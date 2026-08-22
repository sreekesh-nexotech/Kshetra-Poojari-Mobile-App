import '../../domain/entities/user.dart';

enum SessionStatus {
  /// Not resolved yet.
  unknown,

  /// A session cookie is held and the server accepted it.
  authenticated,

  /// A session cookie is held but the server could not be reached to confirm
  /// it. The poojari stays in — logging them out because the temple wifi
  /// hiccuped is the worst failure mode here.
  stale,

  unauthenticated,
}

class SessionState {
  const SessionState({this.status = SessionStatus.unknown, this.user});

  final SessionStatus status;
  final PoojariUser? user;

  /// Stale counts as signed in: the cookie is still on disk, and the screens
  /// have their own error branches for a server that is not answering.
  bool get isAuthenticated =>
      status == SessionStatus.authenticated || status == SessionStatus.stale;

  bool get isResolved => status != SessionStatus.unknown;

  static const SessionState signedOut = SessionState(
    status: SessionStatus.unauthenticated,
  );

  SessionState copyWith({
    SessionStatus? status,
    PoojariUser? user,
    bool clearUser = false,
  }) => SessionState(
    status: status ?? this.status,
    user: clearUser ? null : (user ?? this.user),
  );
}
