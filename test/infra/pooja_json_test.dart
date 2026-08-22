import 'package:flutter_test/flutter_test.dart';
import 'package:kshetra_poojari/features/pooja/domain/entities/booking.dart';
import 'package:kshetra_poojari/features/pooja/domain/entities/pooja_category.dart';
import 'package:kshetra_poojari/features/pooja/domain/entities/pooja_order.dart';
import 'package:kshetra_poojari/features/pooja/domain/entities/status_update.dart';

import '../support/fixtures.dart';

void main() {
  group('TodaysWork — the list payload', () {
    late TodaysWork work;

    setUp(() => work = TodaysWork.fromJson(loadFixture('todays_work.json')));

    test('parses the god and its Malayalam name', () {
      expect(work.category.id, 3);
      expect(work.category.name, 'ഗണപതി');
    });

    test('an order holds several bookings — they are not the same thing', () {
      expect(work.orders, hasLength(3));
      expect(work.orders.first.id, 4182);
      expect(work.orders.first.bookings, hasLength(3));
      expect(work.orders.first.bookings.map((b) => b.id), [9051, 9052, 9053]);
    });

    test('money arrives as a String and must parse to a number', () {
      // "750.00", not 750.0 — DRF renders Decimal as a String.
      expect(work.orders.first.total, 750.00);
      expect(work.orders.first.bookings.first.price, 250.00);
    });

    test('nakshtram is read under its misspelled wire name', () {
      // Spelled without the `a`. "Fixing" it makes this silently null.
      expect(work.orders.first.bookings[0].nakshatram, 'തിരുവോണം');
      expect(work.orders.first.bookings[1].nakshatram, 'ഉത്രം');
    });

    test('a counter walk-in has no devotee and does not crash', () {
      final walkIn = work.orders.first.bookings[2];
      expect(walkIn.devotee, isNull);
      expect(walkIn.nakshatram, isNull);
    });

    test('poojari_id null means unassigned, up for grabs', () {
      expect(work.orders.first.bookings[0].poojariId, isNull);
      expect(work.orders.first.bookings[0].isUnassigned, isTrue);
      expect(work.orders.first.bookings[1].poojariId, 41);
      expect(work.orders.first.bookings[1].isUnassigned, isFalse);
    });

    test('status and pooja_status are two different vocabularies', () {
      final refunded = work.orders[2].bookings.single;
      // A refunded booking: money state refunded, execution state cancelled.
      expect(refunded.status, 'refunded');
      expect(refunded.poojaStatus, PoojaStatus.cancelled);
      expect(refunded.isSettled, isTrue);
    });

    test('canMark blocks settled and already-cancelled rows', () {
      expect(work.orders.first.bookings[0].canMark, isTrue);
      expect(
        work.orders.first.bookings[2].canMark,
        isTrue,
      ); // completed, undoable
      expect(work.orders[2].bookings.single.canMark, isFalse); // refunded
      expect(work.orders[2].markable, isEmpty);
    });

    test('pooja_date is a plain date with no time', () {
      expect(work.orders.first.bookings.first.poojaDate, DateTime(2026, 8, 22));
    });

    test('special_pooja and the order rollup come through', () {
      expect(work.orders[1].specialPooja, isTrue);
      expect(work.orders[1].poojaStatus, PoojaStatus.completed);
      expect(work.orders[1].status, 'cod');
    });
  });

  group('a `main`-branch response still parses', () {
    test(
      'missing pooja_status and poojari_id fall back, they do not throw',
      () {
        final work = TodaysWork.fromJson(
          loadFixture('todays_work_main_shape.json'),
        );
        final booking = work.orders.single.bookings.single;

        expect(booking.poojaStatus, PoojaStatus.pending);
        expect(booking.poojariId, isNull);
        expect(booking.nakshatram, 'തിരുവോണം');
      },
    );
  });

  group('PoojaCategory', () {
    test('catalogue rows carry sort_order; poojari rows may not', () {
      final rows = (loadFixture('poojacategory.json')['results'] as List)
          .cast<Map<String, dynamic>>()
          .map(PoojaCategory.fromJson)
          .toList();

      expect(rows, hasLength(4));
      expect(rows.first.sortOrder, 3);
      expect(rows.first.poojasCount, 4);

      // The narrower poojari shape has neither, and must not throw.
      final narrow = PoojaCategory.fromJson(
        loadFixture('todays_work.json')['category'] as Map<String, dynamic>,
      );
      expect(narrow.sortOrder, isNull);
      expect(narrow.poojasCount, isNull);
      expect(narrow.mediaUrl, isNotNull);
    });
  });

  group('StatusUpdateResult — three different success bodies', () {
    test('completed carries bookings_updated and per-line statuses', () {
      final r = StatusUpdateResult.fromJson(
        loadFixture('patch_completed.json'),
      );

      expect(r.bookingsUpdated, 2);
      expect(r.refundStarted, isFalse);
      // The rollup is the server's, and it is still pending because line
      // 9053 has not been performed.
      expect(r.orderPoojaStatus, PoojaStatus.pending);
      expect(r.lineStatuses[9051], PoojaStatus.completed);
      expect(r.lineStatuses[9052], PoojaStatus.completed);
      // The response covers EVERY line on the order, including another god's.
      expect(r.lineStatuses[9053], PoojaStatus.pending);
      expect(r.lineStatuses, hasLength(3));
    });

    test('an unpaid cancel omits bookings_updated entirely', () {
      final r = StatusUpdateResult.fromJson(
        loadFixture('patch_cancelled_cod.json'),
      );
      expect(r.bookingsUpdated, isNull);
      expect(r.refundStarted, isFalse);
      expect(r.orderPoojaStatus, PoojaStatus.cancelled);
    });

    test('a paid cancel surfaces the refund id and amount', () {
      final r = StatusUpdateResult.fromJson(
        loadFixture('patch_cancelled_refund.json'),
      );
      expect(r.refundStarted, isTrue);
      expect(r.refundId, 'rfnd_Nx7Kq2');
      expect(r.refundAmount, 250.00);
      // Only the cancelled booking is refunded; the order still stands.
      expect(r.orderPoojaStatus, PoojaStatus.pending);
      expect(r.lineStatuses[9051], PoojaStatus.cancelled);
    });
  });
}
