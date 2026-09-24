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

/// Enter the 6-digit OTP to log in or continue a password reset.
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
    // verifyOtp/resendOtp are async, so this can land after the screen is gone.
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

    // System back mirrors the "ബാക്ക് — ലോഗിൻ" button below rather than
    // exiting the app — this screen sits outside the tab shell with no route
    // beneath it, so an unhandled back would otherwise close the app mid-flow.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _run(controller.backToLogin());
      },
      child: AuthScaffold(
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
                  'നിങ്ങളുടെ നമ്പറിലേക്ക് ഒ.ടി.പി അയച്ചിട്ടുണ്ട്.',
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
              letterSpacing: 8,
              maxLength: 6,
              hintText: '––––––',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            if (auth.otpError != null) ...[
              SizedBox(height: 10.h),
              AuthErrorText(auth.otpError!),
            ],
            SizedBox(height: 18.h),
            AppButton(
              label: auth.busy ? 'വെരിഫൈ ചെയ്യുന്നു…' : 'വെരിഫൈ ചെയ്യുക',
              glow: true,
              expanded: true,
              onTap: auth.busy
                  ? () {}
                  : () async => _run(await controller.verifyOtp()),
            ),
            SizedBox(height: 18.h),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: auth.busy
                  ? null
                  : () async {
                      _otp.clear();
                      _run(await controller.resendOtp());
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
      ),
    );
  }
}
