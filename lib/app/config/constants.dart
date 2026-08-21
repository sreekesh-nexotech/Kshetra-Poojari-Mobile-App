import 'package:flutter/widgets.dart';

/// Global, non-visual constants (visual tokens live under `app/theme/`).
abstract final class AppConstants {
  AppConstants._();

  /// ScreenUtil design baseline — the design frame is 375 × 812.
  static const Size designSize = Size(375, 812);

  /// Toast auto-dismiss duration (design used a 2.4 s timeout).
  static const Duration toastDuration = Duration(milliseconds: 2400);

  /// Standard calm transition ceiling from the design ("fades ≤ 200ms").
  static const Duration shortAnim = Duration(milliseconds: 200);

  /// Slide-to-confirm settle animation.
  static const Duration slideSettle = Duration(milliseconds: 250);
}
