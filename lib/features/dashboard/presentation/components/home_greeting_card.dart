import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../profile/application/providers/profile_providers.dart';
import '../../application/mock/home_mock_data.dart';
import '../../application/providers/home_providers.dart';

/// Frosted greeting card: namaskaram + poojari name + both calendars.
class HomeGreetingCard extends ConsumerWidget {
  const HomeGreetingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(poojariProvider).name;
    final malayalamDate = ref.watch(malayalamDateProvider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glass50,
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                HomeMockData.greeting,
                style: AppText.malayalam(size: 14, color: AppColors.maroon),
              ),
              Text(
                name,
                style: AppText.latin(
                  size: 20,
                  weight: FontWeight.w700,
                  color: AppColors.maroon,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    // Mixed Malayalam + digits → Malayalam face (Roboto lacks
                    // the Malayalam glyphs and would render tofu).
                    malayalamDate,
                    style: AppText.malayalam(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.maroon,
                    ),
                  ),
                  Text(
                    AppTime.gregorianLabel(),
                    style: AppText.latin(size: 12, color: AppColors.maroon),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
