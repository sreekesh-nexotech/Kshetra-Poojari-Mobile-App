/// One marked day, from a report's `records` (poojari-app.md §6, extended by
/// poojari-geofence.md §4).
class AttendanceRecord {
  const AttendanceRecord({
    required this.date,
    required this.status,
    this.distanceMeters,
    this.locationVerified = false,
  });

  /// `YYYY-MM-DD`.
  final String date;

  /// `present`, `absent`, or `leave`.
  final String status;

  /// How far from the temple the mark was taken, **as measured at the time**
  /// and stored — not recomputed. Null for a leave, a backdated mark, or any
  /// row written before the geofence existed.
  final int? distanceMeters;

  /// True only when the server measured the distance *and* accepted it.
  ///
  /// ⚠️ False is **not** an accusation. It is false for every leave, every
  /// backdated correction, every row older than this feature, and everything
  /// marked while enforcement was switched off. Deliberately not rendered on
  /// the poojari's own sheet — a red flag next to a legitimate leave would be
  /// a lie the UI tells about its own user (poojari-geofence.md §4).
  final bool locationVerified;

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
    date: j['date'] as String? ?? '',
    status: j['status'] as String? ?? '',
    distanceMeters: (j['distance_meters'] as num?)?.round(),
    locationVerified: j['location_verified'] as bool? ?? false,
  );
}

/// `GET /api/poojari/attendance/report/?period=weekly|monthly` — used for
/// both the profile's "ഹാജർ ദിനങ്ങൾ" KPI tile (`summary`) and the week dot
/// strip (`records`). (poojari-app.md §6)
class AttendanceReport {
  const AttendanceReport({
    required this.present,
    required this.days,
    required this.records,
  });

  /// Days marked present in the window.
  final int present;

  /// Every day in the window, marked or not — the KPI tile's denominator.
  final int days;

  /// Only the days actually marked; a day missing here is unmarked.
  final List<AttendanceRecord> records;

  factory AttendanceReport.fromJson(Map<String, dynamic> j) {
    final summary = j['summary'] as Map<String, dynamic>? ?? const {};
    final records = (j['records'] as List?) ?? const [];
    return AttendanceReport(
      present: summary['present'] as int? ?? 0,
      days: summary['days'] as int? ?? 0,
      records: records
          .cast<Map<String, dynamic>>()
          .map(AttendanceRecord.fromJson)
          .toList(),
    );
  }
}
