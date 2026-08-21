import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';

/// The thin two-stroke caret used throughout the design (an 8×8 box with a
/// top + right border, rotated). Matches the CSS `border-top/right + rotate`
/// chevrons rather than a filled Material icon.
///
/// Angle guide: 45° → ›(right), 135° → ⌄(down), -45° → ˄(up), 225° → ‹(left).
class KsChevron extends StatelessWidget {
  const KsChevron({
    super.key,
    this.size = 8,
    this.color = AppColors.maroon,
    this.angleDeg = 45,
    this.thickness = 2,
  });

  final double size;
  final Color color;
  final double angleDeg;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angleDeg * math.pi / 180,
      child: Container(
        width: size.w,
        height: size.w,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: color, width: thickness),
            right: BorderSide(color: color, width: thickness),
          ),
        ),
      ),
    );
  }
}
