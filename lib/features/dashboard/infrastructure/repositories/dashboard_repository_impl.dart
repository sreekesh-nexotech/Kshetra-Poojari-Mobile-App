import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/panchangam.dart';
import '../../domain/entities/temple_location.dart';
import '../../domain/entities/upcoming_pooja_count.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../data_sources/remote/dashboard_api.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._api);

  final DashboardApi _api;

  @override
  Future<Panchangam> panchangam() async =>
      Panchangam.fromJson(await _api.panchangam());

  @override
  Future<List<UpcomingPoojaCount>> upcomingPoojaCounts({
    int days = 3,
    int? categoryId,
  }) async {
    final body = await _api.upcomingPoojaCounts(
      days: days,
      categoryId: categoryId,
    );
    final rows = (body['days'] as List?) ?? const [];
    return rows
        .cast<Map<String, dynamic>>()
        .map(UpcomingPoojaCount.fromJson)
        .toList();
  }

  @override
  Future<TempleLocation?> attendanceLocation() async {
    final body = await _api.attendanceLocation();
    final location = body['location'] as Map<String, dynamic>?;
    // An explicit `null` is the server saying "no site configured", not a
    // parse miss — it travels up as null and the card disables itself.
    return location == null ? null : TempleLocation.fromJson(location);
  }

  @override
  Future<void> markAttendance({
    required String latitude,
    required String longitude,
  }) => _api.markAttendance(latitude: latitude, longitude: longitude);

  @override
  Future<DateTime?> todayCheckIn() async {
    final body = await _api.attendanceWeek();
    final records = (body['records'] as List?) ?? const [];
    // The server dates rows by the temple's day, so "today" has to be the
    // temple's too — not the device's.
    final today = AppTime.istToday();
    for (final r in records.cast<Map<String, dynamic>>()) {
      if (r['date'] == today && r['status'] == 'present') {
        return DateTime.tryParse(r['marked_at'] as String? ?? '');
      }
    }
    return null;
  }
}
