/// The signed-in poojari's profile.
class PoojariVm {
  const PoojariVm({required this.name, required this.phone, this.poojariId});

  /// English name (Roboto).
  final String name;

  /// "9142 2245 22".
  final String phone;

  /// "02548". Null until an admin assigns one — the ID badge renders
  /// conditionally, never a placeholder.
  final String? poojariId;

  /// Avatar initial (names are English, so a plain substring is safe).
  String get initial => name.trim().isEmpty ? '' : name.trim().substring(0, 1);
}

/// A month KPI tile (design 2×2 grid).
class MonthKpi {
  const MonthKpi({
    required this.value,
    required this.label,
    this.accent = false,
  });

  /// "24/26", "1,148", "₹2,400"…
  final String value;
  final String label;

  /// Maroon value (the incentive tile) instead of navy.
  final bool accent;
}

/// Visual role of a day dot in the week strip.
enum WeekDayKind {
  present,
  absent,

  /// No mark on record for that day yet (neither present, absent, nor
  /// leave) — distinct from [absent] so an unmarked day doesn't read as a
  /// missed one.
  notMarked,
  today,
}

/// One day in the account week attendance strip.
class WeekDay {
  const WeekDay({required this.label, required this.mark, required this.kind});

  /// "S" / "M" / "T"…
  final String label;

  /// "✓" / "✕" / "–".
  final String mark;
  final WeekDayKind kind;
}
