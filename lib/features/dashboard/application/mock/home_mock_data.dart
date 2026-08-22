import '../models/home_view_models.dart';

/// ── MOCK DATA SEAM — home header + upcoming counts ───────────────────────────
/// Static demo content mirroring the design. Replace the date strings with a
/// panchangam/date service and the upcoming counts with
/// `DashboardRepository.upcoming()` on API integration.
abstract final class HomeMockData {
  HomeMockData._();

  static const String greeting = 'നമസ്കാരം';

  /// Kollam-era Malayalam calendar date (design keeps both calendars).
  static const String malayalamDate = '1180 കർക്കിടകം 22, ശനി';

  /// Gregorian date.
  static const String gregorianDate = 'September 09, 2025';

  /// Next-3-days counts (design: 42 / 29 / 55).
  static const List<UpcomingDay> upcoming = [
    UpcomingDay(label: 'നാളെ', count: 42),
    UpcomingDay(label: 'മറ്റന്നാൾ', count: 29),
    UpcomingDay(label: 'Sep 12', count: 55, latinLabel: true),
  ];
}
