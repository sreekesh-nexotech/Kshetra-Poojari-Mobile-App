import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../pooja/application/models/pooja_task.dart';
import '../../../pooja/application/providers/pooja_data_providers.dart';
import '../mock/home_mock_data.dart';
import '../models/home_view_models.dart';
import 'attendance_controller.dart';

/// Overall progress on the home combined card (design `tPct` / `tFrac` etc.).
final homeProgressProvider = Provider<HomeProgress>((ref) {
  final tasks = ref.watch(poojaTasksControllerProvider);
  final total = tasks.length;
  final done = tasks.where((t) => t.isDone).length;
  final cancelled = tasks.where((t) => t.isCancelled).length;
  final pct = total == 0 ? 0 : ((done / total) * 100).round();

  final incentive = tasks.where((t) => t.incentive).toList();
  final incentiveDone = incentive.where((t) => t.isDone).length;

  return HomeProgress(
    percentInt: pct,
    fracLabel: '$done/$total',
    pendingLabel: '${total - done - cancelled}',
    incentiveFracLabel: '$incentiveDone/${incentive.length}',
  );
});

/// Per-deity progress cards (design `godCards`).
final godCardsProvider = Provider<List<GodCardVm>>((ref) {
  final tasks = ref.watch(poojaTasksControllerProvider);
  final gods = ref.watch(godsProvider);
  return [
    for (final g in gods)
      () {
        final gt = tasks.where((t) => t.godId == g.id).toList();
        final gd = gt.where((t) => t.isDone).length;
        return GodCardVm(
          id: g.id,
          name: g.name,
          imageAsset: g.imageAsset,
          fracLabel: '$gd/${gt.length}',
          progress: gt.isEmpty ? 0 : gd / gt.length,
        );
      }(),
  ];
});

/// The home tally table — "to-do" before check-out, "today's summary" after
/// (design tally + summary flip).
final homeTallyProvider = Provider<HomeTally>((ref) {
  final tasks = ref.watch(poojaTasksControllerProvider);
  final dayOver = ref.watch(isCheckedOutProvider);
  final target = dayOver ? TaskStatus.done : TaskStatus.pending;

  final order = <String>[];
  final rowByName = <String, TallyRowVm>{};
  final countByName = <String, int>{};
  for (final t in tasks) {
    if (t.status != target) continue;
    if (!countByName.containsKey(t.poojaName)) {
      order.add(t.poojaName);
      countByName[t.poojaName] = 0;
    }
    countByName[t.poojaName] = countByName[t.poojaName]! + 1;
    final prev = rowByName[t.poojaName];
    rowByName[t.poojaName] = TallyRowVm(
      name: t.poojaName,
      count: '', // filled below
      reassigned: (prev?.reassigned ?? false) || t.reassigned,
      incentive: (prev?.incentive ?? false) || t.incentive,
    );
  }

  final rows = [
    for (final n in order)
      TallyRowVm(
        name: n,
        count: AppTime.pad2(countByName[n]!),
        reassigned: rowByName[n]!.reassigned,
        incentive: rowByName[n]!.incentive,
      ),
  ];
  final total = countByName.values.fold<int>(0, (a, b) => a + b);
  final pendingLeft = tasks.where((t) => t.isPending).length;

  return HomeTally(
    title: dayOver ? 'ഇന്നത്തെ സമ്മറി' : 'ഇന്ന് ചെയ്യാനുള്ളവ',
    rows: rows,
    totalLabel: dayOver ? 'ആകെ ചെയ്തത്' : 'ആകെ ബാക്കി',
    total: AppTime.pad2(total),
    noteOn: dayOver && pendingLeft > 0,
    note: AppTime.pad2(pendingLeft),
  );
});

/// Static upcoming-day counts.
final upcomingDaysProvider =
    Provider<List<UpcomingDay>>((ref) => HomeMockData.upcoming);
