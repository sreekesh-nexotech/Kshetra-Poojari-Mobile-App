import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'colors.dart';

/// Font family names — must match the `family:` keys declared in pubspec.yaml.
abstract final class AppFonts {
  AppFonts._();

  /// Product type. Rendered condensed (wdth 75) app-wide, per the design.
  static const String malayalam = 'NotoSansMalayalam';

  /// Rare bold section-label accent.
  static const String serif = 'NotoSerifMalayalam';

  /// Latin data lines: names, dates, counts, ₹ amounts.
  static const String latin = 'Roboto';

  /// Dashboard stat numbers.
  static const String stat = 'PlusJakartaSans';

  /// Fallback covering ✓ / ✕ marks the primary faces lack.
  static const String symbols = 'NotoSansSymbols2';
}

/// Shared fallback so stray ✓ / ✕ text glyphs always render.
const List<String> _symbolFallback = [AppFonts.symbols];

/// The condensed width the design applies to all Malayalam type
/// (`font-stretch: 75%`). Noto Sans Malayalam exposes a `wdth` axis (62.5–100).
const double kMalayalamWidth = 75;

/// Text-style factory. Callers pass raw design px (e.g. `size: 16`); ScreenUtil
/// scaling (`.sp`) is applied here so no widget hardcodes a font size.
///
/// Never wrap the returned styles in `const` — they depend on `.sp`.
abstract final class AppText {
  AppText._();

  /// Malayalam product type, rendered condensed (wdth 75) to match the design.
  static TextStyle malayalam({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: AppFonts.malayalam,
      fontFamilyFallback: _symbolFallback,
      fontSize: size.sp,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontVariations: [
        FontVariation('wght', weight.value.toDouble()),
        const FontVariation('wdth', kMalayalamWidth),
      ],
    );
  }

  /// Latin data (Roboto) — names, dates, zero-padded counts, ₹ amounts.
  static TextStyle latin({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: AppFonts.latin,
      fontFamilyFallback: _symbolFallback,
      fontSize: size.sp,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
    );
  }

  /// Plus Jakarta Sans — dashboard stat numbers.
  static TextStyle stat({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.navy,
    double? height,
  }) {
    return TextStyle(
      fontFamily: AppFonts.stat,
      fontFamilyFallback: _symbolFallback,
      fontSize: size.sp,
      fontWeight: weight,
      color: color,
      height: height,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
    );
  }

  /// Noto Serif Malayalam bold — the small section-label accent (12/700).
  static TextStyle serif({
    double size = 12,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.black,
    double? height,
  }) {
    return TextStyle(
      fontFamily: AppFonts.serif,
      fontFamilyFallback: _symbolFallback,
      fontSize: size.sp,
      fontWeight: weight,
      color: color,
      height: height,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
    );
  }
}
