/// Error envelope for every poojari endpoint.
///
/// The app's own views return `{"error": "…"}`, occasionally with `"details"`
/// from the serializer. RBAC denials come from DRF itself and use
/// `{"detail": "…"}` — so both keys have to be read.
///
/// See `docs-flutter/pooja.md` §10.
class ApiException implements Exception {
  const ApiException(
    this.statusCode,
    this.message, {
    this.details,
    this.refundId,
    this.appError = false,
    this.distanceMeters,
    this.radiusMeters,
    this.location,
  });

  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;

  /// Present only on the cancel path, and only when Razorpay was reached.
  final String? refundId;

  /// The body carried an `error` key — i.e. one of the app's own views wrote
  /// it, not DRF's auth layer. This is the *only* thing separating an
  /// "outside the premises" `403` from an "your session is gone" `403`
  /// (poojari-geofence.md §3), and getting it wrong signs the poojari out for
  /// standing in the wrong car park.
  final bool appError;

  /// `403 Outside temple premises` only: how far the server measured them to
  /// be, and the radius it measured against.
  final int? distanceMeters;
  final int? radiusMeters;

  /// The server's current site config, echoed inside a geofence `403`. When it
  /// disagrees with the cached one, the cached one is stale.
  final Map<String, dynamic>? location;

  factory ApiException.fromResponse(int code, Map<String, dynamic> body) =>
      ApiException(
        code,
        (body['error'] ?? body['detail'] ?? 'Something went wrong') as String,
        details: body['details'] as Map<String, dynamic>?,
        refundId: body['refund_id'] as String?,
        appError: body.containsKey('error'),
        distanceMeters: (body['distance_meters'] as num?)?.round(),
        radiusMeters: (body['radius_meters'] as num?)?.round(),
        location: body['location'] as Map<String, dynamic>?,
      );

  /// The back office gave this booking to someone else while the list was open.
  bool get isAssignedToSomeoneElse =>
      statusCode == 403 && message.contains('assigned to another poojari');

  /// The list on screen no longer matches the server — reload it.
  bool get isStaleOrder =>
      statusCode == 404 ||
      (statusCode == 400 &&
          (message.contains('are not on order') ||
              message.contains('already cancelled') ||
              message.contains('No active bookings')));

  /// Money left Razorpay but the database did not record it. **Never retry** —
  /// a retry could refund the devotee twice. Show the [refundId] and tell the
  /// poojari to call the temple office.
  bool get needsManualReconciliation => statusCode == 500 && refundId != null;

  /// A `403` from **DRF's auth layer** — session expired, or the account is
  /// not a poojari. Those two are themselves ambiguous, and the caller
  /// disambiguates them by asking the cookie jar whether a `sessionid` is
  /// still held.
  ///
  /// [appError] is what keeps an application `403` (outside the premises, a
  /// booking reassigned) out of here: auth denials return `detail` only, never
  /// an `error` key, and treating one of the others as an auth failure would
  /// wipe the session over a business rule.
  bool get isForbidden => statusCode == 403 && !appError;

  /// `403` from the attendance geofence — the mark was taken outside the
  /// radius and **no row was written**. Detected structurally: it is the only
  /// `403` that reports a measured distance (poojari-geofence.md §3).
  bool get isOutsidePremises =>
      statusCode == 403 && distanceMeters != null && radiusMeters != null;

  /// `409` — the temple has no attendance site configured (or none this
  /// poojari is assigned to). A deployment problem, not the poojari's.
  bool get isNoTempleLocation => statusCode == 409 && appError;

  bool get isThrottled => statusCode == 429;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
