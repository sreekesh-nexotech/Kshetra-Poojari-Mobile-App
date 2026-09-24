import 'dart:async';

import 'package:kshetra_poojari/core/device/location_service.dart';
import 'package:kshetra_poojari/features/dashboard/domain/entities/panchangam.dart';
import 'package:kshetra_poojari/features/dashboard/domain/entities/temple_location.dart';
import 'package:kshetra_poojari/features/dashboard/domain/entities/upcoming_pooja_count.dart';
import 'package:kshetra_poojari/features/dashboard/domain/repositories/dashboard_repository.dart';

/// A scriptable [DashboardRepository]: hand it what each call should return or
/// throw, and inspect what it was asked for.
class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({this.site, this.siteError, this.markError});

  /// What `attendanceLocation()` returns. Null models `{"location": null}`.
  TempleLocation? site;

  /// Thrown by `attendanceLocation()` instead of returning [site].
  Object? siteError;

  /// Thrown by `markAttendance()`. Null means the mark succeeds.
  Object? markError;

  int siteCalls = 0;
  final List<({String latitude, String longitude})> markCalls = [];

  @override
  Future<TempleLocation?> attendanceLocation() async {
    siteCalls++;
    if (siteError != null) throw siteError!;
    return site;
  }

  @override
  Future<void> markAttendance({
    required String latitude,
    required String longitude,
  }) async {
    markCalls.add((latitude: latitude, longitude: longitude));
    if (markError != null) throw markError!;
  }

  @override
  Future<DateTime?> todayCheckIn() async => null;

  @override
  Future<Panchangam> panchangam() async =>
      throw UnimplementedError('not used by the geofence tests');

  @override
  Future<List<UpcomingPoojaCount>> upcomingPoojaCounts({
    int days = 3,
    int? categoryId,
  }) async => const [];
}

/// A [LocationService] that answers from fields instead of the platform.
///
/// [metresBetween] is the real haversine's stand-in: tests set [metres]
/// directly, so a case reads "they were 850 m out" rather than making the
/// reader decode a pair of coordinates.
class FakeLocationService implements LocationService {
  FakeLocationService({
    this.denial = LocationDenial.none,
    this.fix = const DeviceFix(latitude: 10.123456, longitude: 76.654321),
    this.metres = 0,
  });

  LocationDenial denial;
  DeviceFix? fix;
  double metres;

  final List<LocationDenial> settingsOpened = [];

  /// When set, [currentFix] waits on it — stands in for the seconds a real
  /// GPS fix takes, so a test can look at the in-flight state.
  Completer<void>? fixGate;

  @override
  Future<LocationDenial> ensureAvailable() async => denial;

  @override
  Future<DeviceFix?> currentFix() async {
    await fixGate?.future;
    return fix;
  }

  @override
  double metresBetween({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) => metres;

  @override
  Future<void> openSettingsFor(LocationDenial denial) async =>
      settingsOpened.add(denial);
}
