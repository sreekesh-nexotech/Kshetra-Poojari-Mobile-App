import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kshetra_poojari/features/pooja/application/models/god.dart';
import 'package:kshetra_poojari/features/pooja/application/models/pooja_task.dart';
import 'package:kshetra_poojari/features/pooja/application/providers/pooja_data_providers.dart';
import 'package:kshetra_poojari/features/pooja/application/providers/pooja_list_controller.dart';
import 'package:kshetra_poojari/features/pooja/application/providers/pooja_repository_provider.dart';
import 'package:kshetra_poojari/features/pooja/application/states/pooja_list_state.dart';

import '../support/fake_pooja_repository.dart';

const _gods = [GodVm(id: 3, name: 'ഗണപതി')];

/// Three orders under one god: 4182 has two bookings, 4190 one, 4195 two.
List<PoojaTaskVm> _tasks() => const [
  PoojaTaskVm(
    id: 9051,
    orderId: 4182,
    categoryId: 3,
    poojaName: 'ഗണപതി ഹോമം',
    person: 'Ramesh',
    nakshatra: 'അശ്വതി',
    price: 250,
  ),
  PoojaTaskVm(
    id: 9052,
    orderId: 4182,
    categoryId: 3,
    poojaName: 'ഗണപതി ഹോമം',
    person: 'Lakshmi',
    nakshatra: 'ഉത്രം',
    price: 250,
  ),
  PoojaTaskVm(
    id: 9101,
    orderId: 4190,
    categoryId: 3,
    poojaName: 'ഭഗവതി സേവ',
    person: 'Suma',
    nakshatra: 'രോഹിണി',
    price: 300,
  ),
  PoojaTaskVm(
    id: 9120,
    orderId: 4195,
    categoryId: 3,
    poojaName: 'മൃത്യുഞ്ജയ ഹോമം',
    person: 'Anil',
    nakshatra: 'ഭരണി',
    price: 500,
  ),
  PoojaTaskVm(
    id: 9121,
    orderId: 4195,
    categoryId: 3,
    poojaName: 'മൃത്യുഞ്ജയ ഹോമം',
    person: 'Deepa',
    nakshatra: 'ചോതി',
    price: 500,
  ),
  // Already refunded: the server will not move it, so it must never be sent.
  PoojaTaskVm(
    id: 9130,
    orderId: 4195,
    categoryId: 3,
    poojaName: 'മൃത്യുഞ്ജയ ഹോമം',
    person: 'Vinod',
    nakshatra: 'മകം',
    price: 500,
    status: TaskStatus.cancelled,
    canMark: false,
  ),
];

void main() {
  late ProviderContainer container;
  late FakePoojaRepository repo;
  late PoojaListController controller;

  setUp(() {
    repo = FakePoojaRepository();
    container = ProviderContainer(
      overrides: [
        godsSeedProvider.overrideWithValue(_gods),
        poojaSeedProvider.overrideWithValue(_tasks()),
        poojaRepositoryProvider.overrideWithValue(repo),
      ],
    );
    controller = container.read(poojaListControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  test(
    'a selection spanning three orders becomes exactly three PATCHes',
    () async {
      for (final id in [9051, 9052, 9101, 9120, 9121]) {
        controller.toggleTask(id);
      }

      await controller.applyBulk();

      expect(repo.markCalls, hasLength(3));

      final byOrder = {
        for (final call in repo.markCalls) call.orderId: call.bookingIds,
      };
      expect(byOrder.keys.toSet(), {4182, 4190, 4195});
      expect(byOrder[4182], [9051, 9052]);
      expect(byOrder[4190], [9101]);
      expect(byOrder[4195], [9120, 9121]);
    },
  );

  test('no PATCH is ever sent without order_line_ids', () async {
    for (final id in [9051, 9101]) {
      controller.toggleTask(id);
    }
    await controller.applyBulk();

    // Omitting the key server-side moves EVERY booking on the order. Every
    // call must name its lines.
    for (final call in repo.markCalls) {
      expect(call.bookingIds, isNotEmpty);
    }
  });

  test('the line sets are disjoint — no booking is moved twice', () async {
    for (final id in [9051, 9052, 9101, 9120, 9121]) {
      controller.toggleTask(id);
    }
    await controller.applyBulk();

    final all = repo.markCalls.expand((c) => c.bookingIds).toList();
    expect(all.toSet().length, all.length);
    expect(all.length, 5);
  });

  test('an unmarkable booking is dropped rather than sent', () async {
    // Select it directly — the UI would not offer it, but the guard belongs
    // in the controller too.
    controller.toggleTask(9120);
    controller.toggleTask(9130);

    await controller.applyBulk();

    expect(repo.markCalls, hasLength(1));
    expect(repo.markCalls.single.bookingIds, [9120]);
  });

  test('selecting nothing sends nothing', () async {
    final outcome = await controller.applyBulk();
    expect(repo.markCalls, isEmpty);
    expect(outcome.toast, isNotEmpty);
  });

  test('a cancel totals the refund across the selected bookings', () async {
    controller.toggleTask(9101); // 300
    controller.toggleTask(9120); // 500
    controller.openBulk(BulkMode.cancel);

    expect(controller.selectedTotal, 800);
  });

  test('the selection is cleared once the action is committed', () async {
    controller.toggleTask(9051);
    expect(container.read(poojaListControllerProvider).hasSelection, isTrue);

    await controller.applyBulk();
    expect(container.read(poojaListControllerProvider).hasSelection, isFalse);
  });
}
