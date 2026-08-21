import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme.dart';

/// The design's surface primitive: a rounded white card that is either
/// **elevated** (warm down-right shadow) or **outlined** (1px inset hairline).
///
/// Maps the two card treatments called out in the design system
/// ("white, hairline-inset OR warm shadow — list vs feature").
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.elevated = false,
    this.color = AppColors.white,
    this.radius = AppRadii.card,
    this.padding,
    this.border,
    this.clip = false,
    this.width,
  });

  /// Card contents.
  final Widget child;

  /// `true` → warm [AppShadows.card]; `false` → 1px hairline border.
  final bool elevated;

  final Color color;

  /// Corner radius in design px (scaled via `.r`).
  final double radius;

  final EdgeInsetsGeometry? padding;

  /// Overrides the default hairline border when not [elevated].
  final BoxBorder? border;

  /// Clip children to the rounded rect (used by the tally table / lists).
  final bool clip;

  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius.r),
        boxShadow: elevated ? AppShadows.card() : null,
        border: elevated ? null : (border ?? AppShadows.hairline()),
      ),
      child: child,
    );
  }
}
