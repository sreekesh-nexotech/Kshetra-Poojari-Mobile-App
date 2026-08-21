import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kshetra_poojari/core/widgets/navbar.dart';
import 'package:kshetra_poojari/features/auth/presentation/screen/login_screen.dart';
import 'package:kshetra_poojari/features/auth/presentation/screen/otp_request_screen.dart';
import 'package:kshetra_poojari/features/auth/presentation/screen/otp_verify_screen.dart';
import 'package:kshetra_poojari/features/auth/presentation/screen/password_done_screen.dart';
import 'package:kshetra_poojari/features/auth/presentation/screen/set_password_screen.dart';
import 'package:kshetra_poojari/features/dashboard/application/providers/attendance_controller.dart';
import 'package:kshetra_poojari/features/dashboard/presentation/screen/home_screen.dart';
import 'package:kshetra_poojari/features/pooja/presentation/screen/pooja_list_screen.dart';
import 'package:kshetra_poojari/features/profile/presentation/screen/account_screen.dart';

import '../support/pump_screen.dart';

/// Wraps a tab screen with the bottom navbar so the golden matches the design
/// frame (content + navbar).
Widget _tab(Widget screen, int index) => Scaffold(
  backgroundColor: Colors.white,
  body: screen,
  bottomNavigationBar: KsBottomNav(currentIndex: index, onTap: (_) {}),
);

void main() {
  testWidgets('login', (tester) async {
    await pumpScreen(tester, const LoginScreen());
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login.png'),
    );
  });

  testWidgets('otp_request', (tester) async {
    await pumpScreen(tester, const OtpRequestScreen());
    await expectLater(
      find.byType(OtpRequestScreen),
      matchesGoldenFile('goldens/otp_request.png'),
    );
  });

  testWidgets('otp_verify', (tester) async {
    await pumpScreen(tester, const OtpVerifyScreen());
    await expectLater(
      find.byType(OtpVerifyScreen),
      matchesGoldenFile('goldens/otp_verify.png'),
    );
  });

  testWidgets('set_password', (tester) async {
    await pumpScreen(tester, const SetPasswordScreen());
    await expectLater(
      find.byType(SetPasswordScreen),
      matchesGoldenFile('goldens/set_password.png'),
    );
  });

  testWidgets('password_done', (tester) async {
    await pumpScreen(tester, const PasswordDoneScreen());
    await expectLater(
      find.byType(PasswordDoneScreen),
      matchesGoldenFile('goldens/password_done.png'),
    );
  });

  testWidgets('home', (tester) async {
    await pumpScreen(tester, _tab(const HomeScreen(), 0));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/home.png'),
    );
  });

  testWidgets('home_summary_after_checkout', (tester) async {
    await pumpScreen(
      tester,
      _tab(const HomeScreen(), 0),
      overrides: [
        attendanceControllerProvider.overrideWith(
          (ref) => AttendanceController()
            ..checkIn('06:05 AM')
            ..checkOut('08:10 PM'),
        ),
      ],
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/home_summary.png'),
    );
  });

  testWidgets('pooja', (tester) async {
    await pumpScreen(tester, _tab(const PoojaListScreen(), 1));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/pooja.png'),
    );
  });

  testWidgets('account', (tester) async {
    await pumpScreen(tester, _tab(const AccountScreen(), 2));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/account.png'),
    );
  });
}
