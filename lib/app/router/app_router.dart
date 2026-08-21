import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/providers/auth_controller.dart';
import '../../features/auth/presentation/screen/login_screen.dart';
import '../../features/auth/presentation/screen/otp_request_screen.dart';
import '../../features/auth/presentation/screen/otp_verify_screen.dart';
import '../../features/auth/presentation/screen/password_done_screen.dart';
import '../../features/auth/presentation/screen/set_password_screen.dart';
import '../../features/dashboard/presentation/screen/home_screen.dart';
import '../../features/pooja/presentation/screen/pooja_list_screen.dart';
import '../../features/profile/presentation/screen/account_screen.dart';
import 'nav_shell.dart';

/// Typed route paths.
abstract final class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String otpRequest = '/otp';
  static const String otpVerify = '/otp-verify';
  static const String setPassword = '/set-password';
  static const String passwordDone = '/password-done';

  static const String home = '/home';
  static const String pooja = '/pooja';
  static const String account = '/account';

  /// Maps an [AuthDestination] from the auth controller to a route path.
  static String forAuthDestination(AuthDestination d) => switch (d) {
        AuthDestination.home => home,
        AuthDestination.otpRequest => otpRequest,
        AuthDestination.otpVerify => otpVerify,
        AuthDestination.setPassword => setPassword,
        AuthDestination.passwordDone => passwordDone,
        AuthDestination.login => login,
      };
}

/// Single app-wide router instance.
final routerProvider = Provider<GoRouter>((ref) => buildAppRouter());

/// Builds the app router. The prototype "starts signed in", so the initial
/// location is the home tab.
GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpRequest,
        builder: (context, state) => const OtpRequestScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        builder: (context, state) => const OtpVerifyScreen(),
      ),
      GoRoute(
        path: AppRoutes.setPassword,
        builder: (context, state) => const SetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.passwordDone,
        builder: (context, state) => const PasswordDoneScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            KsNavShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.pooja,
                builder: (context, state) => const PoojaListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
