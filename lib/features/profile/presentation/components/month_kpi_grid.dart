import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../application/models/profile_models.dart';
import '../../application/providers/profile_providers.dart';

/// 2×2 grid of this-month KPI tiles.
class MonthKpiGrid extends ConsumerWidget {
  const MonthKpiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(monthKpisProvider);

    return Column(
      children: [
        for (var r = 0; r < kpis.length; r += 2) ...[
          if (r > 0) SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(child: _KpiTile(kpi: kpis[r])),
              if (r + 1 < kpis.length) ...[
                SizedBox(width: 8.w),
                Expanded(child: _KpiTile(kpi: kpis[r + 1])),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.kpi});

  final MonthKpi kpi;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kpi.value,
            style: AppText.stat(
              size: 22,
              weight: FontWeight.w600,
              color: kpi.accent ? AppColors.maroon : AppColors.navy,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            kpi.label,
            style: AppText.malayalam(size: 12, color: AppColors.grayText),
          ),
        ],
      ),
    );
  }
}
