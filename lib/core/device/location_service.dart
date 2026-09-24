import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Why a fix could not be taken. [none] means one was.
///
/// Ordered the way the poojari has to fix them: the OS location switch first
/// (no app permission helps while it is off), then the app's own grant, then
/// the fix itself.
enum LocationDenial {
  none,

  /// The device's location switch is off.
  serviceDisabled,

  /// Denied this time; asking again is allowed.
  denied,

  /// Denied permanently (or blocked by policy) — only the settings screen can
  /// undo it, `requestPermission()` returns immediately from here on.
  deniedForever,

  /// Permission granted and the service on, but no fix arrived — indoors, no
  /// sky view, or the timeout elapsed.
  unavailable,
}

/// A device fix, reduced to what the geofence needs.
class DeviceFix {
  const DeviceFix({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  /// The wire format the attendance API wants: a decimal string with 6 places,
  /// **not** a JSON float (poojari-geofence.md §3).
  String get latitudeParam => latitude.toStringAsFixed(6);
  String get longitudeParam => longitude.toStringAsFixed(6);
}

/// ── DEVICE SEAM ─────────────────────────────────────────────────────────────
/// Everything the app knows about where the phone is. An interface rather than
/// bare `Geolocator` statics so tests can hand in a fake and never touch a
/// platform channel — the same seam the repositories use for Dio.
abstract interface class LocationService {
  /// Location switch on **and** permission granted, requesting it if it has
  /// not been asked for yet. [LocationDenial.none] means [currentFix] may be
  /// called.
  Future<LocationDenial> ensureAvailable();

  /// A single foreground fix. Returns `null` when none arrived in time —
  /// callers map that to [LocationDenial.unavailable].
  Future<DeviceFix?> currentFix();

  /// Great-circle metres between two points. Pure maths, no I/O.
  double metresBetween({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  });

  /// Sends the poojari where they can undo [denial]: the app's permission page
  /// for [LocationDenial.deniedForever], the system location page for
  /// [LocationDenial.serviceDisabled].
  Future<void> openSettingsFor(LocationDenial denial);
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  /// High accuracy, because a 200 m radius is not a lot of room. The time
  /// limit is what turns "no sky view" into an answer instead of a spinner the
  /// poojari watches forever.
  static const LocationSettings _settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 15),
  );

  @override
  Future<LocationDenial> ensureAvailable() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationDenial.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationDenial.none,
      LocationPermission.deniedForever => LocationDenial.deniedForever,
      // `unableToDetermine` is treated as a plain denial: it is recoverable by
      // asking again, which is exactly what `denied` offers.
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => LocationDenial.denied,
    };
  }

  @override
  Future<DeviceFix?> currentFix() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      );
      return DeviceFix(latitude: p.latitude, longitude: p.longitude);
    } catch (_) {
      // TimeoutException, LocationServiceDisabledException, a PlatformException
      // from a flaky provider — all the same to the caller: no fix, no mark.
      return null;
    }
  }

  @override
  double metresBetween({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) => Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);

  @override
  Future<void> openSettingsFor(LocationDenial denial) async {
    switch (denial) {
      case LocationDenial.serviceDisabled:
        await Geolocator.openLocationSettings();
      case LocationDenial.deniedForever:
        await Geolocator.openAppSettings();
      case LocationDenial.none:
      case LocationDenial.denied:
      case LocationDenial.unavailable:
        // Nothing in settings would help — asking again is the fix.
        break;
    }
  }
}

/// Overridden in tests with a fake; production gets the real thing.
final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);
