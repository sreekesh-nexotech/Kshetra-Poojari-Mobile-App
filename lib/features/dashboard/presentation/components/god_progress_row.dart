import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/ks_chevron.dart';
import '../../../../core/widgets/ks_progress_bar.dart';
import '../../application/models/home_view_models.dart';

/// A per-deity progress row inside the home combined card.
class GodProgressRow extends StatelessWidget {
  const GodProgressRow({super.key, required this.god, required this.onTap});

  final GodCardVm god;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Image.asset(god.imageAsset, fit: BoxFit.cover),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  god.name,
                  style: AppText.malayalam(
                    size: 15,
                    weight: FontWeight.w700,
                    color: AppColors.maroon,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 6.h),
                KsProgressBar(value: god.progress, height: 5),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            god.fracLabel,
            style: AppText.latin(
              size: 13,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          SizedBox(width: 8.w),
          const KsChevron(angleDeg: 45),
        ],
      ),
    );
  }
}
