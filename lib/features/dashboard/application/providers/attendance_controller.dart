import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/attendance_state.dart';

/// Owns today's attendance. Pure state — the location/premises gate and toast
/// live in the widgets that call [checkIn] / [checkOut].
///
/// Global (not autoDispose): attendance must persist while the poojari moves
/// between the home, pooja and account tabs.
class AttendanceController extends StateNotifier<AttendanceState> {
  AttendanceController() : super(const AttendanceState());

  void checkIn(String time) =>
      state = state.copyWith(checkInAt: time, clearExpandedOverride: true);

  void checkOut(String time) =>
      state = state.copyWith(checkOutAt: time, clearExpandedOverride: true);

  void toggleExpanded() =>
      state = state.copyWith(expandedOverride: !state.expanded);
}

final attendanceControllerProvider =
    StateNotifierProvider<AttendanceController, AttendanceState>(
  (ref) => AttendanceController(),
);

/// True once the poojari has checked in — gates the pooja tab.
final isCheckedInProvider = Provider<bool>(
  (ref) => ref.watch(attendanceControllerProvider.select((s) => s.started)),
);

/// True once checked out — flips the home tally to "today's summary".
final isCheckedOutProvider = Provider<bool>(
  (ref) => ref.watch(
    attendanceControllerProvider.select((s) => s.checkOutAt != null),
  ),
);
