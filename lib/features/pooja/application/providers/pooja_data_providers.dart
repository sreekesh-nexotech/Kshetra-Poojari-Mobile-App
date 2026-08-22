import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/repositories/pooja_repository.dart';
import '../mappers/pooja_vm_mapper.dart';
import '../models/god.dart';
import '../models/pooja_task.dart';
import '../states/pooja_feed_state.dart';
import 'pooja_list_controller.dart';
import 'pooja_repository_provider.dart';

/// ── The data seam ───────────────────────────────────────────────────────────
/// [godsProvider] and [poojaTasksControllerProvider] are what the whole
/// feature reads. Both are plain synchronous providers; [PoojaFeedController]
/// does the awaiting and pushes results into them, so no derived provider and
/// no widget has to deal with an `AsyncValue`.

/// The shrine list. Filled by [PoojaFeedController.loadGods]; overridden with
/// a fixture in tests.
final godsSeedProvider = Provider<List<GodVm>>((ref) => const <GodVm>[]);

class GodsController extends StateNotifier<List<GodVm>> {
  GodsController(super.seed);

  void replace(List<GodVm> gods) => state = gods;
}

final godsControllerProvider =
    StateNotifierProvider<GodsController, List<GodVm>>(
      (ref) => GodsController(ref.watch(godsSeedProvider)),
    );

/// Read this, not the controller — it is what every widget watches.
final godsProvider = Provider<List<GodVm>>(
  (ref) => ref.watch(godsControllerProvider),
);

/// Initial task list. Empty in production; a fixture in tests.
final poojaSeedProvider = Provider<List<PoojaTaskVm>>(
  (ref) => const <PoojaTaskVm>[],
);

/// ── Shared task state ───────────────────────────────────────────────────────
/// The master booking list, keyed by server order-line id. Owned by the pooja
/// feature but read by the dashboard (home tally + progress). Global (not
/// autoDispose): the day's work persists across tab switches.
class PoojaTasksController extends StateNotifier<List<PoojaTaskVm>> {
  PoojaTasksController(super.seed);

  /// Swap in a freshly fetched god's bookings, leaving every other god's
  /// alone. The list is a union across whichever shrines have been visited.
  void replaceForCategory(int categoryId, List<PoojaTaskVm> incoming) {
    state = [
      for (final t in state)
        if (t.categoryId != categoryId) t,
      ...incoming,
    ];
  }

  /// Apply the server's per-line verdict from a PATCH response.
  ///
  /// Only the lines the response actually mentions are touched — it carries
  /// every line on the order, and ours are a subset of that.
  void applyStatuses(Map<int, TaskStatus> byLineId, {String? doneAt}) {
    if (byLineId.isEmpty) return;
    state = [
      for (final t in state)
        if (byLineId.containsKey(t.id))
          t.copyWith(
            status: byLineId[t.id],
            doneAt: byLineId[t.id] == TaskStatus.done ? doneAt : null,
            clearDoneAt: byLineId[t.id] != TaskStatus.done,
          )
        else
          t,
    ];
  }

  /// Put just [ids] back the way [snapshot] had them.
  ///
  /// Per-order, not global: with a multi-order selection one PATCH can succeed
  /// while another is refused, and rolling back everything would undo a write
  /// the server accepted.
  void restoreIds(List<PoojaTaskVm> snapshot, Iterable<int> ids) {
    final wanted = ids.toSet();
    final before = {
      for (final t in snapshot)
        if (wanted.contains(t.id)) t.id: t,
    };
    if (before.isEmpty) return;
    state = [for (final t in state) before[t.id] ?? t];
  }

  /// Mark [ids] complete, stamping [time] as the completion label.
  void bulkComplete(Iterable<int> ids, String time) {
    final set = ids.toSet();
    state = [
      for (final t in state)
        if (set.contains(t.id) && t.isPending)
          t.copyWith(status: TaskStatus.done, doneAt: time)
        else
          t,
    ];
  }

  /// Cancel [ids].
  void bulkCancel(Iterable<int> ids) {
    final set = ids.toSet();
    state = [
      for (final t in state)
        if (set.contains(t.id) && t.isPending)
          t.copyWith(status: TaskStatus.cancelled, clearDoneAt: true)
        else
          t,
    ];
  }

  /// Undo a completed task back to pending.
  void undo(int id) {
    state = [
      for (final t in state)
        if (t.id == id)
          t.copyWith(status: TaskStatus.pending, clearDoneAt: true)
        else
          t,
    ];
  }
}

final poojaTasksControllerProvider =
    StateNotifierProvider<PoojaTasksController, List<PoojaTaskVm>>(
      (ref) => PoojaTasksController(ref.watch(poojaSeedProvider)),
    );

/// ── Load orchestration ──────────────────────────────────────────────────────

class PoojaFeedController extends StateNotifier<PoojaFeedState> {
  PoojaFeedController(this._ref) : super(const PoojaFeedState());

  final Ref _ref;

  /// Gods currently being fetched. Entering the tab and the shrine-change
  /// listener can both fire for the same god on the first frame; without this
  /// they would issue two identical requests against a 2000/hour throttle.
  final Set<int> _inFlight = {};

  PoojaRepository get _repo => _ref.read(poojaRepositoryProvider);

  /// Fetch the shrine list and select the first one if nothing is selected.
  Future<void> loadGods() async {
    state = state.copyWith(status: LoadStatus.loading, clearMessage: true);
    try {
      final gods = await _repo.gods();
      _ref.read(godsControllerProvider.notifier).replace([
        for (final g in gods) g.toVm(),
      ]);
      state = state.copyWith(godsLoaded: true, status: LoadStatus.ready);
    } catch (e) {
      state = await _toError(e);
    }
  }

  /// Load one god's bookings. Skips the network when we already hold that
  /// god's list unless [force] is set.
  Future<void> load(int? categoryId, {bool force = false}) async {
    if (categoryId == null) return;
    if (_inFlight.contains(categoryId)) return;

    final held = state.holds(categoryId);
    if (held && !force) {
      state = state.copyWith(status: LoadStatus.ready, clearMessage: true);
      return;
    }

    state = state.copyWith(
      // Refreshing a god we already show must not blank the list underneath.
      status: held ? LoadStatus.refreshing : LoadStatus.loading,
      clearMessage: true,
    );

    _inFlight.add(categoryId);
    try {
      final work = await _repo.todaysWork(categoryId);
      _ref
          .read(poojaTasksControllerProvider.notifier)
          .replaceForCategory(categoryId, work.toTasks());
      state = state.copyWith(
        status: LoadStatus.ready,
        loadedCategories: {...state.loadedCategories, categoryId},
      );
    } catch (e) {
      state = await _toError(e);
    } finally {
      _inFlight.remove(categoryId);
    }
  }

  /// Fetch on first entry to the tab — and no-op when something has already
  /// supplied data (a fixture in tests), so a widget test never reaches for a
  /// network client that was never wired.
  Future<void> ensureLoaded(int? categoryId) async {
    final seeded =
        _ref.read(godsProvider).isNotEmpty &&
        _ref.read(poojaTasksControllerProvider).isNotEmpty;
    if (seeded) return;

    if (!state.godsLoaded) await loadGods();
    if (state.hasError) return;
    await load(_ref.read(effectiveCategoryIdProvider) ?? categoryId);
  }

  /// Pull-to-refresh, and the recovery path after a stale-list error.
  Future<void> refresh(int? categoryId) async {
    if (!state.godsLoaded) await loadGods();
    await load(categoryId, force: true);
  }

  /// A 403 is ambiguous — ask the jar whether a session is still held before
  /// deciding this means "signed out" rather than "not permitted".
  Future<PoojaFeedState> _toError(Object e) async {
    var hasSession = true;
    try {
      hasSession = await _ref.read(apiClientProvider).hasSessionCookie();
    } catch (_) {
      // No client wired (tests); treat as still signed in.
    }
    final failure = Failure.from(e, hasSession: hasSession);
    return state.copyWith(status: LoadStatus.error, message: failure.message);
  }
}

final poojaFeedControllerProvider =
    StateNotifierProvider<PoojaFeedController, PoojaFeedState>(
      PoojaFeedController.new,
    );

/// Convenience: current wall-clock label for completion stamps.
String poojaNowLabel() => AppTime.clockLabel();
