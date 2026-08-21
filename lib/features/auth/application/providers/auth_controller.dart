import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mock/auth_mock_data.dart';
import '../states/auth_state.dart';

/// Where an auth action wants to navigate next.
enum AuthDestination {
  home,
  otpRequest,
  otpVerify,
  setPassword,
  passwordDone,
  login,
}

/// Result of an auth action: an optional navigation + optional toast. Errors
/// are reported through [AuthState] (inline), never here — keeps the controller
/// free of BuildContext / navigation / snackbars.
class AuthOutcome {
  const AuthOutcome({this.navigate, this.toast});
  final AuthDestination? navigate;
  final String? toast;

  static const AuthOutcome none = AuthOutcome();
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState());

  // ── Field setters (clear the relevant inline error) ────────────────────────
  void setPhone(String v) =>
      state = state.copyWith(phone: v, clearPhoneError: true);

  void setPassword(String v) =>
      state = state.copyWith(password: v, clearPhoneError: true);

  void setOtp(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 4 ? digits.substring(0, 4) : digits;
    state = state.copyWith(otp: trimmed, clearOtpError: true);
  }

  void setNewPassword(String v) =>
      state = state.copyWith(newPassword: v, clearPasswordError: true);

  void setConfirmPassword(String v) =>
      state = state.copyWith(confirmPassword: v, clearPasswordError: true);

  // ── Validation ─────────────────────────────────────────────────────────────
  String? _phoneError() {
    final normalized = AuthMockData.normalize(state.phone);
    if (normalized.isEmpty) return 'ഫോൺ നമ്പർ നൽകുക';
    if (!AuthMockData.isRegistered(state.phone)) {
      return 'ഈ നമ്പർ അഡ്മിൻ സിസ്റ്റത്തിൽ രജിസ്റ്റർ ചെയ്തിട്ടില്ല';
    }
    return null;
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  AuthOutcome login() {
    final err =
        _phoneError() ?? (state.password.isEmpty ? 'പാസ്‌വേഡ് നൽകുക' : null);
    if (err != null) {
      state = state.copyWith(phoneError: err);
      return AuthOutcome.none;
    }
    state = state.copyWith(clearPhoneError: true);
    return const AuthOutcome(
      navigate: AuthDestination.home,
      toast: 'ലോഗിൻ വിജയിച്ചു ✓',
    );
  }

  AuthOutcome startOtpLogin() {
    state = state.copyWith(flow: AuthFlow.otp, clearPhoneError: true);
    return const AuthOutcome(navigate: AuthDestination.otpRequest);
  }

  AuthOutcome startReset() {
    state = state.copyWith(flow: AuthFlow.reset, clearPhoneError: true);
    return const AuthOutcome(navigate: AuthDestination.otpRequest);
  }

  AuthOutcome sendOtp() {
    final err = _phoneError();
    if (err != null) {
      state = state.copyWith(phoneError: err);
      return AuthOutcome.none;
    }
    state = state.copyWith(otp: '', clearPhoneError: true, clearOtpError: true);
    return const AuthOutcome(navigate: AuthDestination.otpVerify);
  }

  AuthOutcome verifyOtp() {
    if (!AuthMockData.isOtpValid(state.otp)) {
      state = state.copyWith(otpError: 'ഒ.ടി.പി തെറ്റാണ് · വീണ്ടും ശ്രമിക്കുക');
      return AuthOutcome.none;
    }
    state = state.copyWith(clearOtpError: true);
    if (state.flow == AuthFlow.reset) {
      state = state.copyWith(
        newPassword: '',
        confirmPassword: '',
        clearPasswordError: true,
      );
      return const AuthOutcome(navigate: AuthDestination.setPassword);
    }
    return const AuthOutcome(
      navigate: AuthDestination.home,
      toast: 'ലോഗിൻ വിജയിച്ചു ✓',
    );
  }

  AuthOutcome resendOtp() {
    state = state.copyWith(otp: '', clearOtpError: true);
    return const AuthOutcome(toast: 'ഒ.ടി.പി വീണ്ടും അയച്ചു (1234)');
  }

  AuthOutcome submitNewPassword() {
    if (state.newPassword.length < 4) {
      state = state.copyWith(passwordError: 'കുറഞ്ഞത് 4 അക്ഷരങ്ങൾ വേണം');
      return AuthOutcome.none;
    }
    if (state.newPassword != state.confirmPassword) {
      state = state.copyWith(passwordError: 'പാസ്‌വേഡുകൾ ഒന്നല്ല');
      return AuthOutcome.none;
    }
    state = state.copyWith(clearPasswordError: true);
    return const AuthOutcome(navigate: AuthDestination.passwordDone);
  }

  AuthOutcome backToLogin() {
    state = state.copyWith(clearPhoneError: true, clearOtpError: true);
    return const AuthOutcome(navigate: AuthDestination.login);
  }

  /// Reset transient fields when the poojari logs out.
  void resetForLogout() => state = state.copyWith(
    password: '',
    clearPhoneError: true,
    clearOtpError: true,
  );
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);
