/// The Malayalam (Kollavarsham) calendar date for the home greeting card.
///
/// The server pre-formats the whole string — `formattedMl` is the only field
/// the greeting card renders (`POOJARI_APP_API.md` §1).
class Panchangam {
  const Panchangam({required this.formattedMl});

  /// e.g. `"1202 ചിങ്ങം 15, ഞായറ്"` — ready to render as-is.
  final String formattedMl;

  factory Panchangam.fromJson(Map<String, dynamic> j) =>
      Panchangam(formattedMl: j['formatted_ml'] as String? ?? '');
}
