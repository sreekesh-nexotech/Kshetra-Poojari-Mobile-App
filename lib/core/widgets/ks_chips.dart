import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';

/// Cream coin with a maroon ₹ — the *only* incentive marker in the app
/// ("just show the rupee icon"). Sizes: 18 on cards/home, 16 in the tally.
class KsIncentiveCoin extends StatelessWidget {
  const KsIncentiveCoin({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        shape: BoxShape.circle,
      ),
      child: Text(
        '₹',
        style: AppText.latin(
          size: size * 0.66,
          weight: FontWeight.w700,
          color: AppColors.maroon,
        ),
      ),
    );
  }
}

/// Rounded status pill (റീ-അസൈൻഡ്, സ്പെഷ്യൽ). Foreground/background per use.
class KsPill extends StatelessWidget {
  const KsPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.fontSize = 11,
  });

  final String label;
  final Color background;
  final Color foreground;
  final double fontSize;

  /// Maroon fill, white text — reassigned marker.
  factory KsPill.reassigned(String label) => KsPill(
    label: label,
    background: AppColors.maroon,
    foreground: AppColors.white,
  );

  /// Cream fill, maroon text — special-pooja marker.
  factory KsPill.special(String label) => KsPill(
    label: label,
    background: AppColors.cream,
    foreground: AppColors.maroon,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        label,
        style: AppText.malayalam(size: fontSize, color: foreground),
      ),
    );
  }
}

/// White count pill with a hairline — the group-header task count on the
/// pooja list (`03`).
class KsCountPill extends StatelessWidget {
  const KsCountPill({super.key, required this.count});

  final String count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Text(
        count,
        style: AppText.latin(
          size: 12,
          weight: FontWeight.w700,
          color: AppColors.maroon,
        ),
      ),
    );
  }
}
