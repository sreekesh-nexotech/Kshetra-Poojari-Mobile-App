import '../entities/booking.dart';
import '../entities/pooja_category.dart';
import '../entities/pooja_order.dart';
import '../entities/status_update.dart';

/// What the pooja feature needs from the outside world.
///
/// The application layer talks only to this; nothing above `infrastructure/`
/// ever calls `fromJson`. Implementations throw [ApiException] on a non-2xx.
abstract interface class PoojaRepository {
  /// The shrine picker's gods, already sorted by `sort_order`.
  Future<List<PoojaCategory>> gods();

  /// Today's bookings for one god that are yours or nobody's.
  /// [categoryId] is mandatory — there is no "all gods" view.
  Future<TodaysWork> todaysWork(int categoryId);

  /// Move [bookingIds] on [orderId] to [status].
  ///
  /// [bookingIds] must be non-empty: omitting the key server-side moves
  /// *every* booking on the order, across other poojas, dates and people.
  Future<StatusUpdateResult> markBookings({
    required int orderId,
    required List<int> bookingIds,
    required PoojaStatus status,
  });
}
