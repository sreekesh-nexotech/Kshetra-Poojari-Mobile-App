import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/ks_chips.dart';
import '../../../../core/widgets/ks_section_label.dart';
import '../../application/models/home_view_models.dart';
import '../../application/providers/home_providers.dart';

/// The home "to-do / today's summary" tally table.
class TodayTallyTable extends ConsumerWidget {
  const TodayTallyTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tally = ref.watch(homeTallyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 4.h),
        KsSectionLabel(tally.title),
        SizedBox(height: 12.h),
        AppCard(
          clip: true,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Header
              Container(
                color: AppColors.creamInput,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('പൂജ', style: _headStyle),
                    Text('എണ്ണം', style: _headStyle),
                  ],
                ),
              ),
              for (final row in tally.rows) _TallyRow(row: row),
              if (tally.noteOn)
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.track)),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ചെയ്യാത്തവ',
                        style: AppText.malayalam(
                          size: 13,
                          color: AppColors.grayText,
                        ),
                      ),
                      Text(
                        tally.note,
                        style: AppText.latin(
                          size: 13,
                          weight: FontWeight.w700,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
              // Total
              Container(
                color: AppColors.cream,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tally.totalLabel,
                      style: AppText.malayalam(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.maroon,
                      ),
                    ),
                    Text(
                      tally.total,
                      style: AppText.latin(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.maroon,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle get _headStyle => AppText.malayalam(
    size: 12,
    weight: FontWeight.w700,
    color: AppColors.brown,
  );
}

class _TallyRow extends StatelessWidget {
  const _TallyRow({required this.row});

  final TallyRowVm row;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.track)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.malayalam(
                      size: 14,
                      weight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.35,
                    ),
                  ),
                ),
                if (row.reassigned) ...[
                  SizedBox(width: 8.w),
                  KsPill.reassigned('റീ-അസൈൻഡ്'),
                ],
                if (row.incentive) ...[
                  SizedBox(width: 8.w),
                  const KsIncentiveCoin(size: 16),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            row.count,
            style: AppText.latin(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.maroon,
            ),
          ),
        ],
      ),
    );
  }
}
