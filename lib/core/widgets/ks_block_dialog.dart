import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/typography.dart';

/// The design's blocking popup (location-off / outside-premises / not-checked-in
/// gates). A 300px white card over a 45%-black scrim with a single maroon
/// "ശരി" acknowledge button.
///
/// The [title]/[message] copy is supplied by the caller (the attendance gate
/// owns the exact Malayalam strings), keeping this shell reusable.
Future<void> showKsBlockDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(24.w),
      child: Container(
        width: 300.w,
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
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
              style: AppText.malayalam(
                size: 14,
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16.h),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: AppDimens.controlH.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.maroon,
                  borderRadius: BorderRadius.circular(AppRadii.input.r),
                ),
                child: Text(
                  'ശരി',
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
      ),
    ),
  );
}
