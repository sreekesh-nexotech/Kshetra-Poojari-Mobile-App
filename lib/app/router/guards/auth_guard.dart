import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/providers/session_controller.dart';
import '../app_router.dart';

/// Routes reachable without a session.
const Set<String> kAuthRoutes = {
  AppRoutes.login,
  AppRoutes.otpRequest,
  AppRoutes.otpVerify,
  AppRoutes.setPassword,
  AppRoutes.passwordDone,
};

/// Bridges the session into GoRouter's `refreshListenable`.
///
/// The router must NOT `ref.watch` the session directly: that rebuilds the
/// whole GoRouter — and resets the StatefulShellRoute's tab state — on every
/// auth tick. A ChangeNotifier just tells it to re-run `redirect`.
class SessionRefresh extends ChangeNotifier {
  SessionRefresh(Ref ref) {
    ref.listen(sessionControllerProvider, (_, _) => notifyListeners());
  }
}

final sessionRefreshProvider = Provider<SessionRefresh>((ref) {
  final notifier = SessionRefresh(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});
