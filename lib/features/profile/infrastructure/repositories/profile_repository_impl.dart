import '../../domain/entities/assigned_god.dart';
import '../../domain/entities/attendance_report.dart';
import '../../domain/entities/monthly_stats.dart';
import '../../domain/repositories/profile_repository.dart';
import '../data_sources/remote/profile_api.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._api);

  final ProfileApi _api;

  @override
  Future<List<AssignedGod>> assignedGods() async {
    final body = await _api.gods();
    final rows = (body['gods'] as List?) ?? const [];
    return rows.cast<Map<String, dynamic>>().map(AssignedGod.fromJson).toList();
  }

  @override
  Future<MonthlyStats> monthlyStats() async =>
      MonthlyStats.fromJson(await _api.monthlyStats());

  @override
  Future<AttendanceReport> attendanceReport({
    required String period,
    String? dateFrom,
    String? dateTo,
  }) async => AttendanceReport.fromJson(
    await _api.attendanceReport(
      period: period,
      dateFrom: dateFrom,
      dateTo: dateTo,
    ),
  );
}
