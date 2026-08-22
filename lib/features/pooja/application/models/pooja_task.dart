/// Lifecycle of a single pooja task.
enum TaskStatus { pending, done, cancelled }

/// **One booking: one pooja, one person, one date** — the unit the temple
/// performs and the unit a checkbox moves.
///
/// [id] is the server's `order_line.id`, and [orderId] is the checkout it
/// belongs to. Both are needed because `PATCH /api/poojari/pooja-management/`
/// takes one `order_id` plus the `order_line_ids` to move, so a selection
/// spanning several orders becomes several requests.
///
/// Immutable value object with [copyWith] — mutations go through the
/// controller, never by editing fields in place.
class PoojaTaskVm {
  const PoojaTaskVm({
    required this.id,
    required this.orderId,
    required this.categoryId,
    required this.poojaName,
    required this.person,
    required this.nakshatra,
    this.remark,
    this.price = 0,
    this.special = false,
    this.incentive = false,
    this.reassigned = false,
    this.status = TaskStatus.pending,
    this.doneAt,
    this.canMark = true,
  });

  /// Server `order_line.id` — globally unique.
  final int id;

  /// Server `order.id` — the PATCH envelope this booking sits in.
  final int orderId;

  /// Server `category_id` (the god).
  final int categoryId;

  /// Pooja name (group header), Malayalam.
  final String poojaName;

  /// Devotee name, English (Roboto).
  final String person;

  /// Nakshatra, Malayalam.
  final String nakshatra;

  /// Optional short remark ("ജോലിക്ക്", "പരീക്ഷയ്ക്ക്"…), Malayalam.
  final String? remark;

  /// This booking's own price. Needed to total a cancellation's refund.
  final double price;

  final bool special;
  final bool incentive;
  final bool reassigned;

  final TaskStatus status;

  /// Completion time label (e.g. "07:40 AM"), set when [status] is done.
  final String? doneAt;

  /// Whether the server will accept a status change at all — false once the
  /// booking is refunded or already cancelled.
  final bool canMark;

  bool get isPending => status == TaskStatus.pending;
  bool get isDone => status == TaskStatus.done;
  bool get isCancelled => status == TaskStatus.cancelled;
  bool get hasRemark => remark != null && remark!.isNotEmpty;

  PoojaTaskVm copyWith({
    TaskStatus? status,
    String? doneAt,
    bool clearDoneAt = false,
  }) {
    return PoojaTaskVm(
      id: id,
      orderId: orderId,
      categoryId: categoryId,
      poojaName: poojaName,
      person: person,
      nakshatra: nakshatra,
      remark: remark,
      price: price,
      special: special,
      incentive: incentive,
      reassigned: reassigned,
      status: status ?? this.status,
      doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
      canMark: canMark,
    );
  }
}
