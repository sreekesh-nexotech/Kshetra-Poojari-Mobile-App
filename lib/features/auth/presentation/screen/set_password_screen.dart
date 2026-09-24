import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../application/providers/auth_controller.dart';
import '../components/auth_scaffold.dart';

/// Set a new password after first login / reset.
class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final TextEditingController _pw1 = TextEditingController();
  final TextEditingController _pw2 = TextEditingController();

  @override
  void dispose() {
    _pw1.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController controller) async {
    final o = await controller.submitNewPassword();
    // submitNewPassword is async, so this can land after the screen is gone.
    if (!mounted) return;
    if (o.navigate != null) {
      context.go(AppRoutes.forAuthDestination(o.navigate!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    return AuthScaffold(
      top: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Text(
                'പുതിയ പാസ്‌വേഡ്',
                style: AppText.malayalam(
                  size: 22,
                  weight: FontWeight.w700,
                  color: AppColors.maroon,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'ആദ്യ ലോഗിൻ / റീസെറ്റിന് ശേഷം പുതിയ പാസ്‌വേഡ് സെറ്റ് ചെയ്യുക.',
                textAlign: TextAlign.center,
                style: AppText.malayalam(
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppColors.black,
                  height: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          AppTextField(
            label: 'പുതിയ പാസ്‌വേഡ്',
            controller: _pw1,
            onChanged: controller.setNewPassword,
            obscureText: true,
          ),
          SizedBox(height: 18.h),
          AppTextField(
            label: 'പാസ്‌വേഡ് കൺഫേം ചെയ്യുക',
            controller: _pw2,
            onChanged: controller.setConfirmPassword,
            obscureText: true,
          ),
          if (auth.passwordError != null) ...[
            SizedBox(height: 10.h),
            AuthErrorText(auth.passwordError!),
          ],
          SizedBox(height: 18.h),
          AppButton(
            label: auth.busy ? 'സെറ്റ് ചെയ്യുന്നു…' : 'പാസ്‌വേഡ് സെറ്റ് ചെയ്യുക',
            glow: true,
            expanded: true,
            onTap: auth.busy ? () {} : () async => _submit(controller),
          ),
        ],
      ),
    );
  }
}
