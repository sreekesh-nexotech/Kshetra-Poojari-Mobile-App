import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/application/providers/attendance_controller.dart';
import '../mock/profile_mock_data.dart';
import '../models/profile_models.dart';

/// The signed-in poojari. Replace the mock read with a session/profile
/// repository on API integration.
final poojariProvider = Provider<PoojariVm>((ref) => ProfileMockData.poojari);

/// Month label + KPIs (till-now settlement figures).
final monthLabelProvider =
    Provider<String>((ref) => ProfileMockData.monthLabel);

final monthKpisProvider =
    Provider<List<MonthKpi>>((ref) => ProfileMockData.monthKpis);

/// Week attendance strip: six settled days + today (live from check-in).
final weekStripProvider = Provider<List<WeekDay>>((ref) {
  final checkedIn = ref.watch(isCheckedInProvider);
  return [
    ...ProfileMockData.weekPast,
    WeekDay(
      label: 'S',
      mark: checkedIn ? '✓' : '–',
      kind: WeekDayKind.today,
    ),
  ];
});
