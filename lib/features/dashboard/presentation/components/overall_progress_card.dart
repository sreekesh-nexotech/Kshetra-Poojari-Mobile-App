import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/device/location_gate.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/ks_block_dialog.dart';
import '../../../../core/widgets/ks_chips.dart';
import '../../../../core/widgets/ks_progress_bar.dart';
import '../../../pooja/application/providers/pooja_list_controller.dart';
import '../../application/providers/attendance_controller.dart';
import '../../application/providers/home_providers.dart';
import 'god_progress_row.dart';

/// The home combined card: overall %, incentive line, and per-deity rows.
class OverallProgressCard extends ConsumerWidget {
  const OverallProgressCard({super.key});

  void _openGod(BuildContext context, WidgetRef ref, int godId) {
    if (!ref.read(isCheckedInProvider)) {
      showKsBlockDialog(
        context,
        title: GateCopy.notCheckedInTitle,
        message: GateCopy.notCheckedInMessage,
      );
      return;
    }
    ref.read(poojaListControllerProvider.notifier).selectGod(godId);
    context.go(AppRoutes.pooja);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(homeProgressProvider);
    final gods = ref.watch(godCardsProvider);

    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ഇന്നത്തെ പൂജകൾ',
                  style: AppText.malayalam(
                    size: 16,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                'ബാക്കി ${progress.pendingLabel}',
                style: AppText.malayalam(
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppColors.grayMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  '${progress.percentInt}%',
                  style: AppText.stat(
                    size: 24,
                    weight: FontWeight.w600,
                    color: AppColors.navy,
                    height: 1.2,
                  ),
                ),
              ),
              Text(
                progress.fracLabel,
                style: AppText.stat(
                  size: 14,
                  weight: FontWeight.w500,
                  color: AppColors.grayMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          KsProgressBar(value: progress.progress, height: 8),
          SizedBox(height: 12.h),
          Row(
            children: [
              const KsIncentiveCoin(size: 18),
              SizedBox(width: 6.w),
              Text(
                'ഇൻസെന്റീവ് — ചെയ്തത് ${progress.incentiveFracLabel}',
                style: AppText.malayalam(
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppColors.grayMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(height: 1, color: AppColors.track),
          for (final g in gods) ...[
            SizedBox(height: 12.h),
            GodProgressRow(god: g, onTap: () => _openGod(context, ref, g.id)),
          ],
        ],
      ),
    );
  }
}
