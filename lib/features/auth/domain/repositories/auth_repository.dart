import '../entities/user.dart';

abstract interface class AuthRepository {
  /// Prime the CSRF cookie. The sign-in endpoints are `@csrf_exempt`, but
  /// every write after them is not.
  Future<void> primeCsrf();

  /// Either [username] or [phoneNumber]; [password] is always required.
  Future<SignInResult> signIn({
    String? username,
    String? phoneNumber,
    required String password,
    String? fcmToken,
  });

  /// The signed-in poojari, or null when the session is gone.
  ///
  /// Throws on a transport failure so the caller can tell "signed out" from
  /// "offline" — those must not be treated the same.
  Future<PoojariUser?> profile();

  /// Ends the server session and clears the stored FCM token, then empties
  /// the cookie jar.
  Future<void> signOut();
}
