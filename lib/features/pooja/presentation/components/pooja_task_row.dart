import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/ks_chips.dart';
import '../../application/models/pooja_view_models.dart';
import 'task_checkbox.dart';

/// One task row: person + nakshatra + optional remark, with a leading
/// checkbox / status tile and trailing pills / undo.
class PoojaTaskRow extends StatelessWidget {
  const PoojaTaskRow({
    super.key,
    required this.row,
    required this.onTap,
    required this.onUndo,
  });

  final PoojaRowVm row;
  final VoidCallback onTap;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: row.isPending ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: row.selected ? AppColors.creamInput : Colors.transparent,
          border: const Border(top: BorderSide(color: AppColors.track)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (row.isPending)
              TaskCheckbox(mark: row.selected ? '✓' : '', filled: row.selected)
            else
              TaskStatusTile(done: row.isDone),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.person,
                    style: AppText.latin(
                      size: 15,
                      weight: FontWeight.w600,
                      color: row.isCancelled
                          ? AppColors.grayText
                          : AppColors.ink,
                      height: 1.35,
                    ),
                  ),
                  if (row.hasRemark) ...[
                    SizedBox(height: 3.h),
                    Text(
                      '— ${row.remark}',
                      style: AppText.malayalam(
                        size: 12,
                        color: AppColors.grayText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  row.nakshatra,
                  style: AppText.malayalam(size: 12, color: AppColors.grayText),
                ),
                if (row.reassignedPill) ...[
                  SizedBox(height: 4.h),
                  KsPill.reassigned('റീ-അസൈൻഡ്'),
                ],
                if (row.isDone) ...[
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        row.timeLabel ?? '',
                        style: AppText.latin(
                          size: 11,
                          color: AppColors.grayText,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onUndo,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.maroon,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'അൺഡു',
                            style: AppText.malayalam(
                              size: 11,
                              weight: FontWeight.w700,
                              color: AppColors.maroon,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (row.isCancelled) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'റീ-അസൈൻ ചെയ്യും',
                    style: AppText.malayalam(size: 11, color: AppColors.rose),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
