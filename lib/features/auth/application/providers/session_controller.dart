import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../dashboard/application/providers/attendance_controller.dart';
import '../../../dashboard/application/providers/home_providers.dart';
import '../../../pooja/application/providers/pooja_data_providers.dart';
import '../../../pooja/application/providers/pooja_list_controller.dart';
import '../../../profile/application/providers/profile_providers.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../infrastructure/data_sources/remote/auth_api.dart';
import '../../infrastructure/repositories/auth_repository_impl.dart';
import '../states/session_state.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(AuthApi(ref.watch(apiClientProvider))),
);

/// Resolved once, before `runApp`, and injected as the starting state — so
/// there is no first-frame flash of the login screen and no /splash route.
final sessionSeedProvider = Provider<SessionState>(
  (ref) => const SessionState(),
);

class SessionController extends StateNotifier<SessionState> {
  SessionController(this._ref, super.seed);

  final Ref _ref;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  void signedIn(PoojariUser user) =>
      state = SessionState(status: SessionStatus.authenticated, user: user);

  Future<void> signOut() async {
    try {
      await _repo.signOut();
    } catch (_) {
      // signOut already empties the jar in its finally block.
    }
    state = SessionState.signedOut;
    _clearFeatureCaches();
  }

  /// The session expired mid-use — drop the cookie and send them to login.
  Future<void> expired() async {
    try {
      await _ref.read(apiClientProvider).clearSession();
    } catch (_) {
      // No client wired (tests).
    }
    state = SessionState.signedOut;
    _clearFeatureCaches();
  }

  /// Every other feature's controllers are Global (not autoDispose) so they
  /// survive tab switches within one poojari's session — but that means they
  /// also survive *between* two different poojaris signing in on the same
  /// device unless something resets them here. Without this, a poojari who
  /// logs out and hands the device to a colleague would see the first
  /// poojari's check-in mark, shrines, tasks and KPI figures rendered under
  /// their own name until they happened to pull-to-refresh every screen.
  /// Invalidating resets each provider to its declared initial state, so the
  /// next `ensureLoaded()` on Home/Pooja/Account finds nothing cached and
  /// fetches fresh — scoped to whoever signs in next.
  void _clearFeatureCaches() {
    _ref.invalidate(attendanceControllerProvider);
    _ref.invalidate(malayalamDateControllerProvider);
    _ref.invalidate(upcomingDaysControllerProvider);
    _ref.invalidate(dashboardFeedControllerProvider);
    _ref.invalidate(godsControllerProvider);
    _ref.invalidate(poojaTasksControllerProvider);
    _ref.invalidate(poojaFeedControllerProvider);
    _ref.invalidate(poojaListControllerProvider);
    _ref.invalidate(assignedGodsLabelControllerProvider);
    _ref.invalidate(monthKpisControllerProvider);
    _ref.invalidate(weekDaysControllerProvider);
    _ref.invalidate(profileFeedControllerProvider);
  }
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>(
      (ref) => SessionController(ref, ref.watch(sessionSeedProvider)),
    );

/// Resolves the persisted session at cold start.
///
/// A `403` is a real rejection. A timeout or socket error is **not** — the
/// cookie is still on disk, so the poojari stays signed in and the screens
/// surface the connectivity problem themselves.
abstract final class SessionBootstrap {
  SessionBootstrap._();

  static Future<SessionState> restore(ApiClient client) async {
    final repo = AuthRepositoryImpl(AuthApi(client));
    try {
      final user = await repo.profile().timeout(const Duration(seconds: 3));
      if (user != null) {
        return SessionState(status: SessionStatus.authenticated, user: user);
      }
      await client.clearSession();
      return SessionState.signedOut;
    } catch (e) {
      debugPrint('Session restore could not reach the server: $e');
      final hasCookie = await client.hasSessionCookie();
      return hasCookie
          ? const SessionState(status: SessionStatus.stale)
          : SessionState.signedOut;
    }
  }
}
