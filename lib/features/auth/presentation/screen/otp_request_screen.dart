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
import '../../application/states/auth_state.dart';
import '../components/auth_scaffold.dart';

/// Enter the registered number to receive an OTP (for OTP login or reset).
class OtpRequestScreen extends ConsumerStatefulWidget {
  const OtpRequestScreen({super.key});

  @override
  ConsumerState<OtpRequestScreen> createState() => _OtpRequestScreenState();
}

class _OtpRequestScreenState extends ConsumerState<OtpRequestScreen> {
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    // Prefilled from the login field, but only when that held a number — an
    // OTP goes out by SMS, so a username carried over would be dead text.
    _phone = TextEditingController(
      text: ref.read(authControllerProvider).phonePrefill,
    );
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _run(AuthOutcome outcome) {
    // sendOtp is async, so this can land after the screen is gone.
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
                  auth.otpHeading,
                  textAlign: TextAlign.center,
                  style: AppText.malayalam(
                    size: 22,
                    weight: FontWeight.w700,
                    color: AppColors.maroon,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  auth.otpHelper,
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
              label: 'ഫോൺ നമ്പർ',
              controller: _phone,
              onChanged: controller.setIdentifier,
              useLatinFont: true,
              keyboardType: TextInputType.phone,
              prefixText: kIndiaCallingCode,
            ),
            if (auth.identifierError != null) ...[
              SizedBox(height: 10.h),
              AuthErrorText(auth.identifierError!),
            ],
            SizedBox(height: 18.h),
            AppButton(
              label: auth.busy ? 'അയയ്ക്കുന്നു…' : 'ഒ.ടി.പി അയയ്ക്കുക',
              glow: true,
              expanded: true,
              onTap: auth.busy
                  ? () {}
                  : () async => _run(await controller.sendOtp()),
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
