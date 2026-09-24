/// The site a poojari has to be standing in to mark today present, and how
/// much slack they get (poojari-geofence.md §2).
///
/// The server hands this out so the app can pre-check before sending a mark —
/// but it measures again itself on every `POST`, and its answer is the one
/// that counts. Treat a cached copy as a hint, never as permission.
class TempleLocation {
  const TempleLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;

  /// How far from ([latitude], [longitude]) still counts as "inside".
  final int radiusMeters;

  /// `latitude`/`longitude` arrive as **strings** — 6-place decimals that a
  /// JSON float would round off. [num] is still accepted because the same
  /// shape is echoed back inside a `403` body and costs nothing to tolerate.
  factory TempleLocation.fromJson(Map<String, dynamic> j) => TempleLocation(
    id: j['id'] as int? ?? 0,
    name: j['name'] as String? ?? '',
    latitude: _coord(j['latitude']),
    longitude: _coord(j['longitude']),
    radiusMeters: j['radius_meters'] as int? ?? 0,
  );

  static double _coord(Object? raw) => switch (raw) {
    num n => n.toDouble(),
    String s => double.tryParse(s) ?? 0,
    _ => 0,
  };
}
