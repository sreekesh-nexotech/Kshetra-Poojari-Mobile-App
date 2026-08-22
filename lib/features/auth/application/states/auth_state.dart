/// Which OTP journey the user is on.
enum AuthFlow { otp, reset }

/// Immutable auth-flow state (phone/password/OTP fields + inline errors).
class AuthState {
  const AuthState({
    this.phone = '',
    this.password = '',
    this.busy = false,
    this.phoneError,
    this.flow = AuthFlow.otp,
    this.otp = '',
    this.otpError,
    this.newPassword = '',
    this.confirmPassword = '',
    this.passwordError,
  });

  final String phone;
  final String password;

  /// A sign-in request is in flight — the CTA is disabled while it is.
  final bool busy;

  final String? phoneError;

  final AuthFlow flow;
  final String otp;
  final String? otpError;

  final String newPassword;
  final String confirmPassword;
  final String? passwordError;

  /// OTP screen heading (design `otpHeading`).
  String get otpHeading =>
      flow == AuthFlow.reset ? 'പാസ്‌വേഡ് റീസെറ്റ്' : 'ഒ.ടി.പി ലോഗിൻ';

  /// OTP request helper line (design `otpHelper`).
  String get otpHelper => flow == AuthFlow.reset
      ? 'രജിസ്റ്റർ ചെയ്ത നമ്പർ നൽകുക. ഒ.ടി.പി വഴി പുതിയ പാസ്‌വേഡ് സെറ്റ് ചെയ്യാം.'
      : 'അഡ്മിൻ സിസ്റ്റത്തിൽ രജിസ്റ്റർ ചെയ്ത നമ്പറിലേക്ക് മാത്രം ഒ.ടി.പി ലഭിക്കും.';

  AuthState copyWith({
    String? phone,
    String? password,
    bool? busy,
    String? phoneError,
    bool clearPhoneError = false,
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
      phone: phone ?? this.phone,
      password: password ?? this.password,
      busy: busy ?? this.busy,
      phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
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
