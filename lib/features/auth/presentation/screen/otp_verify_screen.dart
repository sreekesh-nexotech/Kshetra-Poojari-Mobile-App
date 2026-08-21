import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Enter the 4-digit OTP to log in or continue a password reset.
class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final TextEditingController _otp = TextEditingController();

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  void _run(AuthOutcome outcome) {
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
      top: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Text(
                'ഒ.ടി.പി നൽകുക',
                style: AppText.malayalam(
                  size: 22,
                  weight: FontWeight.w700,
                  color: AppColors.maroon,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'നിങ്ങളുടെ നമ്പറിലേക്ക് ഒ.ടി.പി അയച്ചിട്ടുണ്ട്. (ഡെമോ: 1234)',
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
            controller: _otp,
            onChanged: controller.setOtp,
            useLatinFont: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            height: 48,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 12,
            maxLength: 4,
            hintText: '––––',
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
          ),
          if (auth.otpError != null) ...[
            SizedBox(height: 10.h),
            AuthErrorText(auth.otpError!),
          ],
          SizedBox(height: 18.h),
          AppButton(
            label: 'വെരിഫൈ ചെയ്യുക',
            glow: true,
            expanded: true,
            onTap: () => _run(controller.verifyOtp()),
          ),
          SizedBox(height: 18.h),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _otp.clear();
              _run(controller.resendOtp());
            },
            child: Text(
              'ഒ.ടി.പി വീണ്ടും അയയ്ക്കുക',
              textAlign: TextAlign.center,
              style: AppText.malayalam(
                size: 14,
                color: AppColors.rose,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          SizedBox(height: 18.h),
          AppButton(
            label: 'ബാക്ക് — ലോഗിൻ',
            variant: AppButtonVariant.secondary,
            fontSize: 14,
            expanded: true,
            onTap: () => _run(controller.backToLogin()),
          ),
        ],
      ),
    );
  }
}
