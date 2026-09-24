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

/// Maps the server's English send-otp/otp-signin errors to the app's
/// Malayalam copy. Only messages actually observed from the live server are
/// translated; anything else falls through to the server string, same rule
/// as [_signInCopy].
String _otpCopy(String serverMessage) {
  final m = serverMessage.toLowerCase();
  if (m.contains('no account found')) {
    return 'ഈ നമ്പർ രജിസ്റ്റർ ചെയ്തിട്ടില്ല';
  }
  return serverMessage;
}

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
  // Server: "Username or phone number is required".
  if (m.contains('required')) return 'ഫോൺ നമ്പറോ യൂസർനെയിമോ നൽകുക';
  return serverMessage;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState());

  final Ref _ref;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  // ── Field setters (clear the relevant inline error) ────────────────────────
  void setIdentifier(String v) =>
      state = state.copyWith(identifier: v, clearIdentifierError: true);

  void setPassword(String v) =>
      state = state.copyWith(password: v, clearIdentifierError: true);

  void setOtp(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    // 6 digits, confirmed against a real OTP from the live server — the
    // design's own 4-digit mock never matched what the backend actually sends.
    final trimmed = digits.length > 6 ? digits.substring(0, 6) : digits;
    state = state.copyWith(otp: trimmed, clearOtpError: true);
  }

  void setNewPassword(String v) =>
      state = state.copyWith(newPassword: v, clearPasswordError: true);

  void setConfirmPassword(String v) =>
      state = state.copyWith(confirmPassword: v, clearPasswordError: true);

  // ── Validation ─────────────────────────────────────────────────────────────
  // Local checks only — whether an account is *registered* is the server's to
  // answer, and guessing it client-side would be wrong.

  /// Login accepts either form, so the only local check on a username is that
  /// it is not blank; a phone number is still held to its full length.
  String? _identifierError() {
    final v = state.identifier.trim();
    if (v.isEmpty) return 'ഫോൺ നമ്പറോ യൂസർനെയിമോ നൽകുക';
    if (looksLikePhone(v) && phoneDigitsOf(v).length < 10) {
      return 'പൂർണ്ണമായ ഫോൺ നമ്പർ നൽകുക';
    }
    return null;
  }

  /// The OTP screens are stricter: an OTP is delivered by SMS, so a username
  /// is not a usable input there however valid it is at login.
  String? _phoneError() {
    final v = state.identifier.trim();
    if (v.isEmpty) return 'ഫോൺ നമ്പർ നൽകുക';
    if (!looksLikePhone(v)) return 'ഒ.ടി.പി-ക്ക് ഫോൺ നമ്പർ നൽകുക';
    if (phoneDigitsOf(v).length < 10) return 'പൂർണ്ണമായ ഫോൺ നമ്പർ നൽകുക';
    return null;
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<AuthOutcome> login() async {
    if (state.busy) return AuthOutcome.none;

    final err =
        _identifierError() ??
        (state.password.isEmpty ? 'പാസ്‌വേഡ് നൽകുക' : null);
    if (err != null) {
      state = state.copyWith(identifierError: err);
      return AuthOutcome.none;
    }

    state = state.copyWith(busy: true, clearIdentifierError: true);
    try {
      // `pooja.md` §4: either `username` or `phone_number`, never both — the
      // server picks its lookup from whichever key is present.
      final id = state.identifier.trim();
      final isPhone = looksLikePhone(id);
      final result = await _repo.signIn(
        username: isPhone ? null : id,
        phoneNumber: isPhone ? normalizedPhone(id) : null,
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
            identifier: phoneNumber.isEmpty ? state.identifier : phoneNumber,
            otp: '',
            clearOtpError: true,
          );
          return const AuthOutcome(
            navigate: AuthDestination.otpVerify,
            toast: 'പാസ്‌വേഡ് സെറ്റ് ചെയ്യാൻ ഒ.ടി.പി അയച്ചു',
          );

        case SignInFailed(:final message):
          state = state.copyWith(
            busy: false,
            identifierError: _signInCopy(message),
          );
          return AuthOutcome.none;
      }
    } catch (e) {
      state = state.copyWith(
        busy: false,
        identifierError: Failure.from(e).message,
      );
      return AuthOutcome.none;
    }
  }

  AuthOutcome startOtpLogin() {
    state = state.copyWith(flow: AuthFlow.otp, clearIdentifierError: true);
    return const AuthOutcome(navigate: AuthDestination.otpRequest);
  }

  AuthOutcome startReset() {
    state = state.copyWith(flow: AuthFlow.reset, clearIdentifierError: true);
    return const AuthOutcome(navigate: AuthDestination.otpRequest);
  }

  // ── OTP journey ──────────────────────────────────────────────────────────
  // Contract confirmed live against the server (docs and schema both leave
  // the request/response bodies undocumented):
  //   POST /api/auth/send-otp/    {"phone_number": "+91..."}
  //   POST /api/auth/otp-signin/  {"phone_number": "+91...", "otp_code": "6 digits"}
  //   POST /api/auth/forgot-password/ {"new_password", "confirm_password"}
  // `otp-signin` signs the poojari in server-side on success — generically,
  // across every account type, not poojari-only — so `verifyOtp` below is
  // the one place that has to check `role` itself; nothing upstream does it
  // for this path the way `poojari-signin` does.

  Future<AuthOutcome> sendOtp() async {
    if (state.busy) return AuthOutcome.none;
    final err = _phoneError();
    if (err != null) {
      state = state.copyWith(identifierError: err);
      return AuthOutcome.none;
    }

    state = state.copyWith(busy: true, clearIdentifierError: true);
    try {
      final result = await _repo.sendOtp(normalizedPhone(state.identifier));
      switch (result) {
        case OtpSent():
          state = state.copyWith(busy: false, otp: '', clearOtpError: true);
          return const AuthOutcome(
            navigate: AuthDestination.otpVerify,
            toast: 'ഒ.ടി.പി അയച്ചു',
          );
        case SendOtpFailed(:final message):
          state = state.copyWith(
            busy: false,
            identifierError: _otpCopy(message),
          );
          return AuthOutcome.none;
      }
    } catch (e) {
      state = state.copyWith(
        busy: false,
        identifierError: Failure.from(e).message,
      );
      return AuthOutcome.none;
    }
  }

  Future<AuthOutcome> verifyOtp() async {
    if (state.busy) return AuthOutcome.none;
    if (state.otp.length != 6) {
      state = state.copyWith(otpError: 'ഒ.ടി.പി പൂർണ്ണമായി നൽകുക');
      return AuthOutcome.none;
    }

    state = state.copyWith(busy: true, clearOtpError: true);
    try {
      final result = await _repo.verifyOtp(
        phoneNumber: normalizedPhone(state.identifier),
        otpCode: state.otp,
      );
      switch (result) {
        case OtpVerified(:final user):
          if (user.role != 'temple_poojari') {
            // The server signed this account in regardless of role — undo
            // it, the same refusal `poojari-signin` gives a non-poojari.
            await _repo.signOut();
            state = state.copyWith(
              busy: false,
              otpError: 'ഈ നമ്പർ പൂജാരിയായി രജിസ്റ്റർ ചെയ്തിട്ടില്ല',
            );
            return AuthOutcome.none;
          }
          state = state.copyWith(busy: false, otp: '');
          if (state.flow == AuthFlow.otp) {
            // Passwordless login — the OTP itself is the credential.
            _ref.read(sessionControllerProvider.notifier).signedIn(user);
            return const AuthOutcome(
              navigate: AuthDestination.home,
              toast: 'ലോഗിൻ വിജയിച്ചു ✓',
            );
          }
          // Reset / first-time setup — a password is still required before
          // this account is usable day to day. `submitNewPassword` reuses
          // the session this call just established.
          return const AuthOutcome(navigate: AuthDestination.setPassword);
        case OtpVerifyFailed(:final message):
          state = state.copyWith(busy: false, otpError: message);
          return AuthOutcome.none;
      }
    } catch (e) {
      state = state.copyWith(busy: false, otpError: Failure.from(e).message);
      return AuthOutcome.none;
    }
  }

  Future<AuthOutcome> resendOtp() async {
    state = state.copyWith(otp: '', clearOtpError: true);
    return sendOtp();
  }

  Future<AuthOutcome> submitNewPassword() async {
    if (state.busy) return AuthOutcome.none;
    if (state.newPassword.length < 4) {
      state = state.copyWith(passwordError: 'കുറഞ്ഞത് 4 അക്ഷരങ്ങൾ വേണം');
      return AuthOutcome.none;
    }
    if (state.newPassword != state.confirmPassword) {
      state = state.copyWith(passwordError: 'പാസ്‌വേഡുകൾ ഒന്നല്ല');
      return AuthOutcome.none;
    }

    state = state.copyWith(busy: true, clearPasswordError: true);
    try {
      final result = await _repo.resetPassword(
        newPassword: state.newPassword,
        confirmPassword: state.confirmPassword,
      );
      switch (result) {
        case PasswordWasReset():
          // Always back to a fresh login, never straight into the app — the
          // poojari types the new password once, on purpose, before it's
          // trusted (password_done_screen's own button goes to login).
          state = state.copyWith(
            busy: false,
            newPassword: '',
            confirmPassword: '',
          );
          return const AuthOutcome(navigate: AuthDestination.passwordDone);
        case PasswordResetFailed(:final message):
          state = state.copyWith(busy: false, passwordError: message);
          return AuthOutcome.none;
      }
    } catch (e) {
      state = state.copyWith(
        busy: false,
        passwordError: Failure.from(e).message,
      );
      return AuthOutcome.none;
    }
  }

  AuthOutcome backToLogin() {
    state = state.copyWith(clearIdentifierError: true, clearOtpError: true);
    return const AuthOutcome(navigate: AuthDestination.login);
  }

  /// Reset transient fields when the poojari logs out.
  void resetForLogout() => state = state.copyWith(
    password: '',
    busy: false,
    clearIdentifierError: true,
    clearOtpError: true,
  );
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
