import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'colors.dart';
import 'typography.dart';

/// Corner radii (design tokens). Values are logical px at the 375-wide
/// baseline; call `.r` at the use-site so they scale with ScreenUtil.
abstract final class AppRadii {
  AppRadii._();

  /// Inputs, CTAs, task cards. `--ks-radius-input`.
  static const double input = 8;

  /// Image / stat cards, back-chip. `--ks-radius-card`.
  static const double card = 12;

  /// Login-kit fields + buttons. `--ks-radius-login`.
  static const double login = 10;

  /// Device screen. `--ks-radius-screen`.
  static const double screen = 20;

  /// Status filter chips / reassigned pills. `16px` pill.
  static const double chip = 16;

  /// Small count pill on group headers. `10px`.
  static const double pill = 10;

  /// Checkbox tile. `6px`.
  static const double checkbox = 6;
}

/// Spacing scale used across the design (column gaps 8 / 12 / 16 / 24, gutter).
abstract final class AppSpacing {
  AppSpacing._();

  static const double gutter = 16;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Fixed layout dimensions from the design system.
abstract final class AppDimens {
  AppDimens._();

  static const double screenW = 375;
  static const double screenH = 812;

  /// Inputs, selects, CTAs. `--ks-control-h`.
  static const double controlH = 40;

  /// Bottom navbar. `--ks-navbar-h`.
  static const double navbarH = 82;
}

/// Warm, down-right elevation. Offsets/blur scale with ScreenUtil, so these
/// are builder methods rather than consts.
abstract final class AppShadows {
  AppShadows._();

  /// `8px 8px 16px rgba(82,45,14,0.16)` — standard warm card lift.
  static List<BoxShadow> card() => [
        BoxShadow(
          color: AppColors.brown.withValues(alpha: 0.16),
          offset: Offset(8.w, 8.h),
          blurRadius: 16.r,
        ),
      ];

  /// `8px 8px 16px rgba(82,45,14,0.3)` — hero poster / modal.
  static List<BoxShadow> poster() => [
        BoxShadow(
          color: AppColors.brown.withValues(alpha: 0.3),
          offset: Offset(8.w, 8.h),
          blurRadius: 16.r,
        ),
      ];

  /// `0px -8px 8px rgba(0,0,0,0.08)` — bottom navbar.
  static List<BoxShadow> nav() => [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.08),
          offset: Offset(0, -8.h),
          blurRadius: 8.r,
        ),
      ];

  /// `0 10px 20px rgb(236,211,188)` — warm login-CTA glow.
  static List<BoxShadow> button() => [
        BoxShadow(
          color: AppColors.ctaGlow,
          offset: Offset(0, 10.h),
          blurRadius: 20.r,
        ),
      ];

  /// `0 1px 4px rgba(12,12,13,0.1), 0 1px 4px rgba(12,12,13,0.05)` — dropdown.
  static List<BoxShadow> menu() => [
        BoxShadow(
          color: const Color(0xFF0C0C0D).withValues(alpha: 0.1),
          offset: Offset(0, 1.h),
          blurRadius: 4.r,
        ),
        BoxShadow(
          color: const Color(0xFF0C0C0D).withValues(alpha: 0.05),
          offset: Offset(0, 1.h),
          blurRadius: 4.r,
        ),
      ];

  /// `8px 8px 16px rgba(140,0,26,0.3)` — pooja selection action bar.
  static List<BoxShadow> selectionBar() => [
        BoxShadow(
          color: AppColors.maroon.withValues(alpha: 0.3),
          offset: Offset(8.w, 8.h),
          blurRadius: 16.r,
        ),
      ];

  /// `inset 0 0 0 1px #D9D9D9` — hairline border (emulated via [Border]).
  static Border hairline([Color color = AppColors.border]) =>
      Border.all(color: color, width: 1);
}

/// Assembles the app-wide [ThemeData]. Kept thin — most styling lives on
/// tokenised widgets, not the global theme.
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: AppFonts.malayalam,
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.white,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.maroon,
      secondary: AppColors.cream,
      surface: AppColors.white,
      error: AppColors.maroon,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
