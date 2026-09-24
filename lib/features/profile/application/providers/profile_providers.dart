import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../auth/application/providers/session_controller.dart';
import '../../../dashboard/application/providers/attendance_controller.dart';
import '../../domain/repositories/profile_repository.dart';
import '../mock/profile_mock_data.dart';
import '../models/profile_models.dart';
import 'profile_repository_provider.dart';

/// The signed-in poojari. Name/phone/ID come from the session (`GET
/// /api/poojari/profile/`, fetched by `sessionControllerProvider` on sign-in
/// / cold-start restore). Blank in the rare case [SessionState.user] is null
/// while still authenticated (a `stale`, offline session where the profile
/// call itself couldn't reach the server) — nothing to show, so nothing
/// invented.
final poojariProvider = Provider<PoojariVm>((ref) {
  final user = ref.watch(sessionControllerProvider).user;
  if (user == null) return const PoojariVm(name: '', phone: '');
  return PoojariVm(
    name: user.displayName,
    phone: user.phoneNumber ?? '',
    poojariId: user.employeeId,
  );
});

/// Static design copy — not backend data (see [ProfileMockData]).
final monthLabelProvider = Provider<String>(
  (ref) => ProfileMockData.monthLabel,
);

/// ── Profile's own network seam — assigned gods, month KPIs, week strip ─────
/// Same shape as the dashboard's: a seed provider (empty in production, a
/// fixture in tests) plus a controller that fetches once and pushes the
/// result in, so every widget stays a bare synchronous `ref.watch`.

final assignedGodsLabelSeedProvider = Provider<String>((ref) => '');

class AssignedGodsLabelController extends StateNotifier<String> {
  AssignedGodsLabelController(super.seed);

  void set(String value) => state = value;
}

final assignedGodsLabelControllerProvider =
    StateNotifierProvider<AssignedGodsLabelController, String>(
      (ref) =>
          AssignedGodsLabelController(ref.watch(assignedGodsLabelSeedProvider)),
    );

/// Read this, not the controller — it is what [ProfileCard] watches.
final assignedGodsLabelProvider = Provider<String>(
  (ref) => ref.watch(assignedGodsLabelControllerProvider),
);

final monthKpisSeedProvider = Provider<List<MonthKpi>>(
  (ref) => const <MonthKpi>[],
);

class MonthKpisController extends StateNotifier<List<MonthKpi>> {
  MonthKpisController(super.seed);

  void replace(List<MonthKpi> kpis) => state = kpis;
}

final monthKpisControllerProvider =
    StateNotifierProvider<MonthKpisController, List<MonthKpi>>(
      (ref) => MonthKpisController(ref.watch(monthKpisSeedProvider)),
    );

final monthKpisProvider = Provider<List<MonthKpi>>(
  (ref) => ref.watch(monthKpisControllerProvider),
);

/// The 6 non-today days of the week strip — see [weekStripProvider].
final weekDaysSeedProvider = Provider<List<WeekDay>>(
  (ref) => const <WeekDay>[],
);

class WeekDaysController extends StateNotifier<List<WeekDay>> {
  WeekDaysController(super.seed);

  void replace(List<WeekDay> days) => state = days;
}

final weekDaysControllerProvider =
    StateNotifierProvider<WeekDaysController, List<WeekDay>>(
      (ref) => WeekDaysController(ref.watch(weekDaysSeedProvider)),
    );

/// Week attendance strip: the 6 fetched days before today, plus today itself
/// (live from check-in state, not the attendance report — today's mark must
/// flip the instant the poojari slides in, not wait on a refetch).
final weekStripProvider = Provider<List<WeekDay>>((ref) {
  final past = ref.watch(weekDaysControllerProvider);
  final checkedIn = ref.watch(isCheckedInProvider);
  return [
    ...past,
    WeekDay(
      label: AppTime.weekdayInitial(DateTime.now()),
      mark: checkedIn ? '✓' : '–',
      kind: WeekDayKind.today,
    ),
  ];
});

/// Fetches assigned deities, month KPIs and the week strip. Mirrors
/// `DashboardFeedController`: [ensureLoaded] is a no-op once a fixture (or a
/// prior fetch) has already supplied data; [refresh] (pull-to-refresh)
/// always hits the network.
class ProfileFeedController extends StateNotifier<bool> {
  ProfileFeedController(this._ref) : super(false);

  final Ref _ref;

  ProfileRepository get _repo => _ref.read(profileRepositoryProvider);

  bool get _seeded =>
      _ref.read(assignedGodsLabelProvider).isNotEmpty &&
      _ref.read(monthKpisProvider).isNotEmpty &&
      _ref.read(weekDaysControllerProvider).isNotEmpty;

  Future<void> ensureLoaded() async {
    if (state || _seeded) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (state) return;
    state = true;
    await Future.wait([
      _loadAssignedGods(),
      _loadMonthKpis(),
      _loadWeekStrip(),
    ]);
    state = false;
  }

  Future<void> _loadAssignedGods() async {
    try {
      final gods = await _repo.assignedGods();
      // An empty list means every god, not none (poojari-app.md §3) — not
      // "no shrines assigned".
      final label = gods.isEmpty
          ? 'എല്ലാ ദേവതകളും'
          : gods.map((g) => g.name).join(' · ');
      _ref.read(assignedGodsLabelControllerProvider.notifier).set(label);
    } catch (_) {
      // Degrade rather than block — the card just shows no deity line.
    }
  }

  Future<void> _loadMonthKpis() async {
    try {
      final stats = await _repo.monthlyStats();
      final attendance = await _repo.attendanceReport(period: 'monthly');
      _ref.read(monthKpisControllerProvider.notifier).replace([
        MonthKpi(
          value: '${attendance.present}/${attendance.days}',
          label: 'ഹാജർ ദിനങ്ങൾ',
        ),
        MonthKpi(value: _grouped(stats.totalPoojas), label: 'ആകെ പൂജകൾ'),
        MonthKpi(value: _grouped(stats.specialPoojas), label: 'സ്പെഷ്യൽ പൂജകൾ'),
        MonthKpi(
          value: '₹${_grouped(stats.incentiveEarned.round())}',
          label: 'ഇൻസെന്റീവ് · ഇതുവരെ',
          accent: true,
        ),
      ]);
    } catch (_) {
      // Degrade rather than block — the grid just stays empty.
    }
  }

  Future<void> _loadWeekStrip() async {
    try {
      final today = DateTime.now();
      final report = await _repo.attendanceReport(
        period: 'weekly',
        dateFrom: AppTime.isoDate(today.subtract(const Duration(days: 6))),
        dateTo: AppTime.isoDate(today.subtract(const Duration(days: 1))),
      );
      final byDate = {for (final r in report.records) r.date: r.status};
      _ref.read(weekDaysControllerProvider.notifier).replace([
        for (var i = 6; i >= 1; i--)
          _weekDayFor(today.subtract(Duration(days: i)), byDate),
      ]);
    } catch (_) {
      // Degrade rather than block — the strip just shows today only.
    }
  }
}

WeekDay _weekDayFor(DateTime date, Map<String, String> statusByDate) {
  final (mark, kind) = switch (statusByDate[AppTime.isoDate(date)]) {
    'present' => ('✓', WeekDayKind.present),
    'absent' || 'leave' => ('✕', WeekDayKind.absent),
    _ => ('–', WeekDayKind.notMarked),
  };
  return WeekDay(label: AppTime.weekdayInitial(date), mark: mark, kind: kind);
}

String _grouped(int n) => NumberFormat('#,##0').format(n);

final profileFeedControllerProvider =
    StateNotifierProvider<ProfileFeedController, bool>(
      ProfileFeedController.new,
    );
