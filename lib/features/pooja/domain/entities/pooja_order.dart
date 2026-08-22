import 'booking.dart';
import 'pooja_category.dart';

/// One checkout — a family paid once — holding several [Booking]s that can
/// span two gods, three dates and two poojaris.
///
/// Its [poojaStatus] is a **derived rollup**, recomputed server-side after
/// every write: `completed` when every standing booking is done, `cancelled`
/// when nothing stands, `pending` otherwise. Never write it, never compute it
/// locally — take the server's value out of the PATCH response.
class PoojaOrder {
  const PoojaOrder({
    required this.id,
    required this.poojaStatus,
    required this.status,
    required this.total,
    required this.bookings,
    this.poojaName,
    this.specialPooja = false,
    this.userEmail,
    this.createdAt,
  });

  final int id;
  final PoojaStatus poojaStatus;
  final String status;
  final double total;
  final List<Booking> bookings;

  /// Read off the *first* matching line only. With a mixed order it describes
  /// one booking, not the order.
  final String? poojaName;

  final bool specialPooja;
  final String? userEmail;
  final DateTime? createdAt;

  List<Booking> get markable => bookings.where((b) => b.canMark).toList();

  factory PoojaOrder.fromJson(Map<String, dynamic> j) => PoojaOrder(
    id: j['id'] as int,
    poojaStatus: poojaStatusFrom(j['pooja_status'] as String?),
    status: j['status'] as String? ?? 'confirmed',
    total: double.tryParse('${j['total'] ?? '0'}') ?? 0,
    poojaName: j['pooja_name'] as String?,
    specialPooja: j['special_pooja'] as bool? ?? false,
    userEmail: j['user_email'] as String?,
    createdAt: DateTime.tryParse(j['created_at'] as String? ?? ''),
    bookings: ((j['order_lines'] as List?) ?? const [])
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// The whole payload of `GET /api/poojari/pooja-management/?category_id=N`:
/// today's bookings for that god that are yours or nobody's.
///
/// "Today" is the temple's today (`Asia/Kolkata`), not the device's. Never
/// send a date — there is no date parameter.
class TodaysWork {
  const TodaysWork({required this.category, required this.orders});

  final PoojaCategory category;

  /// Sorted pending → completed → cancelled, oldest-first inside each group.
  /// That order is the work queue; preserve it.
  final List<PoojaOrder> orders;

  factory TodaysWork.fromJson(Map<String, dynamic> j) => TodaysWork(
    category: PoojaCategory.fromJson(j['category'] as Map<String, dynamic>),
    orders: ((j['orders'] as List?) ?? const [])
        .map((e) => PoojaOrder.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
