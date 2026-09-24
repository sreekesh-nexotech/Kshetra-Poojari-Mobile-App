import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/ks_temple_background.dart';
import '../../../pooja/application/providers/pooja_data_providers.dart';
import '../../../pooja/application/providers/pooja_list_controller.dart';
import '../../application/providers/home_providers.dart';
import '../components/attendance_card.dart';
import '../components/home_greeting_card.dart';
import '../components/overall_progress_card.dart';
import '../components/today_tally_table.dart';
import '../components/upcoming_days_row.dart';

/// Home tab — today's overview: greeting, attendance, progress, tally, upcoming.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Same trigger as the pooja tab's own `initState` — so the progress card
    // and tally have real numbers the moment Home opens, not only once the
    // poojari has visited the pooja tab at least once. `ensureLoaded` no-ops
    // when a fixture (or the pooja tab) already supplied data.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final categoryId = ref.read(effectiveCategoryIdProvider);
      ref.read(poojaFeedControllerProvider.notifier).ensureLoaded(categoryId);
      ref.read(dashboardFeedControllerProvider.notifier).ensureLoaded();
    });
  }

  Future<void> _refresh() => Future.wait([
    ref.read(dashboardFeedControllerProvider.notifier).refresh(),
    ref
        .read(poojaFeedControllerProvider.notifier)
        .refresh(ref.read(effectiveCategoryIdProvider)),
  ]);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const KsTempleBackground(flipped: true),
        SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.maroon,
            child: SingleChildScrollView(
              // AlwaysScrollable so pull-to-refresh works even when the
              // content is shorter than the viewport.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 36.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HomeGreetingCard(),
                  SizedBox(height: 12.h),
                  const AttendanceCard(),
                  SizedBox(height: 12.h),
                  const OverallProgressCard(),
                  SizedBox(height: 12.h),
                  const TodayTallyTable(),
                  SizedBox(height: 12.h),
                  const UpcomingDaysRow(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
