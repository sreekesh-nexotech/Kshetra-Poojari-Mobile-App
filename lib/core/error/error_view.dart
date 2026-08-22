import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/typography.dart';
import '../widgets/app_button.dart';

/// The retry card shown in place of a list that could not load.
///
/// Deliberately shaped like the screen's own empty state (a translucent white
/// panel over the temple background) so a failed load does not look like a
/// different app.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.padding,
  });

  final String message;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding ?? EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      children: [
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 28.h),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.malayalam(
                  size: 14,
                  color: AppColors.grayText,
                  height: 1.45,
                ),
              ),
              if (onRetry != null) ...[
                SizedBox(height: 16.h),
                AppButton(
                  label: 'വീണ്ടും ശ്രമിക്കുക',
                  radius: AppRadii.input,
                  fontSize: 14,
                  width: 160.w,
                  onTap: onRetry!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
