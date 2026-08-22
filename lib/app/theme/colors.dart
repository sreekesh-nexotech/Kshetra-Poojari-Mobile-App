import 'package:flutter/material.dart';

/// Kshetra brand palette — transcribed 1:1 from the design system tokens
/// (`_ds/.../tokens/kshetra.css`) plus the literal rgb() values used inline in
/// the `Poojary App.dc.html` prototype.
///
/// Names use lowerCamelCase to satisfy `constant_identifier_names`
/// (the Dart/Flutter lint prefers camelCase over SCREAMING_CAPS for consts).
abstract final class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  /// Primary brand: CTAs, headings, selected states. `rgb(140,0,26)`.
  static const Color maroon = Color(0xFF8C001A);

  /// Pressed / secondary links. `rgba(140,0,26,0.8)`.
  static const Color maroon80 = Color(0xCC8C001A);

  /// Figma "Brand B/800". `rgb(119,0,0)`.
  static const Color maroonDeep = Color(0xFF770000);

  /// Muted brand: inactive nav glyphs, tertiary links. `rgb(192,121,126)`.
  static const Color rose = Color(0xFFC0797E);

  /// Warm surface: navbar, incentive coin, cream headers. `rgb(251,239,217)`.
  static const Color cream = Color(0xFFFBEFD9);

  /// Active / selected input fill. `rgb(251,246,241)`.
  static const Color creamInput = Color(0xFFFBF6F1);

  /// Shadow + protection-gradient base. `rgb(82,45,14)`.
  static const Color brown = Color(0xFF522D0E);

  // ── Neutrals ───────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);

  /// Text on maroon. `rgb(242,242,242)`.
  static const Color offWhite = Color(0xFFF2F2F2);

  /// Primary text. `rgb(30,30,30)`.
  static const Color ink = Color(0xFF1E1E1E);

  /// Secondary headings. `rgb(51,51,51)`.
  static const Color ink2 = Color(0xFF333333);

  static const Color black = Color(0xFF000000);

  /// Captions. `rgb(130,128,128)`.
  static const Color grayText = Color(0xFF828080);

  static const Color grayMid = Color(0xFF757575);

  /// Dashboard sublabels. `rgb(117,109,120)`.
  static const Color grayMuted = Color(0xFF756D78);

  /// Input placeholder. `rgb(179,179,179)`.
  static const Color grayPlaceholder = Color(0xFFB3B3B3);

  /// Inactive checkbox border / tab text. `rgb(178,178,178)`.
  static const Color grayInactive = Color(0xFFB2B2B2);

  /// Default input / card hairline border. `rgb(217,217,217)`.
  static const Color border = Color(0xFFD9D9D9);

  /// Stat numbers. `rgb(16,24,40)`.
  static const Color navy = Color(0xFF101828);

  // ── Functional accents ─────────────────────────────────────────────────────
  /// Progress-bar fill. `rgb(253,176,34)`.
  static const Color amber = Color(0xFFFDB022);

  /// Progress track / thin dividers. `rgb(234,236,240)`.
  static const Color track = Color(0xFFEAECF0);

  /// Warm login-CTA glow. `rgb(236,211,188)`.
  static const Color ctaGlow = Color(0xFFECD3BC);

  // ── Overlays / glass ───────────────────────────────────────────────────────
  /// Modal scrim. `rgba(0,0,0,0.45)`.
  static const Color scrim = Color(0x73000000);

  /// Home greeting glass card. `rgba(255,255,255,0.5)`.
  static const Color glass50 = Color(0x80FFFFFF);

  /// Account profile / login glass. `rgba(255,255,255,0.85)`.
  static const Color glass85 = Color(0xD9FFFFFF);

  /// Password-done glass. `rgba(255,255,255,0.6)`.
  static const Color glass60 = Color(0x99FFFFFF);

  /// Login form glass. `rgba(255,255,255,0.5)` (alias of [glass50]).
  static const Color glassLogin = Color(0x80FFFFFF);

  /// Selected nav-tile fill. `rgba(255,255,255,0.3)`.
  static const Color navTileGlass = Color(0x4DFFFFFF);
}
