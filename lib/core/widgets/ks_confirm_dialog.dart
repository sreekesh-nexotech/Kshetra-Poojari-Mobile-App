import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/typography.dart';

/// A yes/no confirmation popup — same 300px card + scrim shell as
/// [showKsBlockDialog], but with a "back out" text button alongside the
/// maroon confirm button instead of a single acknowledge.
///
/// Returns `true` only when the confirm button was tapped; dismissing the
/// dialog any other way (back gesture, tapping the scrim) reads as `false`.
Future<bool> showKsConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'ബാക്ക്',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(24.w),
      child: Container(
        width: 300.w,
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.card.r),
          boxShadow: AppShadows.poster(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppText.malayalam(
                size: 18,
                weight: FontWeight.w700,
                color: AppColors.maroon,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              style: AppText.malayalam(size: 14, color: AppColors.ink, height: 1.5),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(false),
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Text(
                      cancelLabel,
                      style: AppText.malayalam(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.maroon,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    height: AppDimens.controlH.h,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.maroon,
                      borderRadius: BorderRadius.circular(AppRadii.input.r),
                    ),
                    child: Text(
                      confirmLabel,
                      style: AppText.malayalam(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.offWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return confirmed ?? false;
}
