import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/ks_temple_background.dart';

/// Shared chrome for the auth screens: full-bleed (upright) temple photo with a
/// centred frosted-glass panel positioned [top] px from the top of the frame.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.top,
    required this.child,
    this.panelWidth = 320,
    this.background = AppColors.glass50,
    this.padding,
  });

  /// Panel offset from the top (design px).
  final double top;
  final Widget child;
  final double panelWidth;
  final Color background;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const KsTempleBackground(flipped: false),
          Positioned(
            top: top.h,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: panelWidth.w,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: padding ?? EdgeInsets.all(24.w),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline validation error line (12 maroon), matching the design's error text.
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: AppText.malayalam(size: 12, color: AppColors.maroon),
  );
}
