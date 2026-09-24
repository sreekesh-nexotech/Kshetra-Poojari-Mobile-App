import 'package:kshetra_poojari/features/auth/application/states/session_state.dart';
import 'package:kshetra_poojari/features/auth/domain/entities/user.dart';
import 'package:kshetra_poojari/features/profile/application/models/profile_models.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// TEST FIXTURE — the design's demo profile, month KPIs and week strip.
///
/// This used to be the app's mock seam (`ProfileMockData`); now that the
/// account screen reads the API it lives here, pinning the goldens to a
/// dataset that never moves. Wire it in with `kFixtureOverrides` (see
/// `fixture_overrides.dart`).
/// ─────────────────────────────────────────────────────────────────────────
abstract final class ProfileFixture {
  ProfileFixture._();

  /// A signed-in session, so `poojariProvider` exercises its real
  /// (authenticated) branch instead of the "no session" fallback.
  static const SessionState session = SessionState(
    status: SessionStatus.authenticated,
    user: PoojariUser(
      id: 1,
      username: 'harichandran',
      firstName: 'Harichandran',
      phoneNumber: '9142 2245 22',
      employeeId: '02548',
    ),
  );

  static const String assignedGodsLabel = 'ശ്രീ ഗണപതി · ശ്രീ ഭഗവതി';

  static const List<MonthKpi> monthKpis = [
    MonthKpi(value: '24/26', label: 'ഹാജർ ദിനങ്ങൾ'),
    MonthKpi(value: '1,148', label: 'ആകെ പൂജകൾ'),
    MonthKpi(value: '36', label: 'സ്പെഷ്യൽ പൂജകൾ'),
    MonthKpi(value: '₹2,400', label: 'ഇൻസെന്റീവ് · ഇതുവരെ', accent: true),
  ];

  /// The 6 non-today days of the week strip. Today is appended live from
  /// check-in state by `weekStripProvider`.
  static const List<WeekDay> weekDays = [
    WeekDay(label: 'S', mark: '✓', kind: WeekDayKind.present),
    WeekDay(label: 'M', mark: '✓', kind: WeekDayKind.present),
    WeekDay(label: 'T', mark: '✓', kind: WeekDayKind.present),
    WeekDay(label: 'W', mark: '✕', kind: WeekDayKind.absent),
    WeekDay(label: 'T', mark: '✓', kind: WeekDayKind.present),
    WeekDay(label: 'F', mark: '✓', kind: WeekDayKind.present),
  ];
}
