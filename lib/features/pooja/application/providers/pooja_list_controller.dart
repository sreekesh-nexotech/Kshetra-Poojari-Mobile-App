import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../models/god.dart';
import '../models/pooja_task.dart';
import '../models/pooja_view_models.dart';
import '../states/pooja_list_state.dart';
import 'pooja_data_providers.dart';

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

  void selectGod(String godId) => state = state.copyWith(
    selectedGodId: godId,
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

  /// Commit the open bulk action to the shared task list; returns the toast
  /// message for the widget to display.
  String applyBulk() {
    final ids = state.selectedIds.toList();
    final mode = state.bulkMode;
    final tasks = _ref.read(poojaTasksControllerProvider.notifier);
    final String toast;
    if (mode == BulkMode.cancel) {
      tasks.bulkCancel(ids);
      toast = 'അഡ്മിനെ അറിയിച്ചു · റീ-അസൈൻ ചെയ്യും';
    } else {
      tasks.bulkComplete(ids, poojaNowLabel());
      toast = '${ids.length} പൂജകൾ പൂർത്തിയായി ✓';
    }
    state = state.copyWith(selectedIds: const <int>{}, bulkMode: BulkMode.none);
    return toast;
  }

  /// Undo a completed task and return the toast text.
  String undo(int id) {
    _ref.read(poojaTasksControllerProvider.notifier).undo(id);
    return 'പെൻഡിംഗിലേക്ക് മാറ്റി';
  }
}

final poojaListControllerProvider =
    StateNotifierProvider<PoojaListController, PoojaListState>(
      PoojaListController.new,
    );

/// Currently-selected deity.
final selectedGodProvider = Provider<GodVm>((ref) {
  final id = ref.watch(
    poojaListControllerProvider.select((s) => s.selectedGodId),
  );
  final gods = ref.watch(godsProvider);
  return gods.firstWhere((g) => g.id == id, orElse: () => gods.first);
});

/// Grouped, filtered, selection-aware rows for the current deity + tab.
final poojaGroupsProvider = Provider<List<PoojaGroupVm>>((ref) {
  final tasks = ref.watch(poojaTasksControllerProvider);
  final s = ref.watch(poojaListControllerProvider);

  final inGod = tasks.where((t) => t.godId == s.selectedGodId).toList();
  final vis = inGod.where((t) => taskMatchesTab(t, s.activeTab)).toList();

  // Group by pooja name, preserving first-appearance order.
  final order = <String>[];
  final byName = <String, List<PoojaTaskVm>>{};
  for (final t in vis) {
    final list = byName.putIfAbsent(t.poojaName, () {
      order.add(t.poojaName);
      return <PoojaTaskVm>[];
    });
    list.add(t);
  }

  return [
    for (final name in order) _buildGroup(name, byName[name]!, s.selectedIds),
  ];
});

PoojaGroupVm _buildGroup(String name, List<PoojaTaskVm> items, Set<int> sel) {
  final pendingIds = [
    for (final t in items)
      if (t.isPending) t.id,
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
  final godId = ref.watch(
    poojaListControllerProvider.select((s) => s.selectedGodId),
  );
  final inGod = tasks.where((t) => t.godId == godId).toList();
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
