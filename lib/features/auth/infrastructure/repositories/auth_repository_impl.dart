import '../../../../core/network/network_exceptions.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/remote/auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._api);

  final AuthApi _api;

  @override
  Future<void> primeCsrf() => _api.primeCsrf();

  @override
  Future<SignInResult> signIn({
    String? username,
    String? phoneNumber,
    required String password,
    String? fcmToken,
  }) async {
    await _api.primeCsrf();

    final res = await _api.poojariSignIn(
      username: username,
      phoneNumber: phoneNumber,
      password: password,
      fcmToken: fcmToken,
    );

    if (res.status == 200) {
      // Branch on this BEFORE looking at `user` — an unactivated account
      // answers 200 with no user object at all.
      if (res.body['requires_password_setup'] == true) {
        return NeedsPasswordSetup(res.body['phone_number'] as String? ?? '');
      }
      final user = res.body['user'];
      if (user is Map<String, dynamic>) {
        return SignedIn(PoojariUser.fromJson(user));
      }
      return const SignInFailed('Sign in failed');
    }

    return SignInFailed(
      (res.body['error'] ?? res.body['detail'] ?? 'Sign in failed') as String,
    );
  }

  @override
  Future<PoojariUser?> profile() async {
    final res = await _api.profile();
    if (res.status == 200) return PoojariUser.fromJson(res.body);
    // 401/403 = the session is genuinely gone. Anything else is a real fault
    // and must not be mistaken for "signed out".
    if (res.status == 401 || res.status == 403) return null;
    throw ApiException.fromResponse(res.status, res.body);
  }

  @override
  Future<void> signOut() async {
    try {
      await _api.logout();
    } catch (_) {
      // A server that will not answer must not trap the poojari in a session
      // they asked to end. The jar is emptied below either way, which is what
      // actually signs them out on this device.
    } finally {
      await _api.clearSession();
    }
  }
}
