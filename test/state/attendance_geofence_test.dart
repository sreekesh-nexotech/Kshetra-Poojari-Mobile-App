import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kshetra_poojari/core/device/location_service.dart';
import 'package:kshetra_poojari/core/network/network_exceptions.dart';
import 'package:kshetra_poojari/features/dashboard/application/providers/attendance_controller.dart';
import 'package:kshetra_poojari/features/dashboard/application/providers/dashboard_repository_provider.dart';
import 'package:kshetra_poojari/features/dashboard/application/providers/temple_location_controller.dart';
import 'package:kshetra_poojari/features/dashboard/application/states/attendance_state.dart';
import 'package:kshetra_poojari/features/dashboard/application/states/check_in_result.dart';
import 'package:kshetra_poojari/features/dashboard/application/states/temple_location_state.dart';
import 'package:kshetra_poojari/features/dashboard/domain/entities/temple_location.dart';

import '../support/fake_dashboard_repository.dart';

const _site = TempleLocation(
  id: 2,
  name: 'Main Temple',
  latitude: 10.123456,
  longitude: 76.654321,
  radiusMeters: 200,
);

const _siteJson = {
  'id': 2,
  'name': 'Main Temple',
  'latitude': '10.123456',
  'longitude': '76.654321',
  'radius_meters': 50,
};

({
  ProviderContainer container,
  FakeDashboardRepository repo,
  FakeLocationService gps,
})
_harness({
  TempleLocation? site = _site,
  Object? siteError,
  Object? markError,
  LocationDenial denial = LocationDenial.none,
  DeviceFix? fix = const DeviceFix(latitude: 10.123456, longitude: 76.654321),
  double metres = 0,
}) {
  final repo = FakeDashboardRepository(
    site: site,
    siteError: siteError,
    markError: markError,
  );
  final gps = FakeLocationService(denial: denial, fix: fix, metres: metres);
  final container = ProviderContainer(
    overrides: [
      dashboardRepositoryProvider.overrideWithValue(repo),
      locationServiceProvider.overrideWithValue(gps),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, repo: repo, gps: gps);
}

Future<CheckInResult> _checkIn(ProviderContainer c) =>
    c.read(attendanceControllerProvider.notifier).checkIn('06:05 AM');

void main() {
  group('inside the radius', () {
    test(
      'marks, sends 6-decimal string coordinates, and flips the card',
      () async {
        final h = _harness(metres: 12);

        final result = await _checkIn(h.container);

        expect(result.ok, isTrue);
        expect(h.repo.markCalls.single.latitude, '10.123456');
        expect(h.repo.markCalls.single.longitude, '76.654321');
        expect(
          h.container.read(attendanceControllerProvider).checkInAt,
          '06:05 AM',
        );
        expect(h.container.read(isCheckedInProvider), isTrue);
      },
    );

    test('exactly on the radius still counts as inside', () async {
      final h = _harness(metres: 200);
      expect((await _checkIn(h.container)).ok, isTrue);
    });
  });

  group('outside the radius — the pre-check refuses without sending (§5)', () {
    test('no request is made, and the distance is reported back', () async {
      final h = _harness(metres: 850);

      final result = await _checkIn(h.container);

      expect(result.block, CheckInBlock.outsidePremises);
      expect(result.distanceMeters, 850);
      expect(result.radiusMeters, 200);
      // The doc's flow is explicit: measure first, and if it fails, send
      // nothing at all.
      expect(h.repo.markCalls, isEmpty);
      // A refused mark must never look like a marked one.
      expect(h.container.read(attendanceControllerProvider).started, isFalse);
    });

    test(
      'the message names both distances rather than just saying no',
      () async {
        final h = _harness(metres: 850);
        final message = (await _checkIn(h.container)).message;

        expect(message, contains('850 മീറ്റർ'));
        expect(message, contains('200 മീറ്റർ'));
      },
    );

    test('a far-away distance reads in kilometres', () async {
      final h = _harness(metres: 178773);
      expect((await _checkIn(h.container)).message, contains('178.8 കി.മീ'));
    });
  });

  group('the server overrules the pre-check', () {
    test('a 403 after a passing local check is still handled', () async {
      // Our own check said 12 m; the server says 178 km. It wins.
      final h = _harness(
        metres: 12,
        markError: ApiException.fromResponse(403, {
          'error': 'Outside temple premises',
          'distance_meters': 178773,
          'radius_meters': 50,
          'location': _siteJson,
        }),
      );

      final result = await _checkIn(h.container);

      expect(result.block, CheckInBlock.outsidePremises);
      expect(result.distanceMeters, 178773);
      expect(result.radiusMeters, 50);
      expect(h.container.read(attendanceControllerProvider).started, isFalse);
    });

    test(
      'the 403 body replaces the cached site, without a second fetch',
      () async {
        final h = _harness(
          metres: 12,
          markError: ApiException.fromResponse(403, {
            'error': 'Outside temple premises',
            'distance_meters': 900,
            'radius_meters': 50,
            'location': _siteJson,
          }),
        );

        await _checkIn(h.container);

        // Adopted from the response, so the next pre-check uses the narrowed
        // radius the office just set — and it cost no extra request.
        expect(
          h.container
              .read(templeLocationControllerProvider)
              .location!
              .radiusMeters,
          50,
        );
        expect(h.repo.siteCalls, 1);
      },
    );

    test('a 409 reports a missing configuration, not a GPS problem', () async {
      final h = _harness(
        metres: 12,
        markError: ApiException.fromResponse(409, {
          'error': 'No temple location configured',
          'detail': 'Ask the temple office to set up the attendance location.',
        }),
      );

      final result = await _checkIn(h.container);

      expect(result.block, CheckInBlock.noTempleLocation);
      expect(result.message, contains('ക്ഷേത്ര ഓഫീസ'));
    });

    test('a 400 about the coordinates reads as an unusable fix', () async {
      final h = _harness(
        metres: 12,
        markError: ApiException.fromResponse(400, {
          'error': 'Invalid input',
          'details': {
            'latitude': ['Location is required to mark attendance for today.'],
          },
        }),
      );

      expect((await _checkIn(h.container)).block, CheckInBlock.fixUnavailable);
    });

    test('an unrelated failure stays an ordinary failure toast', () async {
      final h = _harness(
        metres: 12,
        markError: ApiException.fromResponse(500, const {}),
      );

      final result = await _checkIn(h.container);
      expect(result.block, CheckInBlock.failed);
      expect(result.failure, isNotNull);
    });
  });

  group('no site configured (§2)', () {
    test('a null location blocks the mark — it is not a free pass', () async {
      final h = _harness(site: null);

      final result = await _checkIn(h.container);

      expect(result.block, CheckInBlock.noTempleLocation);
      expect(h.repo.markCalls, isEmpty);
      expect(h.container.read(templeLocationUnconfiguredProvider), isTrue);
    });

    test('a failed fetch is "unknown", never "unconfigured"', () async {
      final h = _harness(siteError: Exception('offline'));

      final result = await _checkIn(h.container);

      expect(result.block, CheckInBlock.failed);
      // Confusing the two would grey the slide out permanently over one
      // dropped request.
      expect(h.container.read(templeLocationUnconfiguredProvider), isFalse);
      expect(
        h.container.read(templeLocationControllerProvider).status,
        TempleLocationStatus.unavailable,
      );
    });
  });

  group('the device cannot answer', () {
    test(
      'location switched off blocks, and offers the settings screen',
      () async {
        final h = _harness(denial: LocationDenial.serviceDisabled);

        final result = await _checkIn(h.container);

        expect(result.block, CheckInBlock.locationOff);
        expect(result.opensSettings, isTrue);
        expect(h.repo.markCalls, isEmpty);

        await h.container
            .read(attendanceControllerProvider.notifier)
            .openSettingsFor(result);
        expect(h.gps.settingsOpened.single, LocationDenial.serviceDisabled);
      },
    );

    test(
      'a plain denial is re-askable, so it offers no settings button',
      () async {
        final result = await _checkIn(
          _harness(denial: LocationDenial.denied).container,
        );

        expect(result.block, CheckInBlock.permissionDenied);
        expect(result.opensSettings, isFalse);
      },
    );

    test('a permanent denial can only be undone in settings', () async {
      final result = await _checkIn(
        _harness(denial: LocationDenial.deniedForever).container,
      );

      expect(result.block, CheckInBlock.permissionBlocked);
      expect(result.opensSettings, isTrue);
    });

    test('permission granted but no fix is its own state', () async {
      final h = _harness(fix: null);

      expect((await _checkIn(h.container)).block, CheckInBlock.fixUnavailable);
      expect(h.repo.markCalls, isEmpty);
    });
  });

  test('the site is fetched once per session, not once per mark', () async {
    final h = _harness(metres: 12);

    await _checkIn(h.container);
    await _checkIn(h.container);

    expect(h.repo.siteCalls, 1);
  });

  group('while the fix is being taken', () {
    test('the slider is told it is busy, and released either way', () async {
      final h = _harness();
      final gate = h.gps.fixGate = Completer<void>();
      AttendanceState state() => h.container.read(attendanceControllerProvider);

      expect(state().checkingIn, isFalse);
      final pending = _checkIn(h.container);
      await Future<void>.delayed(Duration.zero);

      expect(state().checkingIn, isTrue);
      expect(state().slideLabel, 'ലൊക്കേഷൻ എടുക്കുന്നു…');

      gate.complete();
      expect((await pending).ok, isTrue);
      expect(state().checkingIn, isFalse);
    });

    test('a refusal also releases it', () async {
      final h = _harness(metres: 850);
      final gate = h.gps.fixGate = Completer<void>();
      final pending = _checkIn(h.container);
      await Future<void>.delayed(Duration.zero);
      expect(h.container.read(attendanceControllerProvider).checkingIn, isTrue);

      gate.complete();
      expect((await pending).block, CheckInBlock.outsidePremises);
      expect(
        h.container.read(attendanceControllerProvider).checkingIn,
        isFalse,
      );
    });

    test('a second slide is dropped, not queued', () async {
      final h = _harness();
      final gate = h.gps.fixGate = Completer<void>();
      final first = _checkIn(h.container);
      await Future<void>.delayed(Duration.zero);

      expect((await _checkIn(h.container)).block, CheckInBlock.busy);

      gate.complete();
      expect((await first).ok, isTrue);
      // One gesture, one mark.
      expect(h.repo.markCalls, hasLength(1));
    });
  });
}
