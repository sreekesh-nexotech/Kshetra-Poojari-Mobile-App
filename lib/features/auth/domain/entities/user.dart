/// The signed-in poojari.
class PoojariUser {
  const PoojariUser({
    required this.id,
    required this.username,
    this.email,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.role = 'temple_poojari',
    this.employeeId,
  });

  final int id;
  final String username;
  final String? email;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;

  /// The ID badge shown on the profile screen. Null until an admin assigns
  /// one — render the badge conditionally, never a placeholder.
  final String? employeeId;

  /// Always `temple_poojari` on this app's endpoints — anything else and the
  /// sign-in would have been refused with a 403.
  final String role;

  String get displayName {
    final full = [firstName, lastName].whereType<String>().join(' ').trim();
    return full.isEmpty ? username : full;
  }

  factory PoojariUser.fromJson(Map<String, dynamic> j) => PoojariUser(
    id: j['id'] as int,
    username: j['username'] as String? ?? '',
    email: j['email'] as String?,
    phoneNumber: j['phone_number'] as String?,
    firstName: j['first_name'] as String?,
    lastName: j['last_name'] as String?,
    role: j['role'] as String? ?? 'temple_poojari',
    employeeId: j['employee_id'] as String?,
  );
}

/// What `POST /api/auth/poojari-signin/` produced.
///
/// All three arrive as HTTP 200 or a 4xx — the branch that matters is
/// [NeedsPasswordSetup], which is a **200** and would otherwise be mistaken
/// for a successful sign-in, leaving the app on a spinner.
sealed class SignInResult {
  const SignInResult();
}

class SignedIn extends SignInResult {
  const SignedIn(this.user);
  final PoojariUser user;
}

/// A poojari the back office registered who has never set a password. The
/// server has already sent an OTP to [phoneNumber].
class NeedsPasswordSetup extends SignInResult {
  const NeedsPasswordSetup(this.phoneNumber);
  final String phoneNumber;
}

class SignInFailed extends SignInResult {
  const SignInFailed(this.message);
  final String message;
}

/// What `POST /api/auth/send-otp/` produced.
sealed class SendOtpResult {
  const SendOtpResult();
}

class OtpSent extends SendOtpResult {
  const OtpSent();
}

class SendOtpFailed extends SendOtpResult {
  const SendOtpFailed(this.message);
  final String message;
}

/// What `POST /api/auth/otp-signin/` produced.
///
/// A `200` here means the server has already set the session cookie — this
/// is a real sign-in, generic across every account type (`temple_poojari`
/// included, but not exclusively). The role check that decides whether that
/// session belongs in *this* app happens one layer up, in the controller.
sealed class OtpVerifyResult {
  const OtpVerifyResult();
}

class OtpVerified extends OtpVerifyResult {
  const OtpVerified(this.user);
  final PoojariUser user;
}

class OtpVerifyFailed extends OtpVerifyResult {
  const OtpVerifyFailed(this.message);
  final String message;
}

/// What `POST /api/auth/forgot-password/` produced. Only ever called with
/// the session an `OtpVerified` result just created.
sealed class PasswordResetResult {
  const PasswordResetResult();
}

class PasswordWasReset extends PasswordResetResult {
  const PasswordWasReset();
}

class PasswordResetFailed extends PasswordResetResult {
  const PasswordResetFailed(this.message);
  final String message;
}
