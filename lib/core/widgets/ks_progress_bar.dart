import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';

/// Amber-on-grey progress bar used on the home overall card (8px) and the
/// per-deity rows (5px). Radius defaults to a full pill (height / 2).
class KsProgressBar extends StatelessWidget {
  const KsProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.fill = AppColors.amber,
    this.track = AppColors.track,
    this.radius,
  });

  /// Completion fraction, clamped to 0..1.
  final double value;

  /// Bar thickness in design px.
  final double height;
  final Color fill;
  final Color track;

  /// Corner radius in design px; defaults to a full pill.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = (radius ?? height / 2).r;
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: Container(
        height: height.h,
        color: track,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(r),
            ),
          ),
        ),
      ),
    );
  }
}
