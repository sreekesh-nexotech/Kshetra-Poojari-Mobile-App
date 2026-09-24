import '../../../../core/error/failure.dart';
import '../../domain/entities/temple_location.dart';

/// How much the app currently knows about the temple's attendance site.
enum TempleLocationStatus {
  /// Not fetched yet this session.
  unknown,

  /// A site is configured and cached — [TempleLocationState.location] is set.
  ready,

  /// The server answered `{"location": null}`. Marking is impossible until the
  /// office configures one; this is **not** "no geofence, mark freely".
  unconfigured,

  /// The fetch itself failed (offline, server error). Distinct from
  /// [unconfigured]: nothing is known, so nothing can be concluded.
  unavailable,
}

/// The session's cached answer to "where do they have to be standing?"
/// (poojari-geofence.md §2).
class TempleLocationState {
  const TempleLocationState({
    this.status = TempleLocationStatus.unknown,
    this.location,
    this.failure,
    this.fetching = false,
  });

  final TempleLocationStatus status;

  /// Non-null exactly when [status] is [TempleLocationStatus.ready].
  final TempleLocation? location;

  /// Why the last fetch failed; set only for [TempleLocationStatus.unavailable].
  final Failure? failure;

  final bool fetching;

  /// The mark button is dead in the water without a configured site.
  bool get isUnconfigured => status == TempleLocationStatus.unconfigured;

  /// [clearLocation] exists because a `null` argument cannot mean "clear" in
  /// the `??` idiom — and going `ready` → `unconfigured` while quietly keeping
  /// the old coordinates would leave the pre-check measuring against a site
  /// the server has just said does not exist.
  TempleLocationState copyWith({
    TempleLocationStatus? status,
    TempleLocation? location,
    Failure? failure,
    bool? fetching,
    bool clearLocation = false,
  }) => TempleLocationState(
    status: status ?? this.status,
    location: clearLocation ? null : (location ?? this.location),
    failure: failure ?? this.failure,
    fetching: fetching ?? this.fetching,
  );
}
