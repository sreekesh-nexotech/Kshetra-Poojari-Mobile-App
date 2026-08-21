import '../models/profile_models.dart';

/// ── MOCK DATA SEAM — profile / account ───────────────────────────────────────
/// Static demo profile, month KPIs and the fixed part of the week strip.
/// Replace with `ProfileRepository.profile()` + `AttendanceRepository.week()`
/// on API integration.
abstract final class ProfileMockData {
  ProfileMockData._();

  static const PoojariVm poojari = PoojariVm(
    name: 'Harichandran',
    phone: '9142 2245 22',
    poojariId: '02548',
    assignedGodsLabel: 'ശ്രീ ഗണപതി · ശ്രീ ഭഗവതി',
  );

  static const String monthLabel = 'ഈ മാസം — സെപ്റ്റംബർ';

  static const List<MonthKpi> monthKpis = [
    MonthKpi(value: '24/26', label: 'ഹാജർ ദിനങ്ങൾ'),
    MonthKpi(value: '1,148', label: 'ആകെ പൂജകൾ'),
    MonthKpi(value: '36', label: 'സ്പെഷ്യൽ പൂജകൾ'),
    MonthKpi(value: '₹2,400', label: 'ഇൻസെന്റീവ് · ഇതുവരെ', accent: true),
  ];

  /// The six settled days of the week strip (Sun–Fri). Saturday ("today") is
  /// appended live from the check-in state by the provider.
  static const List<WeekDay> weekPast = [
    WeekDay(label: 'S', mark: '✓', kind: WeekDayKind.present),
    WeekDay(label: 'M', mark: '✓', kind: WeekDayKind.present),
    WeekDay(label: 'T', mark: '✓', kind: WeekDayKind.present),
    WeekDay(label: 'W', mark: '✕', kind: WeekDayKind.absent),
    WeekDay(label: 'T', mark: '✓', kind: WeekDayKind.present),
    WeekDay(label: 'F', mark: '✓', kind: WeekDayKind.present),
  ];
}
