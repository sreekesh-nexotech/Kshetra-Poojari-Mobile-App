import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/ks_section_label.dart';
import '../../application/models/home_view_models.dart';
import '../../application/providers/home_providers.dart';

/// The next-3-days count tiles.
class UpcomingDaysRow extends ConsumerWidget {
  const UpcomingDaysRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(upcomingDaysProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 4.h),
        const KsSectionLabel('വരും ദിവസങ്ങൾ'),
        SizedBox(height: 12.h),
        Row(
          children: [
            for (var i = 0; i < days.length; i++) ...[
              if (i > 0) SizedBox(width: 8.w),
              Expanded(child: _UpcomingTile(day: days[i])),
            ],
          ],
        ),
      ],
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.day});

  final UpcomingDay day;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 8,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      child: Column(
        children: [
          Text(
            day.label,
            style: day.latinLabel
                ? AppText.latin(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.maroon,
                  )
                : AppText.malayalam(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.maroon,
                  ),
          ),
          SizedBox(height: 2.h),
          Text(
            '${day.count}',
            style: AppText.stat(
              size: 20,
              weight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'പൂജകൾ',
            style: AppText.malayalam(size: 12, color: AppColors.grayText),
          ),
        ],
      ),
    );
  }
}
