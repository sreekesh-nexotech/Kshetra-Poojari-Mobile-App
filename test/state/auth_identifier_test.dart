import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kshetra_poojari/features/auth/application/providers/auth_controller.dart';
import 'package:kshetra_poojari/features/auth/application/providers/session_controller.dart';
import 'package:kshetra_poojari/features/auth/application/states/auth_state.dart';
import 'package:kshetra_poojari/features/auth/domain/entities/user.dart';
import 'package:kshetra_poojari/features/auth/domain/repositories/auth_repository.dart';

/// Records what the controller decided to send, so the tests can assert on the
/// *shape* of the request rather than on a wire format.
class _RecordingAuth implements AuthRepository {
  String? username;
  String? phoneNumber;
  int calls = 0;

  @override
  Future<SignInResult> signIn({
    String? username,
    String? phoneNumber,
    required String password,
    String? fcmToken,
  }) async {
    calls++;
    this.username = username;
    this.phoneNumber = phoneNumber;
    return const SignedIn(PoojariUser(id: 41, username: 'sharma'));
  }

  @override
  Future<void> primeCsrf() async {}

  @override
  Future<PoojariUser?> profile() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<SendOtpResult> sendOtp(String phoneNumber) async {
    calls++;
    this.phoneNumber = phoneNumber;
    return const OtpSent();
  }

  @override
  Future<OtpVerifyResult> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    calls++;
    this.phoneNumber = phoneNumber;
    return const OtpVerified(PoojariUser(id: 41, username: 'sharma'));
  }

  @override
  Future<PasswordResetResult> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    calls++;
    return const PasswordWasReset();
  }
}

({ProviderContainer container, _RecordingAuth repo}) _harness() {
  final repo = _RecordingAuth();
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return (container: container, repo: repo);
}

void main() {
  group('the login field takes either a phone number or a username', () {
    test('a phone number is sent as phone_number, never as username', () async {
      final h = _harness();
      final c = h.container.read(authControllerProvider.notifier)
        ..setIdentifier('9847000000')
        ..setPassword('secret');

      await c.login();

      expect(h.repo.phoneNumber, '+919847000000');
      expect(h.repo.username, isNull);
    });

    test('a username is sent as username, never as phone_number', () async {
      final h = _harness();
      final c = h.container.read(authControllerProvider.notifier)
        ..setIdentifier('sharma')
        ..setPassword('secret');

      await c.login();

      expect(h.repo.username, 'sharma');
      expect(h.repo.phoneNumber, isNull);
    });

    test('a phone typed with its own +91 is not double-prefixed', () async {
      final h = _harness();
      final c = h.container.read(authControllerProvider.notifier)
        ..setIdentifier(' +91 98470 00000 ')
        ..setPassword('secret');

      await c.login();

      expect(h.repo.phoneNumber, '+919847000000');
      expect(h.repo.username, isNull);
    });

    test('surrounding whitespace is trimmed off a username', () async {
      final h = _harness();
      final c = h.container.read(authControllerProvider.notifier)
        ..setIdentifier('  sharma  ')
        ..setPassword('secret');

      await c.login();

      expect(h.repo.username, 'sharma');
    });

    test('a short username is allowed — only the server knows if it exists', () async {
      final h = _harness();
      final c = h.container.read(authControllerProvider.notifier)
        ..setIdentifier('sh')
        ..setPassword('secret');

      await c.login();

      expect(h.repo.calls, 1);
      expect(h.repo.username, 'sh');
    });

    test('a half-typed phone number is refused before any request', () async {
      final h = _harness();
      final c = h.container.read(authControllerProvider.notifier)
        ..setIdentifier('98470')
        ..setPassword('secret');

      await c.login();

      expect(h.repo.calls, 0);
      expect(
        h.container.read(authControllerProvider).identifierError,
        isNotNull,
      );
    });

    test('a blank field is refused before any request', () async {
      final h = _harness();
      final c = h.container.read(authControllerProvider.notifier)
        ..setIdentifier('   ')
        ..setPassword('secret');

      await c.login();

      expect(h.repo.calls, 0);
      expect(
        h.container.read(authControllerProvider).identifierError,
        isNotNull,
      );
    });
  });

  group('the OTP screens stay phone-only', () {
    test('a username cannot request an OTP', () {
      final h = _harness();
      h.container.read(authControllerProvider.notifier).setIdentifier('sharma');

      h.container.read(authControllerProvider.notifier).sendOtp();

      expect(
        h.container.read(authControllerProvider).identifierError,
        'ഒ.ടി.പി-ക്ക് ഫോൺ നമ്പർ നൽകുക',
      );
    });

    test('a username does not prefill the OTP phone field', () {
      const withUsername = AuthState(identifier: 'sharma');
      const withPhone = AuthState(identifier: '9847000000');

      expect(withUsername.phonePrefill, '');
      expect(withPhone.phonePrefill, '9847000000');
    });
  });

  group('looksLikePhone', () {
    test('reads digits and phone punctuation as a number', () {
      expect(looksLikePhone('9847000000'), isTrue);
      expect(looksLikePhone('+91 98470-00000'), isTrue);
      expect(looksLikePhone('(0484) 2345678'), isTrue);
    });

    test('reads anything with a letter as a username', () {
      expect(looksLikePhone('sharma'), isFalse);
      expect(looksLikePhone('sharma123'), isFalse);
      expect(looksLikePhone('9847a'), isFalse);
    });

    test('is false for blank and for punctuation with no digits', () {
      expect(looksLikePhone(''), isFalse);
      expect(looksLikePhone('   '), isFalse);
      expect(looksLikePhone('+-()'), isFalse);
    });
  });
}
