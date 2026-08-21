import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme.dart';

/// One bottom-nav destination.
class KsNavItem {
  const KsNavItem({required this.asset, required this.semanticLabel});
  final String asset;
  final String semanticLabel;
}

/// The design's bottom navigation bar (cream, 82px) rebuilt from the
/// `NavbarVariant9/10/11` components. Glyphs are the exact SVG paths extracted
/// from the design system (`assets/icons/nav_*.svg`), tinted via `currentColor`
/// — rose when idle, maroon inside a translucent white pill when selected.
class KsBottomNav extends StatelessWidget {
  const KsBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<KsNavItem> items = [
    KsNavItem(asset: 'assets/icons/nav_home.svg', semanticLabel: 'Home'),
    KsNavItem(asset: 'assets/icons/nav_pooja.svg', semanticLabel: 'Pooja'),
    KsNavItem(asset: 'assets/icons/nav_user.svg', semanticLabel: 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimens.navbarH.h,
      decoration: BoxDecoration(
        color: AppColors.cream,
        boxShadow: AppShadows.nav(),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < items.length; i++)
            _NavCell(
              item: items[i],
              selected: i == currentIndex,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  const _NavCell({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final KsNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glyph = SvgPicture.asset(
      item.asset,
      width: selected ? 20.w : 24.w,
      height: selected ? 20.w : 24.w,
      colorFilter: ColorFilter.mode(
        selected ? AppColors.maroon : AppColors.rose,
        BlendMode.srcIn,
      ),
      semanticsLabel: item.semanticLabel,
    );

    final Widget content = selected
        ? Container(
            width: 63.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.navTileGlass,
              borderRadius: BorderRadius.circular(AppRadii.input.r),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.maroon.withValues(alpha: 0.16),
                  offset: Offset(8.w, 8.h),
                  blurRadius: 16.r,
                ),
              ],
            ),
            child: glyph,
          )
        : SizedBox(width: 50.w, child: Center(child: glyph));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: double.infinity,
        child: Center(child: content),
      ),
    );
  }
}
