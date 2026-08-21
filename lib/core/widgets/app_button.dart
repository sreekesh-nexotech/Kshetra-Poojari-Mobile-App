import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/typography.dart';

/// Visual variants of the design's CTA.
enum AppButtonVariant {
  /// Maroon fill, white label (login, verify, logout, dialog confirm).
  primary,

  /// White fill, muted `#494949` label (OTP-via-login, back buttons).
  secondary,

  /// Transparent fill, hairline/white outline (bulk cancel).
  outline,
}

/// Tappable CTA matching the design buttons. Height defaults to the 40px
/// control height; radius, glow and colors adapt per [variant].
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = AppButtonVariant.primary,
    this.radius = AppRadii.login,
    this.height = AppDimens.controlH,
    this.glow = false,
    this.fontSize = 15,
    this.fillColor,
    this.labelColor,
    this.outlineColor,
    this.trailing,
    this.width,
    this.expanded = false,
  });

  final String label;
  final VoidCallback onTap;
  final AppButtonVariant variant;

  /// Corner radius in design px. Auth CTAs use 10; in-card CTAs use 8.
  final double radius;
  final double height;

  /// Adds the warm `0 10px 20px #ECD3BC` login glow.
  final bool glow;
  final double fontSize;

  final Color? fillColor;
  final Color? labelColor;
  final Color? outlineColor;

  /// Optional trailing glyph widget (e.g. the "✓" on പൂർത്തിയായി).
  final Widget? trailing;

  final double? width;

  /// Stretch to the parent's full width.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Color fg;
    Border? outline;

    switch (variant) {
      case AppButtonVariant.primary:
        fill = fillColor ?? AppColors.maroon;
        fg = labelColor ?? AppColors.white;
        outline = null;
      case AppButtonVariant.secondary:
        fill = fillColor ?? AppColors.white;
        fg = labelColor ?? const Color(0xFF494949);
        outline = null;
      case AppButtonVariant.outline:
        fill = fillColor ?? Colors.transparent;
        fg = labelColor ?? AppColors.white;
        outline = Border.all(
          color: outlineColor ?? AppColors.white.withValues(alpha: 0.55),
          width: 1,
        );
    }

    Widget button = Container(
      width: expanded ? double.infinity : width,
      height: height.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius.r),
        border: outline,
        boxShadow: glow ? AppShadows.button() : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppText.malayalam(
              size: fontSize,
              weight: variant == AppButtonVariant.secondary
                  ? FontWeight.w600
                  : FontWeight.w700,
              color: fg,
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: 6.w),
            trailing!,
          ],
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: button,
    );
  }
}
