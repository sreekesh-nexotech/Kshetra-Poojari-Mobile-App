import '../../domain/entities/booking.dart';
import '../../domain/entities/pooja_category.dart';
import '../../domain/entities/pooja_order.dart';
import '../models/god.dart';
import '../models/pooja_task.dart';

/// Turns domain entities into the view-models the widgets already read.
///
/// This is the only place the two vocabularies meet. Four things the UI shows
/// have no field in the API and degrade rather than block the screen:
///
/// | UI            | Source                                        |
/// |---------------|-----------------------------------------------|
/// | `remark`      | none — stays null, the subtitle just vanishes  |
/// | `incentive`   | none — stays false, the coin never renders     |
/// | `doneAt`      | stamped locally on a successful mark only      |
/// | `reassigned`  | proxy: `poojari_id == null` (up for grabs)     |
extension PoojaCategoryMapper on PoojaCategory {
  GodVm toVm() => GodVm(id: id, name: name, imageUrl: mediaUrl);
}

extension TodaysWorkMapper on TodaysWork {
  /// Flattens orders into one booking per row, preserving the server's order —
  /// pending → completed → cancelled, oldest-first — because that ordering is
  /// the work queue.
  List<PoojaTaskVm> toTasks() => [
    for (final order in orders)
      for (final booking in order.bookings) _task(booking, order, category.id),
  ];
}

PoojaTaskVm _task(Booking b, PoojaOrder order, int categoryId) => PoojaTaskVm(
  id: b.id,
  orderId: order.id,
  categoryId: categoryId,
  // Order-level: the server reads it off the first matching line. Right in
  // the common case because the fetch is already scoped to one god.
  poojaName: order.poojaName ?? '',
  // A counter walk-in has no devotee record.
  person: b.devotee?.name ?? kWalkInPlaceholder,
  nakshatra: b.nakshatram ?? '',
  price: b.price,
  special: order.specialPooja,
  reassigned: b.isUnassigned,
  status: _statusOf(b),
  canMark: b.canMark,
);

/// The money state overrides the execution state: a refunded or cancelled
/// booking reads as cancelled on screen whatever its `pooja_status` says.
TaskStatus _statusOf(Booking b) {
  if (b.isSettled) return TaskStatus.cancelled;
  return switch (b.poojaStatus) {
    PoojaStatus.completed => TaskStatus.done,
    PoojaStatus.cancelled => TaskStatus.cancelled,
    PoojaStatus.pending => TaskStatus.pending,
  };
}

/// Shown where a devotee name would be for a counter booking.
const String kWalkInPlaceholder = '—';

/// The reverse direction, for sending a row's new state back to the server.
TaskStatus taskStatusFrom(PoojaStatus s) => switch (s) {
  PoojaStatus.completed => TaskStatus.done,
  PoojaStatus.cancelled => TaskStatus.cancelled,
  PoojaStatus.pending => TaskStatus.pending,
};

PoojaStatus poojaStatusOf(TaskStatus s) => switch (s) {
  TaskStatus.done => PoojaStatus.completed,
  TaskStatus.cancelled => PoojaStatus.cancelled,
  TaskStatus.pending => PoojaStatus.pending,
};
