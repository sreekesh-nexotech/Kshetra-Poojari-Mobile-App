import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/temple_location.dart';
import '../states/temple_location_state.dart';
import 'dashboard_repository_provider.dart';

/// The session's cache of "where do they have to be standing?".
///
/// Fetched once ([ensureLoaded], from the home feed's load) and re-fetched
/// only when the server says the cache is wrong — a `403` carries its current
/// config to [adopt], a `409` means [refresh] (poojari-geofence.md §2).
///
/// Global rather than `autoDispose`: the poojari moves between tabs while the
/// check-in card is on screen, and re-fetching a value that changes about once
/// a year on every tab switch would be silly.
class TempleLocationController extends StateNotifier<TempleLocationState> {
  TempleLocationController(this._ref) : super(const TempleLocationState());

  final Ref _ref;

  /// De-duplicates concurrent callers — the home feed's load and a poojari who
  /// slides the moment the screen appears would otherwise fetch twice.
  Future<TempleLocationState>? _inFlight;

  /// The cached site, fetching it if it has never been fetched or the last
  /// attempt failed. A [TempleLocationStatus.unconfigured] answer is *not*
  /// retried: the server was clear, and hammering it changes nothing.
  Future<TempleLocationState> ensureLoaded() {
    switch (state.status) {
      case TempleLocationStatus.ready:
      case TempleLocationStatus.unconfigured:
        return Future.value(state);
      case TempleLocationStatus.unknown:
      case TempleLocationStatus.unavailable:
        return refresh();
    }
  }

  /// Always hits the network. Called after a `409`, and after a `403` that
  /// arrives without an embedded location to [adopt].
  Future<TempleLocationState> refresh() {
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  Future<TempleLocationState> _fetch() async {
    if (mounted) state = state.copyWith(fetching: true);
    try {
      final site = await _ref
          .read(dashboardRepositoryProvider)
          .attendanceLocation();
      final next = site == null
          ? const TempleLocationState(status: TempleLocationStatus.unconfigured)
          : TempleLocationState(
              status: TempleLocationStatus.ready,
              location: site,
            );
      if (mounted) state = next;
      return next;
    } catch (e) {
      var hasSession = true;
      try {
        hasSession = await _ref.read(apiClientProvider).hasSessionCookie();
      } catch (_) {
        // No client wired (tests) — the default is the safer read.
      }
      // Deliberately *not* `unconfigured`: a failed fetch means we know
      // nothing, and the two must not be confused. The last known good site is
      // kept so a check-in mid-outage can still pre-check against it.
      final next = state.copyWith(
        status: TempleLocationStatus.unavailable,
        failure: Failure.from(e, hasSession: hasSession),
        fetching: false,
      );
      if (mounted) state = next;
      return next;
    }
  }

  /// Replaces the cache with the config embedded in a geofence `403`. The
  /// server just told us what it is measuring against; believe it rather than
  /// spending another request to ask.
  void adopt(TempleLocation site) {
    if (!mounted) return;
    state = TempleLocationState(
      status: TempleLocationStatus.ready,
      location: site,
    );
  }
}

final templeLocationControllerProvider =
    StateNotifierProvider<TempleLocationController, TempleLocationState>(
      TempleLocationController.new,
    );

/// True when the server has no site configured — the check-in slide disables
/// itself on this rather than letting the poojari drag into a `409`.
final templeLocationUnconfiguredProvider = Provider<bool>(
  (ref) => ref.watch(
    templeLocationControllerProvider.select((s) => s.isUnconfigured),
  ),
);
