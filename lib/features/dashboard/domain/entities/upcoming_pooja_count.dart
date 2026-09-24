/// One tile of the home screen's "വരും ദിവസങ്ങൾ" row —
/// a day's pooja count (`POOJARI_APP_API.md` §2).
class UpcomingPoojaCount {
  const UpcomingPoojaCount({
    required this.date,
    required this.label,
    required this.count,
  });

  /// `YYYY-MM-DD`, Asia/Kolkata.
  final String date;

  /// `"Tomorrow"`, `"Day after tomorrow"`, then the English weekday name
  /// (`"Monday"`, …) for day 3+.
  final String label;

  final int count;

  factory UpcomingPoojaCount.fromJson(Map<String, dynamic> j) =>
      UpcomingPoojaCount(
        date: j['date'] as String? ?? '',
        label: j['label'] as String? ?? '',
        count: j['count'] as int? ?? 0,
      );
}
