import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../dashboard/application/providers/attendance_controller.dart';
import '../../application/models/profile_models.dart';
import '../../application/providers/profile_providers.dart';

/// The week attendance dot strip with the live status line.
class WeekStrip extends ConsumerWidget {
  const WeekStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(weekStripProvider);
    final att = ref.watch(attendanceControllerProvider);

    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ഹാജർ — ഈ ആഴ്ച',
                style: AppText.malayalam(
                  size: 15,
                  weight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                att.statusLabel,
                style: AppText.malayalam(
                  size: 12,
                  weight: FontWeight.w600,
                  color: att.started ? AppColors.maroon : AppColors.grayText,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [for (final d in days) Expanded(child: _DayDot(day: d))],
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.day});

  final WeekDay day;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color? ring) = switch (day.kind) {
      WeekDayKind.present => (
        AppColors.cream,
        AppColors.maroon,
        AppColors.maroon,
      ),
      WeekDayKind.absent => (AppColors.white, AppColors.rose, AppColors.rose),
      WeekDayKind.today => (AppColors.maroon, AppColors.white, null),
    };
    final labelColor = day.kind == WeekDayKind.today
        ? AppColors.maroon
        : AppColors.grayText;

    return Column(
      children: [
        Container(
          width: 26.w,
          height: 26.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: ring == null ? null : Border.all(color: ring, width: 1),
          ),
          child: Text(
            day.mark,
            style: AppText.malayalam(
              size: 11,
              weight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(day.label, style: AppText.malayalam(size: 11, color: labelColor)),
      ],
    );
  }
}
