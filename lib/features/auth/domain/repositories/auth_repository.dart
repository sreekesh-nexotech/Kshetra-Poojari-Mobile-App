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

  /// `POST /api/auth/send-otp/`. [phoneNumber] must carry the `+91` prefix —
  /// confirmed live: a bare 10-digit number or a `91`-only prefix both 404 as
  /// "no account found," even for a phone that is genuinely registered.
  Future<SendOtpResult> sendOtp(String phoneNumber);

  /// `POST /api/auth/otp-signin/`. [otpCode] is 6 digits.
  Future<OtpVerifyResult> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  });

  /// `POST /api/auth/forgot-password/`. Only valid with the session
  /// [verifyOtp] just established — there is no phone/OTP on this call, it
  /// rides the cookie.
  Future<PasswordResetResult> resetPassword({
    required String newPassword,
    required String confirmPassword,
  });
}
