import '../entities/panchangam.dart';
import '../entities/temple_location.dart';
import '../entities/upcoming_pooja_count.dart';

/// What the home screen needs from the outside world, beyond the pooja and
/// attendance features it already shares with the pooja tab.
abstract interface class DashboardRepository {
  /// Today's Malayalam calendar date for the greeting card.
  Future<Panchangam> panchangam();

  /// Pooja counts for the next [days] days (max 14), optionally scoped to
  /// one deity via [categoryId].
  Future<List<UpcomingPoojaCount>> upcomingPoojaCounts({
    int days = 3,
    int? categoryId,
  });

  /// Where the poojari has to be standing to mark today present, and how far
  /// from it still counts. `null` when the temple has configured no site —
  /// which is not a geofence-free pass but the opposite: marking is
  /// impossible until someone in the office sets one up
  /// (poojari-geofence.md §2).
  Future<TempleLocation?> attendanceLocation();

  /// Marks today present on the backend's attendance sheet. There is no
  /// server concept of a check-out timestamp — attendance is one
  /// present/absent/leave mark per calendar day (poojari-app.md §5) — so this
  /// is only ever called on check-in.
  ///
  /// The coordinates are required rather than optional because this app only
  /// ever marks *today, present*, and that is exactly the case the server
  /// geofences: it refuses the mark without them (`400`) and refuses it again
  /// if they land outside the radius (`403`). A future leave/absent or
  /// backdated mark would take neither.
  Future<void> markAttendance({
    required String latitude,
    required String longitude,
  });

  /// When today was already marked present — on a previous run of the app,
  /// or another device — so a restart can restore the check-in card instead
  /// of showing "not marked" for a day that is actually on the books. `null`
  /// when today has no `present` mark yet.
  Future<DateTime?> todayCheckIn();
}
