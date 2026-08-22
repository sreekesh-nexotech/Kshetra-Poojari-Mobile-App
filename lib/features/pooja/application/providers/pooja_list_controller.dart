import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/booking.dart' show PoojaStatus;
import '../../domain/repositories/pooja_repository.dart';
import '../mappers/pooja_vm_mapper.dart';
import '../models/god.dart';
import '../models/pooja_task.dart';
import '../models/pooja_view_models.dart';
import '../states/pooja_list_state.dart';
import 'pooja_data_providers.dart';
import 'pooja_repository_provider.dart';

/// Does task [t] belong under filter tab [i]? Mirrors the design's `stOkAt`.
bool taskMatchesTab(PoojaTaskVm t, int i) {
  switch (i) {
    case 0:
      return t.isPending; // പെൻഡിംഗ്
    case 1:
      return t.reassigned; // റീ-അസൈൻഡ്
    case 2:
      return t.special; // സ്പെഷ്യൽ
    case 3:
      return !t.special; // നോർമൽ
    case 4:
      return t.isDone; // പൂർത്തിയായി
    default:
      return true; // എല്ലാം
  }
}

/// Sort key so rows read pending → done → cancelled (design `ord`).
int _statusOrder(TaskStatus s) => switch (s) {
  TaskStatus.pending => 0,
  TaskStatus.done => 1,
  TaskStatus.cancelled => 2,
};

/// Pooja-screen UI state controller. Holds [Ref] so [applyBulk] can drive the
/// shared task list; contains no navigation/toast/dialog logic (that stays in
/// the widgets).
class PoojaListController extends StateNotifier<PoojaListState> {
  PoojaListController(this._ref) : super(const PoojaListState());

  final Ref _ref;

  void selectGod(int categoryId) => state = state.copyWith(
    selectedCategoryId: categoryId,
    activeTab: 0,
    selectedIds: const <int>{},
    pickerOpen: false,
  );

  void selectTab(int index) =>
      state = state.copyWith(activeTab: index, selectedIds: const <int>{});

  void togglePicker() => state = state.copyWith(pickerOpen: !state.pickerOpen);

  void closePicker() => state = state.copyWith(pickerOpen: false);

  void toggleTask(int id) {
    final next = Set<int>.from(state.selectedIds);
    if (!next.add(id)) next.remove(id);
    state = state.copyWith(selectedIds: next);
  }

  /// Select-all / clear-all for a group's pending tasks.
  void toggleGroup(List<int> pendingIds) {
    if (pendingIds.isEmpty) return;
    final next = Set<int>.from(state.selectedIds);
    final allSelected = pendingIds.every(next.contains);
    if (allSelected) {
      next.removeAll(pendingIds);
    } else {
      next.addAll(pendingIds);
    }
    state = state.copyWith(selectedIds: next);
  }

  void clearSelection() => state = state.copyWith(selectedIds: const <int>{});

  void openBulk(BulkMode mode) => state = state.copyWith(bulkMode: mode);

  void closeBulk() => state = state.copyWith(bulkMode: BulkMode.none);

  /// The bookings currently selected, grouped by the order that owns them.
  ///
  /// A PATCH addresses one order at a time, and a group card's select-all can
  /// legitimately span several orders — so the grouping is computed here, at
  /// send time, and never assumed from the card.
  Map<int, List<int>> _groupByOrder(Set<int> selected) {
    final out = <int, List<int>>{};
    for (final t in _ref.read(poojaTasksControllerProvider)) {
      if (selected.contains(t.id) && t.canMark) {
        (out[t.orderId] ??= <int>[]).add(t.id);
      }
    }
    return out;
  }

  /// Total refund a cancellation would trigger, for the confirm sheet.
  double get selectedTotal {
    final selected = state.selectedIds;
    var sum = 0.0;
    for (final t in _ref.read(poojaTasksControllerProvider)) {
      if (selected.contains(t.id) && t.canMark) sum += t.price;
    }
    return sum;
  }

  /// Commit the open bulk action.
  ///
  /// Completing is **optimistic** — the poojari is standing in a shrine on
  /// patchy 4G, so the rows flip at once and reconcile when the server
  /// answers. Cancelling is not: it moves money, so the caller blocks on it.
  Future<BulkOutcome> applyBulk() async {
    final mode = state.bulkMode;
    final byOrder = _groupByOrder(state.selectedIds);
    state = state.copyWith(selectedIds: const <int>{}, bulkMode: BulkMode.none);

    if (byOrder.isEmpty) {
      return const BulkOutcome(toast: 'മാറ്റാൻ പൂജകളില്ല');
    }

    return mode == BulkMode.cancel ? _cancel(byOrder) : _complete(byOrder);
  }

  Future<BulkOutcome> _complete(Map<int, List<int>> byOrder) async {
    final tasks = _ref.read(poojaTasksControllerProvider.notifier);
    final snapshot = _ref.read(poojaTasksControllerProvider);
    final label = poojaNowLabel();
    final all = byOrder.values.expand((e) => e).toList();

    tasks.bulkComplete(all, label);

    var done = 0;
    var needsRefresh = false;
    String? error;

    for (final entry in byOrder.entries) {
      try {
        final r = await _repo.markBookings(
          orderId: entry.key,
          bookingIds: entry.value,
          status: PoojaStatus.completed,
        );
        tasks.applyStatuses({
          for (final e in r.lineStatuses.entries)
            e.key: taskStatusFrom(e.value),
        }, doneAt: label);
        done += entry.value.length;
      } catch (e) {
        // Roll back only this order. With a multi-order selection another
        // order may already have been accepted, and undoing that would
        // contradict the server.
        tasks.restoreIds(snapshot, entry.value);
        final failure = await _failure(e);
        needsRefresh = needsRefresh || failure.needsRefresh;
        error ??= failure.message;
      }
    }

    if (done == 0) {
      return BulkOutcome(
        toast: error ?? 'മാറ്റാനായില്ല',
        needsRefresh: needsRefresh,
      );
    }
    return BulkOutcome(
      toast: error == null
          ? '$done പൂജകൾ പൂർത്തിയായി ✓'
          : '$done പൂർത്തിയായി · $error',
      needsRefresh: needsRefresh,
    );
  }

  Future<BulkOutcome> _cancel(Map<int, List<int>> byOrder) async {
    final tasks = _ref.read(poojaTasksControllerProvider.notifier);

    var cancelled = 0;
    var needsRefresh = false;
    var refundTotal = 0.0;
    String? refundId;
    String? blockingRefundId;
    String? error;

    for (final entry in byOrder.entries) {
      try {
        final r = await _repo.markBookings(
          orderId: entry.key,
          bookingIds: entry.value,
          status: PoojaStatus.cancelled,
        );
        tasks.applyStatuses({
          for (final e in r.lineStatuses.entries)
            e.key: taskStatusFrom(e.value),
        });
        cancelled += entry.value.length;
        if (r.refundStarted) {
          refundId = r.refundId;
          refundTotal += r.refundAmount ?? 0;
        }
      } catch (e) {
        final failure = await _failure(e);
        needsRefresh = needsRefresh || failure.needsRefresh;
        // Money left Razorpay but the record did not. This must reach a human,
        // and must never be retried.
        if (failure.action == FailureAction.callTheOffice) {
          blockingRefundId = failure.refundId;
        }
        error ??= failure.message;
      }
    }

    if (blockingRefundId != null) {
      return BulkOutcome(
        toast: error ?? '',
        needsRefresh: needsRefresh,
        unreconciledRefundId: blockingRefundId,
      );
    }
    if (cancelled == 0) {
      return BulkOutcome(
        toast: error ?? 'കാൻസൽ ചെയ്യാനായില്ല',
        needsRefresh: needsRefresh,
      );
    }

    final refunded = refundId != null;
    return BulkOutcome(
      toast: refunded
          ? '$cancelled കാൻസൽ ചെയ്തു · ₹${refundTotal.toStringAsFixed(0)} റീഫണ്ട് ആരംഭിച്ചു'
          : '$cancelled കാൻസൽ ചെയ്തു',
      needsRefresh: needsRefresh,
      refundId: refundId,
    );
  }

  /// Undo a completed booking back to pending. Optimistic, like completing.
  Future<BulkOutcome> undo(int id) async {
    final tasks = _ref.read(poojaTasksControllerProvider.notifier);
    final snapshot = _ref.read(poojaTasksControllerProvider);

    final task = snapshot.where((t) => t.id == id).firstOrNull;
    if (task == null) return const BulkOutcome(toast: '');

    tasks.undo(id);
    try {
      final r = await _repo.markBookings(
        orderId: task.orderId,
        bookingIds: [id],
        status: PoojaStatus.pending,
      );
      tasks.applyStatuses({
        for (final e in r.lineStatuses.entries) e.key: taskStatusFrom(e.value),
      });
      return const BulkOutcome(toast: 'പെൻഡിംഗിലേക്ക് മാറ്റി');
    } catch (e) {
      tasks.restoreIds(snapshot, [id]);
      final failure = await _failure(e);
      return BulkOutcome(
        toast: failure.message,
        needsRefresh: failure.needsRefresh,
      );
    }
  }

  /// Reload the shrine currently on screen — the recovery path after a
  /// stale-list error.
  Future<void> refreshCurrent() => _ref
      .read(poojaFeedControllerProvider.notifier)
      .refresh(_ref.read(effectiveCategoryIdProvider));

  PoojaRepository get _repo => _ref.read(poojaRepositoryProvider);

  /// A 403 means "signed out" or "not permitted" depending on whether a
  /// session cookie is still held.
  Future<Failure> _failure(Object e) async {
    var hasSession = true;
    try {
      hasSession = await _ref.read(apiClientProvider).hasSessionCookie();
    } catch (_) {
      // No client wired (tests).
    }
    return Failure.from(e, hasSession: hasSession);
  }
}

/// What a bulk action produced, for the widget to surface.
class BulkOutcome {
  const BulkOutcome({
    required this.toast,
    this.needsRefresh = false,
    this.refundId,
    this.unreconciledRefundId,
  });

  final String toast;

  /// The list disagreed with the server — reload it.
  final bool needsRefresh;

  /// A refund is in flight at Razorpay. Worth saying out loud.
  final String? refundId;

  /// Money moved but the record did not. Show this id, block the retry, and
  /// send the poojari to the temple office.
  final String? unreconciledRefundId;

  bool get needsManualReconciliation => unreconciledRefundId != null;
}

final poojaListControllerProvider =
    StateNotifierProvider<PoojaListController, PoojaListState>(
      PoojaListController.new,
    );

/// The god the list is actually showing.
///
/// `selectedCategoryId` is null until the catalogue loads, so this falls back
/// to the first shrine — the list endpoint has no "all gods" view and cannot
/// be called without one. Null here means "nothing to show yet".
final effectiveCategoryIdProvider = Provider<int?>((ref) {
  final selected = ref.watch(
    poojaListControllerProvider.select((s) => s.selectedCategoryId),
  );
  if (selected != null) return selected;

  final gods = ref.watch(godsProvider);
  return gods.isEmpty ? null : gods.first.id;
});

/// Currently-selected deity, or [GodVm.placeholder] while the catalogue loads.
final selectedGodProvider = Provider<GodVm>((ref) {
  final id = ref.watch(effectiveCategoryIdProvider);
  final gods = ref.watch(godsProvider);
  if (gods.isEmpty) return GodVm.placeholder;
  return gods.firstWhere((g) => g.id == id, orElse: () => gods.first);
});

/// Grouped, filtered, selection-aware rows for the current deity + tab.
final poojaGroupsProvider = Provider<List<PoojaGroupVm>>((ref) {
  final tasks = ref.watch(poojaTasksControllerProvider);
  final s = ref.watch(poojaListControllerProvider);

  final categoryId = ref.watch(effectiveCategoryIdProvider);
  final inGod = tasks.where((t) => t.categoryId == categoryId).toList();
  final vis = inGod.where((t) => taskMatchesTab(t, s.activeTab)).toList();

  // One card per ORDER, one checkable row per booking. An order is a single
  // checkout and is what a PATCH addresses; two orders that happen to share a
  // pooja name are still two separate pieces of work.
  //
  // First-appearance order is preserved, which keeps the server's sort
  // (pending → completed → cancelled, oldest-first) — that is the work queue.
  final order = <int>[];
  final byOrder = <int, List<PoojaTaskVm>>{};
  for (final t in vis) {
    final list = byOrder.putIfAbsent(t.orderId, () {
      order.add(t.orderId);
      return <PoojaTaskVm>[];
    });
    list.add(t);
  }

  return [
    for (final orderId in order) _buildGroup(byOrder[orderId]!, s.selectedIds),
  ];
});

PoojaGroupVm _buildGroup(List<PoojaTaskVm> items, Set<int> sel) {
  final name = items.first.poojaName;
  final pendingIds = [
    for (final t in items)
      // canMark is false once the server has settled the booking (refunded or
      // cancelled) — those rows must not be selectable.
      if (t.isPending && t.canMark) t.id,
  ];
  final selN = pendingIds.where(sel.contains).length;
  final GroupCheck check;
  if (pendingIds.isNotEmpty && selN == pendingIds.length) {
    check = GroupCheck.all;
  } else if (selN > 0) {
    check = GroupCheck.partial;
  } else {
    check = GroupCheck.none;
  }

  // Stable partition: pending → done → cancelled, original order within each.
  final sorted = [...items]
    ..sort((a, b) => _statusOrder(a.status).compareTo(_statusOrder(b.status)));

  return PoojaGroupVm(
    name: name,
    countLabel: AppTime.pad2(items.length),
    special: items.any((t) => t.special),
    incentive: items.any((t) => t.incentive),
    hasPending: pendingIds.isNotEmpty,
    check: check,
    pendingIds: pendingIds,
    rows: [
      for (final t in sorted)
        PoojaRowVm(
          id: t.id,
          person: t.person,
          nakshatra: t.nakshatra,
          remark: t.remark,
          status: t.status,
          reassignedPill: t.reassigned && t.isPending,
          selected: sel.contains(t.id),
          timeLabel: t.doneAt,
        ),
    ],
  );
}

/// Zero-padded task count for each filter tab (current deity).
final poojaTabCountsProvider = Provider<List<String>>((ref) {
  final tasks = ref.watch(poojaTasksControllerProvider);
  final categoryId = ref.watch(effectiveCategoryIdProvider);
  final inGod = tasks.where((t) => t.categoryId == categoryId).toList();
  return [
    for (var i = 0; i < kPoojaCategories.length; i++)
      AppTime.pad2(inGod.where((t) => taskMatchesTab(t, i)).length),
  ];
});

final poojaListEmptyProvider = Provider<bool>(
  (ref) => ref.watch(poojaGroupsProvider).isEmpty,
);

/// A summary row (pooja name × count) for the bulk confirm modal.
typedef SummaryRow = ({String name, String count});

final poojaSummaryRowsProvider = Provider<List<SummaryRow>>((ref) {
  final tasks = ref.watch(poojaTasksControllerProvider);
  final sel = ref.watch(
    poojaListControllerProvider.select((s) => s.selectedIds),
  );
  final order = <String>[];
  final counts = <String, int>{};
  for (final t in tasks) {
    if (!sel.contains(t.id)) continue;
    if (!counts.containsKey(t.poojaName)) order.add(t.poojaName);
    counts[t.poojaName] = (counts[t.poojaName] ?? 0) + 1;
  }
  return [for (final n in order) (name: n, count: AppTime.pad2(counts[n]!))];
});

/// Total selected (design `sumTotal`).
final poojaSummaryTotalProvider = Provider<String>((ref) {
  final n = ref.watch(
    poojaListControllerProvider.select((s) => s.selectedCount),
  );
  return AppTime.pad2(n);
});
