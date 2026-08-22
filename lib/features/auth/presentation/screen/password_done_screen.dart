import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../application/providers/auth_controller.dart';
import '../components/auth_scaffold.dart';

/// Confirmation that the password was changed.
class PasswordDoneScreen extends ConsumerWidget {
  const PasswordDoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(authControllerProvider.notifier);

    return AuthScaffold(
      top: 250,
      background: AppColors.glass60,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56.w,
              height: 56.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.maroon, width: 2),
              ),
              child: Text(
                '✓',
                style: AppText.malayalam(size: 24, color: AppColors.maroon),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'പാസ്‌വേഡ് മാറ്റി',
            textAlign: TextAlign.center,
            style: AppText.malayalam(
              size: 22,
              weight: FontWeight.w700,
              color: AppColors.maroon,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'പുതിയ പാസ്‌വേഡ് ഉപയോഗിച്ച് ലോഗിൻ ചെയ്യുക.',
            textAlign: TextAlign.center,
            style: AppText.malayalam(size: 14, color: AppColors.black),
          ),
          SizedBox(height: 16.h),
          AppButton(
            label: 'ലോഗിൻ',
            glow: true,
            expanded: true,
            onTap: () {
              final o = controller.backToLogin();
              if (o.navigate != null) {
                context.go(AppRoutes.forAuthDestination(o.navigate!));
              }
            },
          ),
        ],
      ),
    );
  }
}
