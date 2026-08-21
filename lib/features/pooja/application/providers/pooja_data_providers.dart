import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../mock/pooja_mock_data.dart';
import '../models/god.dart';
import '../models/pooja_task.dart';

/// ── Mock seam ───────────────────────────────────────────────────────────────
/// The two providers below are the ONLY swap points for real data. Override
/// them (or replace their bodies with a repository read) once the API exists;
/// every controller/derived provider/UI downstream stays unchanged.

/// Assigned deities. Replace with `PoojaRepository.gods()`.
final godsProvider = Provider<List<GodVm>>((ref) => PoojaMockData.gods);

/// Initial task list seed. Replace with `PoojaRepository.todaysTasks()`.
final poojaSeedProvider = Provider<List<PoojaTaskVm>>(
  (ref) => PoojaMockData.tasks(),
);

/// ── Shared task state ───────────────────────────────────────────────────────
/// The master task list. Owned by the pooja feature but read by the dashboard
/// (home tally + progress). Global (not autoDispose): the day's tasks persist
/// across tab switches.
class PoojaTasksController extends StateNotifier<List<PoojaTaskVm>> {
  PoojaTasksController(super.seed);

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

  /// Cancel/reject [ids] (admin will reassign).
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

/// Convenience: current wall-clock label for completion stamps.
String poojaNowLabel() => AppTime.clockLabel();
