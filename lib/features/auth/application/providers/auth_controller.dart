import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../states/auth_state.dart';
import 'session_controller.dart';

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

/// Shown wherever the OTP / password-reset journey would call the server.
/// Remove once the endpoint contract lands.
const String kOtpUnavailable =
    'ഒ.ടി.പി ലോഗിൻ ഉടൻ ലഭ്യമാകും · പാസ്‌വേഡ് ഉപയോഗിക്കുക';

/// Maps the server's English sign-in errors to the app's Malayalam copy.
/// Anything unrecognised falls through to the server string rather than being
/// swallowed — a new backend message should be visible, not hidden.
String _signInCopy(String serverMessage) {
  final m = serverMessage.toLowerCase();
  if (m.contains('invalid credentials')) {
    return 'ഫോൺ നമ്പറോ പാസ്‌വേഡോ തെറ്റാണ്';
  }
  if (m.contains('no poojari account')) {
    return 'ഈ നമ്പർ പൂജാരിയായി രജിസ്റ്റർ ചെയ്തിട്ടില്ല';
  }
  if (m.contains('inactive')) {
    return 'അക്കൗണ്ട് നിർജ്ജീവമാണ് · അഡ്മിനുമായി ബന്ധപ്പെടുക';
  }
  if (m.contains('password is required')) return 'പാസ്‌വേഡ് നൽകുക';
  if (m.contains('required')) return 'ഫോൺ നമ്പർ നൽകുക';
  return serverMessage;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState());

  final Ref _ref;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  /// Digits only — the field is formatted for reading ("9142 2245 22").
  static String _digits(String raw) => raw.replaceAll(RegExp(r'\D'), '');

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
  /// Local checks only — whether a number is *registered* is the server's to
  /// answer, and guessing it client-side would be wrong.
  String? _phoneError() {
    final normalized = _digits(state.phone);
    if (normalized.isEmpty) return 'ഫോൺ നമ്പർ നൽകുക';
    if (normalized.length < 10) return 'പൂർണ്ണമായ ഫോൺ നമ്പർ നൽകുക';
    return null;
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<AuthOutcome> login() async {
    if (state.busy) return AuthOutcome.none;

    final err =
        _phoneError() ?? (state.password.isEmpty ? 'പാസ്‌വേഡ് നൽകുക' : null);
    if (err != null) {
      state = state.copyWith(phoneError: err);
      return AuthOutcome.none;
    }

    state = state.copyWith(busy: true, clearPhoneError: true);
    try {
      final result = await _repo.signIn(
        phoneNumber: _digits(state.phone),
        password: state.password,
      );

      switch (result) {
        case SignedIn(:final user):
          _ref.read(sessionControllerProvider.notifier).signedIn(user);
          state = state.copyWith(busy: false, password: '');
          return const AuthOutcome(
            navigate: AuthDestination.home,
            toast: 'ലോഗിൻ വിജയിച്ചു ✓',
          );

        // A 200 that is NOT a sign-in: the account exists but has no password,
        // and the server has already sent an OTP.
        case NeedsPasswordSetup(:final phoneNumber):
          state = state.copyWith(
            busy: false,
            flow: AuthFlow.reset,
            phone: phoneNumber.isEmpty ? state.phone : phoneNumber,
            otp: '',
            clearOtpError: true,
          );
          return const AuthOutcome(
            navigate: AuthDestination.otpVerify,
            toast: 'പാസ്‌വേഡ് സെറ്റ് ചെയ്യാൻ ഒ.ടി.പി അയച്ചു',
          );

        case SignInFailed(:final message):
          state = state.copyWith(busy: false, phoneError: _signInCopy(message));
          return AuthOutcome.none;
      }
    } catch (e) {
      state = state.copyWith(busy: false, phoneError: Failure.from(e).message);
      return AuthOutcome.none;
    }
  }

  AuthOutcome startOtpLogin() {
    state = state.copyWith(flow: AuthFlow.otp, clearPhoneError: true);
    return const AuthOutcome(navigate: AuthDestination.otpRequest);
  }

  AuthOutcome startReset() {
    state = state.copyWith(flow: AuthFlow.reset, clearPhoneError: true);
    return const AuthOutcome(navigate: AuthDestination.otpRequest);
  }

  // ── OTP journey — NOT WIRED TO THE SERVER YET ──────────────────────────────
  // `docs-flutter/pooja.md` §4 names POST /api/auth/otp-signin/ and
  // POST /api/auth/forgot-password/, but does not say which one sends the OTP
  // versus verifies it, gives no request or response bodies, no resend
  // endpoint, and no OTP length (this UI is built for 4 digits). Guessing
  // those would produce confusing 400s, so these actions fail closed and say
  // so. Password sign-in is complete and is the working path.
  //
  // The one live entry into this journey is `login()`'s NeedsPasswordSetup
  // branch, where the server has already sent an OTP.

  AuthOutcome sendOtp() {
    final err = _phoneError();
    if (err != null) {
      state = state.copyWith(phoneError: err);
      return AuthOutcome.none;
    }
    state = state.copyWith(clearPhoneError: true);
    return const AuthOutcome(toast: kOtpUnavailable);
  }

  AuthOutcome verifyOtp() {
    if (state.otp.length != 4) {
      state = state.copyWith(otpError: 'ഒ.ടി.പി പൂർണ്ണമായി നൽകുക');
      return AuthOutcome.none;
    }
    // Only the server can say whether an OTP is correct. Navigating to home
    // on a locally "valid" code would claim a session that does not exist —
    // the router's redirect would bounce it straight back anyway.
    state = state.copyWith(clearOtpError: true);
    return const AuthOutcome(toast: kOtpUnavailable);
  }

  AuthOutcome resendOtp() {
    state = state.copyWith(otp: '', clearOtpError: true);
    return const AuthOutcome(toast: kOtpUnavailable);
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
    return const AuthOutcome(toast: kOtpUnavailable);
  }

  AuthOutcome backToLogin() {
    state = state.copyWith(clearPhoneError: true, clearOtpError: true);
    return const AuthOutcome(navigate: AuthDestination.login);
  }

  /// Reset transient fields when the poojari logs out.
  void resetForLogout() => state = state.copyWith(
    password: '',
    busy: false,
    clearPhoneError: true,
    clearOtpError: true,
  );
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
