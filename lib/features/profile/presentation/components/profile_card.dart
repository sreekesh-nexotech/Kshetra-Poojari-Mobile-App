import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../application/providers/profile_providers.dart';

/// The account profile card: avatar, name, phone·ID, assigned deities.
class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poojari = ref.watch(poojariProvider);
    final assignedGodsLabel = ref.watch(assignedGodsLabelProvider);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.glass85,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.maroon,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  poojari.initial,
                  style: AppText.latin(
                    size: 18,
                    weight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poojari.name,
                    style: AppText.latin(
                      size: 17,
                      weight: FontWeight.w700,
                      color: AppColors.maroon,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    poojari.poojariId == null
                        ? poojari.phone
                        : '${poojari.phone} · ID ${poojari.poojariId}',
                    style: AppText.latin(size: 12, color: AppColors.grayText),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(height: 1, color: AppColors.track),
          SizedBox(height: 12.h),
          Text(
            'അസൈൻ ചെയ്ത ദേവതകൾ',
            style: AppText.malayalam(size: 12, color: AppColors.grayText),
          ),
          SizedBox(height: 4.h),
          Text(
            assignedGodsLabel,
            style: AppText.malayalam(
              size: 15,
              weight: FontWeight.w600,
              color: AppColors.maroon,
            ),
          ),
        ],
      ),
    );
  }
}
