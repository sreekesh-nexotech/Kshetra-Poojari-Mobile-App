import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../application/providers/pooja_list_controller.dart';
import '../../application/states/pooja_list_state.dart';

/// Horizontally-scrolling status filter chips with per-tab counts. A right-edge
/// fade + the padding make the scrollability obvious.
class StatusFilterChips extends ConsumerWidget {
  const StatusFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(
      poojaListControllerProvider.select((s) => s.activeTab),
    );
    final counts = ref.watch(poojaTabCountsProvider);

    return SizedBox(
      height: 36.h,
      child: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: 17.w, right: 44.w),
            child: Row(
              children: [
                for (var i = 0; i < kPoojaCategories.length; i++) ...[
                  if (i > 0) SizedBox(width: 8.w),
                  _Chip(
                    label: kPoojaCategories[i],
                    count: counts[i],
                    selected: i == activeTab,
                    onTap: () => ref
                        .read(poojaListControllerProvider.notifier)
                        .selectTab(i),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: 40.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.white.withValues(alpha: 0),
                      AppColors.white.withValues(alpha: 0.85),
                    ],
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Container(
          height: 32.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: selected ? AppColors.maroon : AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: selected ? AppColors.maroon : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: AppText.malayalam(
                  size: 13,
                  weight: FontWeight.w600,
                  color: selected ? AppColors.white : AppColors.ink,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.white.withValues(alpha: 0.22)
                      : AppColors.creamInput,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  count,
                  style: AppText.latin(
                    size: 11,
                    weight: FontWeight.w700,
                    color: selected ? AppColors.white : AppColors.maroon,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
