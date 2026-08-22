/// Date / clock helpers.
abstract final class AppTime {
  AppTime._();

  /// Formats [when] as the design's clock label, e.g. `07:40 AM` — 12-hour,
  /// zero-padded hours and minutes. Mirrors the prototype's `now()`.
  static String clockLabel([DateTime? when]) {
    final d = when ?? DateTime.now();
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final hh = h12.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm $ap';
  }

  /// Zero-pads a count to two digits, as the design does (`03`, `42`).
  static String pad2(int n) => n.toString().padLeft(2, '0');
}
