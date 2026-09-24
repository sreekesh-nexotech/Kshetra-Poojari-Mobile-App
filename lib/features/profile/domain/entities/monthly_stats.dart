/// `GET /api/poojari/monthly-stats/` — this poojari's current-month totals
/// for the profile KPI tiles (`POOJARI_APP_API.md` §5).
class MonthlyStats {
  const MonthlyStats({
    required this.totalPoojas,
    required this.specialPoojas,
    required this.incentiveEarned,
  });

  final int totalPoojas;
  final int specialPoojas;

  /// INR, summed over this month's completed bookings.
  final double incentiveEarned;

  factory MonthlyStats.fromJson(Map<String, dynamic> j) => MonthlyStats(
    totalPoojas: j['total_poojas'] as int? ?? 0,
    specialPoojas: j['special_poojas'] as int? ?? 0,
    // DRF renders Decimal as a String — "2400.00", never 2400.0.
    incentiveEarned: double.tryParse('${j['incentive_earned'] ?? '0'}') ?? 0,
  );
}
