/// The **execution** state of a booking. Not to be confused with `status`,
/// which is the *money* state (`confirmed`/`cod`/`cancelled`/`refunded`).
/// A refunded booking has `status: refunded` and `poojaStatus: cancelled`.
enum PoojaStatus { pending, completed, cancelled }

PoojaStatus poojaStatusFrom(String? raw) => switch (raw) {
  'completed' => PoojaStatus.completed,
  'cancelled' => PoojaStatus.cancelled,
  // `main` omits per-line pooja_status entirely; falling back to pending
  // keeps that response parseable (pooja.md appendix).
  _ => PoojaStatus.pending,
};

/// The person the pooja is performed for. Null for a counter walk-in.
class Devotee {
  const Devotee({required this.name, this.dob, this.time});

  final String name;
  final String? dob;
  final String? time;

  factory Devotee.fromJson(Map<String, dynamic> j) => Devotee(
    name: j['name'] as String? ?? '',
    dob: j['dob'] as String?,
    time: j['time'] as String?,
  );
}

/// **One booking: one pooja, one person, one date.** This is the unit the
/// temple performs, and the unit a checkbox on the list screen moves.
///
/// It is *not* the order — see [PoojaOrder].
class Booking {
  const Booking({
    required this.id,
    required this.status,
    required this.poojaStatus,
    required this.poojariId,
    required this.poojaDate,
    required this.price,
    this.devotee,
    this.nakshatram,
    this.isIncentivePooja = false,
    this.remarks = '',
    this.completedAt,
  });

  /// `order_line.id` — globally unique, and what `order_line_ids` names.
  final int id;

  /// The money state: confirmed | cod | cancelled | refunded.
  final String status;

  final PoojaStatus poojaStatus;

  /// null = unassigned, up for grabs. Your own id = assigned to you. On this
  /// endpoint it is never anyone else's.
  final int? poojariId;

  final DateTime? poojaDate;
  final double price;
  final Devotee? devotee;

  /// Spelled without the `a`. It is the wire name — do not "fix" it or the
  /// parser silently reads null.
  final String? nakshatram;

  /// Coin icon on the task row + the home progress card's incentive total.
  final bool isIncentivePooja;

  /// Short reason text under a task row ("ജോലിക്ക്", "പരീക്ഷയ്ക്ക്"…). Never
  /// null on the wire — empty when the devotee left no reason.
  final String remarks;

  /// Server-stamped when the booking is marked completed. Preferred over a
  /// device-local clock stamp so every client shows the same time.
  final DateTime? completedAt;

  bool get isSettled => status == 'cancelled' || status == 'refunded';
  bool get isDone => poojaStatus == PoojaStatus.completed;

  /// Whether a checkbox may move this row at all.
  bool get canMark => !isSettled && poojaStatus != PoojaStatus.cancelled;

  bool get isUnassigned => poojariId == null;

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
    id: j['id'] as int,
    status: j['status'] as String? ?? 'confirmed',
    poojaStatus: poojaStatusFrom(j['pooja_status'] as String?),
    poojariId: j['poojari_id'] as int?,
    poojaDate: DateTime.tryParse(j['pooja_date'] as String? ?? ''),
    // DRF renders Decimal as a String — "250.00", never 250.0.
    price: double.tryParse('${j['price'] ?? '0'}') ?? 0,
    devotee: j['user_list'] == null
        ? null
        : Devotee.fromJson(j['user_list'] as Map<String, dynamic>),
    nakshatram: j['nakshtram'] as String?,
    isIncentivePooja: j['is_incentive_pooja'] as bool? ?? false,
    remarks: j['remarks'] as String? ?? '',
    completedAt: DateTime.tryParse(j['completed_at'] as String? ?? ''),
  );
}
