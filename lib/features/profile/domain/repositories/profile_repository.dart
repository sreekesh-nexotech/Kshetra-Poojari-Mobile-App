import '../entities/assigned_god.dart';
import '../entities/attendance_report.dart';
import '../entities/monthly_stats.dart';

/// What the account/profile screen needs from the outside world, beyond the
/// signed-in user it already gets from the auth session.
abstract interface class ProfileRepository {
  /// The shrines this poojari keeps. Empty means *every* god, not none
  /// (poojari-app.md §3) — the caller decides how to word that.
  Future<List<AssignedGod>> assignedGods();

  /// This poojari's current-month pooja + incentive totals.
  Future<MonthlyStats> monthlyStats();

  /// Attendance bucketed over [period] (`"weekly"` or `"monthly"`). Omitting
  /// [dateFrom]/[dateTo] defaults to the current week/month; passing both
  /// widens the window to that explicit span (poojari-app.md §6).
  Future<AttendanceReport> attendanceReport({
    required String period,
    String? dateFrom,
    String? dateTo,
  });
}
