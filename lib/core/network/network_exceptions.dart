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
  });

  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;

  /// Present only on the cancel path, and only when Razorpay was reached.
  final String? refundId;

  factory ApiException.fromResponse(int code, Map<String, dynamic> body) =>
      ApiException(
        code,
        (body['error'] ?? body['detail'] ?? 'Something went wrong') as String,
        details: body['details'] as Map<String, dynamic>?,
        refundId: body['refund_id'] as String?,
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

  /// A `403` is ambiguous: an unauthenticated caller and a caller missing a
  /// permission look almost identical. The caller disambiguates by asking the
  /// cookie jar whether a `sessionid` is still held.
  bool get isForbidden => statusCode == 403;

  bool get isThrottled => statusCode == 429;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
