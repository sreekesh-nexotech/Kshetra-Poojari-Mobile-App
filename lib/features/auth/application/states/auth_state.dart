/// Which OTP journey the user is on.
enum AuthFlow { otp, reset }

/// Digits only — the phone field is formatted for reading ("9142 2245 22").
String digitsOf(String raw) => raw.replaceAll(RegExp(r'\D'), '');

/// The server stores `phone_number` with the country code on it
/// (`"+918086343747"`, confirmed against `/api/auth/poojari-signin/`), so
/// every number this app sends must carry the same prefix.
const String kIndiaCallingCode = '+91';

/// The bare 10-digit local number, stripped of a `+91`/`91` prefix a poojari
/// may have typed — used to validate length and to render the field next to
/// the fixed "+91" shown in the UI.
String phoneDigitsOf(String raw) {
  final digits = digitsOf(raw);
  return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
}

/// What actually goes on the wire as `phone_number`: always `+91` plus the
/// 10-digit local number, regardless of whether the poojari typed the
/// country code themselves.
String normalizedPhone(String raw) => '$kIndiaCallingCode${phoneDigitsOf(raw)}';

/// True when the input can only be read as a phone number: digits plus the
/// punctuation people type into a phone field, and nothing else. A username
/// contains at least one character that is not one of those.
///
/// A username made **only** of digits would be read as a phone number. That is
/// the right default for a temple's poojaris, whose usernames are names.
bool looksLikePhone(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return false;
  if (!RegExp(r'^[+()\-\s0-9]+$').hasMatch(v)) return false;
  return digitsOf(v).isNotEmpty;
}

/// Immutable auth-flow state (identifier/password/OTP fields + inline errors).
class AuthState {
  const AuthState({
    this.identifier = '',
    this.password = '',
    this.busy = false,
    this.identifierError,
    this.flow = AuthFlow.otp,
    this.otp = '',
    this.otpError,
    this.newPassword = '',
    this.confirmPassword = '',
    this.passwordError,
  });

  /// What the poojari typed in the first field. On the login screen this is
  /// **either** a phone number or a username — the server accepts both
  /// (`pooja.md` §4). On the OTP screens it must be a phone number, because a
  /// username cannot receive an SMS; [AuthController] validates accordingly.
  final String identifier;

  final String password;

  /// A sign-in request is in flight — the CTA is disabled while it is.
  final bool busy;

  final String? identifierError;

  final AuthFlow flow;
  final String otp;
  final String? otpError;

  final String newPassword;
  final String confirmPassword;
  final String? passwordError;

  /// What to prefill the OTP screen's phone field with — just the local
  /// digits, since that field renders a fixed `+91` prefix next to them.
  /// Blank when the login field held a username — that field must carry a
  /// number an SMS can reach.
  String get phonePrefill =>
      looksLikePhone(identifier) ? phoneDigitsOf(identifier) : '';

  /// OTP screen heading (design `otpHeading`).
  String get otpHeading =>
      flow == AuthFlow.reset ? 'പാസ്‌വേഡ് റീസെറ്റ്' : 'ഒ.ടി.പി ലോഗിൻ';

  /// OTP request helper line (design `otpHelper`).
  String get otpHelper => flow == AuthFlow.reset
      ? 'രജിസ്റ്റർ ചെയ്ത നമ്പർ നൽകുക. ഒ.ടി.പി വഴി പുതിയ പാസ്‌വേഡ് സെറ്റ് ചെയ്യാം.'
      : 'അഡ്മിൻ സിസ്റ്റത്തിൽ രജിസ്റ്റർ ചെയ്ത നമ്പറിലേക്ക് മാത്രം ഒ.ടി.പി ലഭിക്കും.';

  AuthState copyWith({
    String? identifier,
    String? password,
    bool? busy,
    String? identifierError,
    bool clearIdentifierError = false,
    AuthFlow? flow,
    String? otp,
    String? otpError,
    bool clearOtpError = false,
    String? newPassword,
    String? confirmPassword,
    String? passwordError,
    bool clearPasswordError = false,
  }) {
    return AuthState(
      identifier: identifier ?? this.identifier,
      password: password ?? this.password,
      busy: busy ?? this.busy,
      identifierError: clearIdentifierError
          ? null
          : (identifierError ?? this.identifierError),
      flow: flow ?? this.flow,
      otp: otp ?? this.otp,
      otpError: clearOtpError ? null : (otpError ?? this.otpError),
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      passwordError: clearPasswordError
          ? null
          : (passwordError ?? this.passwordError),
    );
  }
}
