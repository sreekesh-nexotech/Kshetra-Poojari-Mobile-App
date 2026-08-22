/// ── MOCK AUTH SEAM ───────────────────────────────────────────────────────────
/// Demo credentials for the prototype. Only a poojari whose number the admin
/// added can log in, so there is no sign-up. Replace [validate*] with the real
/// auth/OTP API on integration; the design keeps the on-screen demo hint since
/// the flow is otherwise untestable.
abstract final class AuthMockData {
  AuthMockData._();

  /// The one registered number (normalized, digits only).
  static const String registeredPhone = '9142224522';

  /// Pre-filled display value on the login screen.
  static const String demoPhoneDisplay = '9142 2245 22';

  /// The demo OTP.
  static const String demoOtp = '1234';

  static String normalize(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  static bool isRegistered(String rawPhone) =>
      normalize(rawPhone) == registeredPhone;

  static bool isOtpValid(String otp) => otp == demoOtp;
}
