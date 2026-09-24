import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/device/location_service.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/temple_location.dart';
import '../states/attendance_state.dart';
import '../states/check_in_result.dart';
import '../states/temple_location_state.dart';
import 'dashboard_repository_provider.dart';
import 'temple_location_controller.dart';

/// Owns today's attendance, including the geofence the mark has to clear.
///
/// Global (not autoDispose): attendance must persist while the poojari moves
/// between the home, pooja and account tabs.
class AttendanceController extends StateNotifier<AttendanceState> {
  AttendanceController(this._ref) : super(const AttendanceState());

  final Ref _ref;

  /// Marks today present, geofenced (poojari-geofence.md §5).
  ///
  /// The order is: cached site → device fix → our own distance check → `POST`.
  /// The local check is the honest half — it lets the card say "you are 850 m
  /// away" instead of firing a request only to relay a refusal — but the
  /// server measures again and **its** answer decides, so a `403` is handled
  /// even when our own check passed. The two disagree more often than it
  /// sounds: a cached radius the office narrowed an hour ago, or a fix that
  /// drifted between the check and the send.
  ///
  /// Waits on the `POST` before the card flips — a check-in that only lives on
  /// this device is not a check-in, and showing one the temple never recorded
  /// is worse than a beat of latency. On any block the state is left untouched
  /// and the caller gets back something specific to say.
  ///
  /// [AttendanceState.checkingIn] is raised for the duration so the slider
  /// can show the wait — the GPS fix alone can take up to 15 s. A slide that
  /// lands while one is already in flight is dropped rather than queued: two
  /// fixes and two `POST`s for one gesture is never what the poojari meant.
  Future<CheckInResult> checkIn(String time) async {
    if (state.checkingIn) return const CheckInResult.busy();
    state = state.copyWith(checkingIn: true);
    try {
      return await _checkIn(time);
    } finally {
      state = state.copyWith(checkingIn: false);
    }
  }

  Future<CheckInResult> _checkIn(String time) async {
    // 1. Where do they have to be standing? Without this there is nothing to
    //    measure against, and per §2 a missing site means "cannot mark", not
    //    "mark freely".
    final site = await _ref
        .read(templeLocationControllerProvider.notifier)
        .ensureLoaded();

    switch (site.status) {
      case TempleLocationStatus.unconfigured:
        return const CheckInResult.noTempleLocation();
      case TempleLocationStatus.unavailable:
        return CheckInResult.failed(
          site.failure ?? Failure.from(StateError('no temple location')),
        );
      case TempleLocationStatus.unknown:
      case TempleLocationStatus.ready:
        break;
    }
    final temple = site.location;
    if (temple == null) return const CheckInResult.noTempleLocation();

    // 2. Can this phone answer where it is?
    final location = _ref.read(locationServiceProvider);
    final denial = await location.ensureAvailable();
    final denialResult = _denialResult(denial);
    if (denialResult != null) return denialResult;

    final fix = await location.currentFix();
    if (fix == null) return const CheckInResult.fixUnavailable();

    // 3. Our own check. `.round()` matches how the server reports distance, so
    //    the two never differ by a rendered metre.
    final metres = location
        .metresBetween(
          fromLat: fix.latitude,
          fromLng: fix.longitude,
          toLat: temple.latitude,
          toLng: temple.longitude,
        )
        .round();
    if (metres > temple.radiusMeters) {
      return CheckInResult.outsidePremises(
        distanceMeters: metres,
        radiusMeters: temple.radiusMeters,
      );
    }

    // 4. The mark. No `distance_meters` goes with it — the server ignores a
    //    client-supplied one and computes its own.
    try {
      await _ref
          .read(dashboardRepositoryProvider)
          .markAttendance(
            latitude: fix.latitudeParam,
            longitude: fix.longitudeParam,
          );
      state = state.copyWith(checkInAt: time, clearExpandedOverride: true);
      return const CheckInResult.marked();
    } on ApiException catch (e) {
      return _markFailure(e);
    } catch (e) {
      return CheckInResult.failed(await _failure(e));
    }
  }

  /// The server disagreed with our pre-check, or refused for its own reasons.
  /// No attendance row was written in any of these branches.
  Future<CheckInResult> _markFailure(ApiException e) async {
    final temple = _ref.read(templeLocationControllerProvider.notifier);

    if (e.isOutsidePremises) {
      // The `403` embeds the config the server measured against. Adopting it
      // is cheaper and more current than another round trip; only fall back to
      // a refetch if it somehow came without one.
      final current = e.location;
      if (current != null) {
        temple.adopt(TempleLocation.fromJson(current));
      } else {
        unawaited(temple.refresh());
      }
      return CheckInResult.outsidePremises(
        distanceMeters: e.distanceMeters!,
        radiusMeters: e.radiusMeters!,
      );
    }

    if (e.isNoTempleLocation) {
      // Our cache said there was a site and the server says there is not —
      // it changed under us, so throw the cache away.
      unawaited(temple.refresh());
      return const CheckInResult.noTempleLocation();
    }

    // A `400` about the coordinates means the fix we sent was not usable.
    // Everything else in that bucket (a future date, a backdated mark) this
    // app cannot produce, so it falls through to the generic message.
    if (e.statusCode == 400 && _isCoordinateComplaint(e.details)) {
      return const CheckInResult.fixUnavailable();
    }

    return CheckInResult.failed(await _failure(e));
  }

  static bool _isCoordinateComplaint(Map<String, dynamic>? details) =>
      details != null &&
      (details.containsKey('latitude') || details.containsKey('longitude'));

  static CheckInResult? _denialResult(LocationDenial denial) =>
      switch (denial) {
        LocationDenial.none => null,
        LocationDenial.serviceDisabled => const CheckInResult.locationOff(),
        LocationDenial.denied => const CheckInResult.permissionDenied(),
        LocationDenial.deniedForever => const CheckInResult.permissionBlocked(),
        LocationDenial.unavailable => const CheckInResult.fixUnavailable(),
      };

  Future<Failure> _failure(Object error) async {
    var hasSession = true;
    try {
      hasSession = await _ref.read(apiClientProvider).hasSessionCookie();
    } catch (_) {
      // No client wired (tests).
    }
    return Failure.from(error, hasSession: hasSession);
  }

  /// Sends the poojari to the settings screen that can undo [result]'s block.
  /// A no-op for blocks settings cannot fix.
  Future<void> openSettingsFor(CheckInResult result) {
    final denial = switch (result.block) {
      CheckInBlock.locationOff => LocationDenial.serviceDisabled,
      CheckInBlock.permissionBlocked => LocationDenial.deniedForever,
      _ => LocationDenial.none,
    };
    return _ref.read(locationServiceProvider).openSettingsFor(denial);
  }

  /// Local-only. The backend has no check-out concept: attendance is one
  /// present/absent/leave mark per calendar day, not a punch pair
  /// (poojari-app.md §5) — so there is nothing to send here.
  void checkOut(String time) =>
      state = state.copyWith(checkOutAt: time, clearExpandedOverride: true);

  /// Called once on app start (see `DashboardFeedController.ensureLoaded`)
  /// to pick up a check-in already on the books — from an earlier run of the
  /// app, a killed process, or another device — so a restart doesn't show
  /// "not marked" for a day that actually is. A no-op once anything local
  /// this session already knows about a check-in, so it can never clobber a
  /// check-out that happened after the server was last asked.
  Future<void> restoreToday() async {
    if (state.started) return;
    try {
      final markedAt = await _ref
          .read(dashboardRepositoryProvider)
          .todayCheckIn();
      if (markedAt != null && !state.started) {
        state = state.copyWith(checkInAt: AppTime.istClockLabel(markedAt));
      }
    } catch (_) {
      // Degrade — the card just stays "not marked" until checked in by hand.
    }
  }

  void toggleExpanded() =>
      state = state.copyWith(expandedOverride: !state.expanded);
}

final attendanceControllerProvider =
    StateNotifierProvider<AttendanceController, AttendanceState>(
      AttendanceController.new,
    );

/// True once the poojari has checked in — gates the pooja tab.
final isCheckedInProvider = Provider<bool>(
  (ref) => ref.watch(attendanceControllerProvider.select((s) => s.started)),
);

/// True once checked out — flips the home tally to "today's summary".
final isCheckedOutProvider = Provider<bool>(
  (ref) => ref.watch(
    attendanceControllerProvider.select((s) => s.checkOutAt != null),
  ),
);
