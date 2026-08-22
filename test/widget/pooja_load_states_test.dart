import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kshetra_poojari/core/error/error_view.dart';
import 'package:kshetra_poojari/core/network/network_exceptions.dart';
import 'package:kshetra_poojari/features/pooja/application/providers/pooja_repository_provider.dart';
import 'package:kshetra_poojari/features/pooja/domain/entities/booking.dart';
import 'package:kshetra_poojari/features/pooja/domain/entities/pooja_category.dart';
import 'package:kshetra_poojari/features/pooja/domain/entities/pooja_order.dart';
import 'package:kshetra_poojari/features/pooja/presentation/components/pooja_group_card.dart';
import 'package:kshetra_poojari/features/pooja/presentation/screen/pooja_list_screen.dart';

import '../support/fake_pooja_repository.dart';
import '../support/pump_screen.dart';

const _ganapathi = PoojaCategory(id: 3, name: 'ഗണപതി', sortOrder: 1);

TodaysWork _work({List<PoojaOrder> orders = const []}) =>
    TodaysWork(category: _ganapathi, orders: orders);

PoojaOrder _order(int id, List<int> lineIds) => PoojaOrder(
  id: id,
  poojaStatus: PoojaStatus.pending,
  status: 'confirmed',
  total: 250.0 * lineIds.length,
  poojaName: 'ഗണപതി ഹോമം',
  bookings: [
    for (final lineId in lineIds)
      Booking(
        id: lineId,
        status: 'confirmed',
        poojaStatus: PoojaStatus.pending,
        poojariId: null,
        poojaDate: DateTime(2026, 8, 22),
        price: 250,
        devotee: const Devotee(name: 'Ramesh'),
        nakshatram: 'അശ്വതി',
      ),
  ],
);

Future<void> _pump(WidgetTester tester, FakePoojaRepository repo) => pumpScreen(
  tester,
  const PoojaListScreen(),
  seedFixtures: false,
  overrides: [poojaRepositoryProvider.overrideWithValue(repo)],
);

void main() {
  testWidgets('a first load shows a spinner, not an empty-day message', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repo = FakePoojaRepository(
      godsResult: const [_ganapathi],
      gate: gate,
    );

    await _pump(tester, repo);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Claiming "no poojas today" while still loading would be a lie.
    expect(find.text('ഈ ലിസ്റ്റിൽ ഇന്ന് പൂജകളില്ല'), findsNothing);

    // Let the request land: the spinner gives way to the day's state.
    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('ഈ ലിസ്റ്റിൽ ഇന്ന് പൂജകളില്ല'), findsOneWidget);
  });

  testWidgets('a failed load shows the retry card, and retry refetches', (
    tester,
  ) async {
    final repo = FakePoojaRepository(
      godsResult: const [_ganapathi],
      workError: const ApiException(500, 'boom'),
    );

    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('വീണ്ടും ശ്രമിക്കുക'), findsOneWidget);

    final before = repo.workCalls.length;
    repo.workError = null;
    repo.workByCategory = {
      3: _work(
        orders: [
          _order(4182, [9051]),
        ],
      ),
    };

    await tester.tap(find.text('വീണ്ടും ശ്രമിക്കുക'));
    await tester.pumpAndSettle();

    expect(repo.workCalls.length, greaterThan(before));
    expect(find.byType(ErrorView), findsNothing);
    expect(find.byType(PoojaGroupCard), findsOneWidget);
  });

  testWidgets('an empty day shows the empty card, not an error', (
    tester,
  ) async {
    final repo = FakePoojaRepository(
      godsResult: const [_ganapathi],
      workByCategory: {3: _work()},
    );

    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('ഈ ലിസ്റ്റിൽ ഇന്ന് പൂജകളില്ല'), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('the list requests the first shrine, never a bare category', (
    tester,
  ) async {
    final repo = FakePoojaRepository(
      godsResult: const [
        PoojaCategory(id: 5, name: 'ഭഗവതി', sortOrder: 2),
        _ganapathi,
      ],
      workByCategory: {
        3: _work(
          orders: [
            _order(4182, [9051, 9052]),
          ],
        ),
      },
    );

    await _pump(tester, repo);
    await tester.pumpAndSettle();

    // sort_order 1 wins, so category 3 is fetched — and category_id is always
    // sent, because there is no "all gods" view.
    expect(repo.workCalls, [3]);
    expect(find.byType(PoojaGroupCard), findsOneWidget);
  });

  testWidgets('one card per order, one row per booking', (tester) async {
    final repo = FakePoojaRepository(
      godsResult: const [_ganapathi],
      workByCategory: {
        3: _work(
          orders: [
            _order(4182, [9051, 9052]),
            _order(4190, [9101]),
          ],
        ),
      },
    );

    await _pump(tester, repo);
    await tester.pumpAndSettle();

    // Two orders sharing one pooja name are still two cards.
    expect(find.byType(PoojaGroupCard), findsNWidgets(2));
    expect(find.text('Ramesh'), findsNWidgets(3));
  });
}
