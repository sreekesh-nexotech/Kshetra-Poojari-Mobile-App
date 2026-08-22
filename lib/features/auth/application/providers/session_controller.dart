import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
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
  }

  /// The session expired mid-use — drop the cookie and send them to login.
  Future<void> expired() async {
    try {
      await _ref.read(apiClientProvider).clearSession();
    } catch (_) {
      // No client wired (tests).
    }
    state = SessionState.signedOut;
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
