import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../../../../core/widgets/ks_section_label.dart';
import '../../../../core/widgets/ks_temple_background.dart';
import '../../../auth/application/providers/auth_controller.dart';
import '../../../auth/application/providers/session_controller.dart';
import '../../application/providers/profile_providers.dart';
import '../components/month_kpi_grid.dart';
import '../components/profile_card.dart';
import '../components/week_strip.dart';

/// Account tab — profile + this-month / till-now review, and logout.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  @override
  void initState() {
    super.initState();
    // Same trigger as the home/pooja tabs' own `initState` — `ensureLoaded`
    // no-ops when a fixture already supplied data.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(profileFeedControllerProvider.notifier).ensureLoaded();
    });
  }

  Future<void> _refresh() =>
      ref.read(profileFeedControllerProvider.notifier).refresh();

  Future<void> _logout(WidgetRef ref) async {
    final confirmed = await showKsConfirmDialog(
      context,
      title: 'ലോഗൗട്ട് ചെയ്യണോ?',
      message: 'നിങ്ങൾ ഈ അക്കൗണ്ടിൽ നിന്ന് പുറത്തുപോകും.',
      confirmLabel: 'ലോഗൗട്ട്',
    );
    if (!confirmed || !mounted) return;

    ref.read(authControllerProvider.notifier).resetForLogout();
    // Ends the server session — which also clears the stored FCM token, so
    // push stops for this device — and empties the cookie jar. The router's
    // redirect handles the navigation, so there is no context.go here.
    await ref.read(sessionControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = ref.watch(monthLabelProvider);

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
              padding: EdgeInsets.fromLTRB(16.w, 44.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'അക്കൗണ്ട്',
                    style: AppText.malayalam(
                      size: 22,
                      weight: FontWeight.w700,
                      color: AppColors.maroon,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  const ProfileCard(),
                  SizedBox(height: 12.h),
                  SizedBox(height: 4.h),
                  KsSectionLabel(monthLabel),
                  SizedBox(height: 12.h),
                  const MonthKpiGrid(),
                  SizedBox(height: 12.h),
                  const WeekStrip(),
                  SizedBox(height: 12.h),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _logout(ref),
                    child: Container(
                      height: 40.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.maroon,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'ലോഗൗട്ട്',
                        style: AppText.malayalam(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.offWhite,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
