import 'package:kshetra_poojari/features/dashboard/application/models/home_view_models.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// TEST FIXTURE — the design's demo greeting-card date + upcoming counts.
///
/// This used to be the app's mock seam (`HomeMockData`); now that the home
/// screen reads the API it lives here, pinning the goldens to a dataset that
/// never moves. Wire it in with `kFixtureOverrides` (see
/// `fixture_overrides.dart`).
/// ─────────────────────────────────────────────────────────────────────────
abstract final class DashboardFixture {
  DashboardFixture._();

  static const String malayalamDate = '1180 കർക്കിടകം 22, ശനി';

  static const List<UpcomingDay> upcoming = [
    UpcomingDay(label: 'നാളെ', count: 42),
    UpcomingDay(label: 'മറ്റന്നാൾ', count: 29),
    UpcomingDay(label: 'Sep 12', count: 55, latinLabel: true),
  ];
}
