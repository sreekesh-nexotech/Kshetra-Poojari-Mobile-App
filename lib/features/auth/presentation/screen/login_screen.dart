import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/ks_toast.dart';
import '../../application/providers/auth_controller.dart';
import '../components/auth_scaffold.dart';

/// Phone + password login, with links to OTP login and password reset.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _phone;
  final TextEditingController _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(
      text: ref.read(authControllerProvider).phone,
    );
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _run(AuthOutcome outcome) {
    // Sign-in is async, so this can land after the screen is gone.
    if (!mounted) return;
    if (outcome.toast != null) {
      ref.read(toastProvider.notifier).show(outcome.toast!);
    }
    if (outcome.navigate != null) {
      context.go(AppRoutes.forAuthDestination(outcome.navigate!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    return AuthScaffold(
      top: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Text(
                'ലോഗിൻ',
                style: AppText.malayalam(
                  size: 22,
                  weight: FontWeight.w700,
                  color: AppColors.maroon,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'വീണ്ടും സ്വാഗതം!',
                style: AppText.malayalam(
                  size: 15,
                  weight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          AppTextField(
            label: 'ഫോൺ നമ്പർ',
            controller: _phone,
            onChanged: controller.setPhone,
            useLatinFont: true,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 18.h),
          AppTextField(
            label: 'പാസ്‌വേഡ്',
            controller: _password,
            onChanged: controller.setPassword,
            obscureText: true,
            hintText: '••••••',
          ),
          if (auth.phoneError != null) ...[
            SizedBox(height: 10.h),
            AuthErrorText(auth.phoneError!),
          ],
          SizedBox(height: 12.h),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _run(controller.startReset()),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'പാസ്‌വേഡ് മറന്നോ?',
                style: AppText.malayalam(
                  size: 14,
                  weight: FontWeight.w600,
                  color: AppColors.maroon80,
                ),
              ),
            ),
          ),
          SizedBox(height: 18.h),
          AppButton(
            label: auth.busy ? 'ലോഗിൻ ചെയ്യുന്നു…' : 'ലോഗിൻ',
            glow: true,
            expanded: true,
            onTap: auth.busy
                ? () {}
                : () async => _run(await controller.login()),
          ),
          SizedBox(height: 18.h),
          AppButton(
            label: 'ഒ.ടി.പി വഴി ലോഗിൻ',
            variant: AppButtonVariant.secondary,
            fontSize: 14,
            expanded: true,
            onTap: () => _run(controller.startOtpLogin()),
          ),
        ],
      ),
    );
  }
}
