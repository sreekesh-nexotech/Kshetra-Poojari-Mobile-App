import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kshetra_poojari/core/error/failure.dart';
import 'package:kshetra_poojari/core/network/network_exceptions.dart';

ApiException _err(int code, String message, {String? refundId}) =>
    ApiException.fromResponse(code, {'error': message, 'refund_id': ?refundId});

void main() {
  group('ApiException body parsing', () {
    test('reads the app views\' {"error": …} shape', () {
      final e = ApiException.fromResponse(400, {'error': 'Invalid input'});
      expect(e.message, 'Invalid input');
    });

    test('reads DRF\'s own {"detail": …} shape for RBAC denials', () {
      final e = ApiException.fromResponse(403, {
        'detail': 'You do not have permission to perform this action.',
      });
      expect(e.message, contains('do not have permission'));
    });

    test('carries serializer details through for logging', () {
      final e = ApiException.fromResponse(400, {
        'error': 'Invalid input',
        'details': {
          'pooja_status': ['not a valid choice'],
        },
      });
      expect(e.details, isNotNull);
      expect(e.details!['pooja_status'], isNotEmpty);
    });

    test('falls back rather than throwing on an unrecognised body', () {
      final e = ApiException.fromResponse(500, const {});
      expect(e.message, 'Something went wrong');
    });
  });

  group('pooja.md §10 — every row maps to the right verdict', () {
    test('400 "are not on order" is a stale list', () {
      expect(
        _err(400, 'Bookings [9052] are not on order 4182').isStaleOrder,
        isTrue,
      );
    });

    test('400 "already cancelled" is a stale list', () {
      expect(
        _err(
          400,
          'Cannot modify pooja_status. Order is already cancelled',
        ).isStaleOrder,
        isTrue,
      );
    });

    test('400 "No active bookings" is a stale list', () {
      expect(_err(400, 'No active bookings to cancel').isStaleOrder, isTrue);
    });

    test('404 is a stale list', () {
      expect(_err(404, 'Pooja order not found').isStaleOrder, isTrue);
    });

    test('400 "Refund already in progress" is NOT stale — do not retry', () {
      final e = _err(400, 'Refund already in progress: pending');
      expect(e.isStaleOrder, isFalse);
      expect(Failure.from(e).action, FailureAction.none);
    });

    test('403 "assigned to another poojari" is its own verdict', () {
      final e = _err(403, 'Bookings [9052] are assigned to another poojari');
      expect(e.isAssignedToSomeoneElse, isTrue);
      expect(Failure.from(e).action, FailureAction.refresh);
    });

    test('429 throttle is flagged so polling can back off', () {
      expect(ApiException.fromResponse(429, const {}).isThrottled, isTrue);
    });

    test('500 WITH a refund id needs manual reconciliation, never a retry', () {
      final e = _err(
        500,
        'Refund was initiated but the database update failed',
        refundId: 'rfnd_Nx1',
      );
      expect(e.needsManualReconciliation, isTrue);

      final f = Failure.from(e);
      expect(f.action, FailureAction.callTheOffice);
      // The poojari must be able to read the id out to the office.
      expect(f.refundId, 'rfnd_Nx1');
      expect(f.message, contains('rfnd_Nx1'));
    });

    test('500 WITHOUT a refund id is an ordinary failure', () {
      final e = _err(500, 'Failed to initiate refund: gateway down');
      expect(e.needsManualReconciliation, isFalse);
      expect(Failure.from(e).action, FailureAction.none);
    });
  });

  group('403 is ambiguous — the cookie jar disambiguates it', () {
    final denied = ApiException.fromResponse(403, {
      'detail': 'You do not have permission to perform this action.',
    });

    test('with a session cookie it means the permission is missing', () {
      final f = Failure.from(denied, hasSession: true);
      expect(f.action, FailureAction.signOut);
      expect(f.message, contains('അനുമതിയില്ല'));
    });

    test('without one it means the session expired', () {
      final f = Failure.from(denied, hasSession: false);
      expect(f.action, FailureAction.signOut);
      expect(f.message, contains('സെഷൻ കാലഹരണപ്പെട്ടു'));
    });
  });

  group('transport failures', () {
    final req = RequestOptions(path: '/api/poojari/pooja-management/');

    test('a connect timeout does not read as signed out', () {
      final f = Failure.from(
        DioException(
          requestOptions: req,
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(f.action, FailureAction.none);
      expect(f.isSignedOut, isFalse);
    });

    test('no connectivity reads as no internet', () {
      final f = Failure.from(
        DioException(
          requestOptions: req,
          type: DioExceptionType.connectionError,
          error: const SocketException('failed'),
        ),
      );
      expect(f.message, contains('ഇന്റർനെറ്റ്'));
      expect(f.isSignedOut, isFalse);
    });

    test('an unknown throwable still yields readable copy', () {
      expect(Failure.from(Exception('boom')).message, isNotEmpty);
    });
  });
}
