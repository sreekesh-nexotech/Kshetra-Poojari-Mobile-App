import 'booking.dart';

/// The reply to `PATCH /api/poojari/pooja-management/`.
///
/// Three different success bodies arrive here:
/// * `completed`/`pending` — carries `bookings_updated`.
/// * `cancelled`, nothing captured — **no `bookings_updated` key at all**.
/// * `cancelled`, paid — adds `refund_id` and `refund_amount`.
///
/// Note the embedded `order` is the **detail** serializer, not the list one:
/// its `order_lines` carry only `id, pooja_name, status, pooja_status,
/// poojari` — no devotee, no date, no price — and they cover *every* line on
/// the order, not just the ones for your god. So merge it into what you hold;
/// never replace a list row with it.
class StatusUpdateResult {
  const StatusUpdateResult({
    required this.message,
    required this.orderPoojaStatus,
    required this.orderStatus,
    required this.lineStatuses,
    this.bookingsUpdated,
    this.refundId,
    this.refundAmount,
  });

  final String message;

  /// The server's rollup. Take it; never derive it.
  final PoojaStatus orderPoojaStatus;
  final String orderStatus;

  /// line id -> its new pooja_status, for the lines this response mentions.
  final Map<int, PoojaStatus> lineStatuses;

  /// Absent on both cancel paths, so nullable.
  final int? bookingsUpdated;

  final String? refundId;
  final double? refundAmount;

  /// The devotee's refund is now in flight at Razorpay. Say so.
  bool get refundStarted => refundId != null;

  factory StatusUpdateResult.fromJson(Map<String, dynamic> j) {
    final order = j['order'] as Map<String, dynamic>;
    final lines = (order['order_lines'] as List?) ?? const [];
    return StatusUpdateResult(
      message: j['message'] as String? ?? '',
      bookingsUpdated: j['bookings_updated'] as int?,
      refundId: j['refund_id'] as String?,
      refundAmount: j['refund_amount'] == null
          ? null
          : double.tryParse('${j['refund_amount']}'),
      orderPoojaStatus: poojaStatusFrom(order['pooja_status'] as String?),
      orderStatus: order['status'] as String? ?? '',
      lineStatuses: {
        for (final l in lines.cast<Map<String, dynamic>>())
          l['id'] as int: poojaStatusFrom(l['pooja_status'] as String?),
      },
    );
  }
}
