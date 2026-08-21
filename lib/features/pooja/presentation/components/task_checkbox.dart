import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';

/// The 22px to-do checkbox used on task rows and group headers.
/// [filled] = maroon fill + maroon border; otherwise white + gray border.
/// [mark] is "✓", "–" (partial) or "" (empty).
class TaskCheckbox extends StatelessWidget {
  const TaskCheckbox({super.key, required this.mark, required this.filled});

  final String mark;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22.w,
      height: 22.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? AppColors.maroon : AppColors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: filled ? AppColors.maroon : AppColors.grayInactive,
          width: 2,
        ),
      ),
      child: Text(
        mark,
        style: AppText.malayalam(
          size: 12,
          weight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// A filled status tile for done (✓ maroon) / cancelled (✕ gray) rows.
class TaskStatusTile extends StatelessWidget {
  const TaskStatusTile({super.key, required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22.w,
      height: 22.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done ? AppColors.maroon : AppColors.track,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        done ? '✓' : '✕',
        style: AppText.malayalam(
          size: 12,
          weight: FontWeight.w700,
          color: done ? AppColors.white : AppColors.grayText,
        ),
      ),
    );
  }
}
