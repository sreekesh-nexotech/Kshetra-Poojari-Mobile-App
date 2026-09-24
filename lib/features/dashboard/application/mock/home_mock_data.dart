/// Static app copy for the home header that isn't backend data. The
/// Malayalam calendar date and upcoming-day counts used to live here too —
/// they now come from `GET /api/poojari/panchangam/` and
/// `GET /api/poojari/upcoming-pooja-counts/` via [DashboardFeedController]
/// (see `home_providers.dart`).
abstract final class HomeMockData {
  HomeMockData._();

  static const String greeting = 'നമസ്കാരം';
}
