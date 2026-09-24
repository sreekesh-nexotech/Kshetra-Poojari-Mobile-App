import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../pooja/application/models/pooja_task.dart';
import '../../../pooja/application/providers/pooja_data_providers.dart';
import '../../domain/entities/upcoming_pooja_count.dart';
import '../models/home_view_models.dart';
import 'attendance_controller.dart';
import 'dashboard_repository_provider.dart';
import 'temple_location_controller.dart';

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
        final gt = tasks.where((t) => t.categoryId == g.id).toList();
        final gd = gt.where((t) => t.isDone).length;
        return GodCardVm(
          id: g.id,
          name: g.name,
          imageUrl: g.imageUrl,
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

/// ── Home's own network seam — panchangam + upcoming counts ─────────────────
/// Same shape as the pooja feature's data seam: a seed provider (empty in
/// production, a fixture in tests) plus a controller that fetches once and
/// pushes the result in, so every widget stays a bare synchronous `ref.watch`.

/// Malayalam calendar date for the greeting card. Empty until
/// [DashboardFeedController.ensureLoaded] fills it in.
final malayalamDateSeedProvider = Provider<String>((ref) => '');

class MalayalamDateController extends StateNotifier<String> {
  MalayalamDateController(super.seed);

  void set(String value) => state = value;
}

final malayalamDateControllerProvider =
    StateNotifierProvider<MalayalamDateController, String>(
      (ref) => MalayalamDateController(ref.watch(malayalamDateSeedProvider)),
    );

/// Read this, not the controller — it is what the greeting card watches.
final malayalamDateProvider = Provider<String>(
  (ref) => ref.watch(malayalamDateControllerProvider),
);

/// Upcoming-day counts (design `tomorrow`/`dayAfter`/…). Empty until
/// [DashboardFeedController.ensureLoaded] fills it in.
final upcomingDaysSeedProvider = Provider<List<UpcomingDay>>(
  (ref) => const <UpcomingDay>[],
);

class UpcomingDaysController extends StateNotifier<List<UpcomingDay>> {
  UpcomingDaysController(super.seed);

  void replace(List<UpcomingDay> days) => state = days;
}

final upcomingDaysControllerProvider =
    StateNotifierProvider<UpcomingDaysController, List<UpcomingDay>>(
      (ref) => UpcomingDaysController(ref.watch(upcomingDaysSeedProvider)),
    );

/// Read this, not the controller — it is what [UpcomingDaysRow] watches.
final upcomingDaysProvider = Provider<List<UpcomingDay>>(
  (ref) => ref.watch(upcomingDaysControllerProvider),
);

/// `"Tomorrow"` / `"Day after tomorrow"` get the design's Malayalam labels;
/// day 3+ keeps the server's English weekday name, rendered Latin like the
/// design's own "Sep 12" placeholder did.
UpcomingDay _upcomingVm(UpcomingPoojaCount c) => switch (c.label) {
  'Tomorrow' => UpcomingDay(label: 'നാളെ', count: c.count),
  'Day after tomorrow' => UpcomingDay(label: 'മറ്റന്നാൾ', count: c.count),
  _ => UpcomingDay(label: c.label, count: c.count, latinLabel: true),
};

/// Fetches the greeting card's date and the upcoming-days row. Mirrors
/// [PoojaFeedController]: [ensureLoaded] is a no-op once a fixture (or a
/// prior fetch) has already supplied data; [refresh] (pull-to-refresh)
/// always hits the network.
class DashboardFeedController extends StateNotifier<bool> {
  DashboardFeedController(this._ref) : super(false);

  final Ref _ref;

  bool get _seeded =>
      _ref.read(malayalamDateProvider).isNotEmpty &&
      _ref.read(upcomingDaysProvider).isNotEmpty;

  Future<void> ensureLoaded() async {
    if (state || _seeded) return;
    await refresh();
  }

  /// Pull-to-refresh — unlike [ensureLoaded], always hits the network.
  Future<void> refresh() async {
    if (state) return;
    state = true;
    await Future.wait([
      _loadPanchangam(),
      _loadUpcoming(),
      _ref.read(attendanceControllerProvider.notifier).restoreToday(),
      // Once per session, so the check-in slide can pre-check without a round
      // trip — and so a temple with no site configured greys the slide out
      // before the poojari drags it (poojari-geofence.md §2). Never throws:
      // the controller folds a failed fetch into its own state.
      _ref.read(templeLocationControllerProvider.notifier).ensureLoaded(),
    ]);
    state = false;
  }

  Future<void> _loadPanchangam() async {
    try {
      final panchangam = await _ref
          .read(dashboardRepositoryProvider)
          .panchangam();
      _ref
          .read(malayalamDateControllerProvider.notifier)
          .set(panchangam.formattedMl);
    } catch (_) {
      // No field to show — the greeting card just renders without it,
      // the same "degrade rather than block" rule the pooja mapper follows.
    }
  }

  Future<void> _loadUpcoming() async {
    try {
      final counts = await _ref
          .read(dashboardRepositoryProvider)
          .upcomingPoojaCounts();
      _ref.read(upcomingDaysControllerProvider.notifier).replace([
        for (final c in counts) _upcomingVm(c),
      ]);
    } catch (_) {
      // Degrade to an empty row rather than block the screen.
    }
  }
}

final dashboardFeedControllerProvider =
    StateNotifierProvider<DashboardFeedController, bool>(
      DashboardFeedController.new,
    );
