import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kshetra_poojari/core/network/network_exceptions.dart';
import 'package:kshetra_poojari/features/pooja/application/models/god.dart';
import 'package:kshetra_poojari/features/pooja/application/models/pooja_task.dart';
import 'package:kshetra_poojari/features/pooja/application/providers/pooja_data_providers.dart';
import 'package:kshetra_poojari/features/pooja/application/providers/pooja_list_controller.dart';
import 'package:kshetra_poojari/features/pooja/application/providers/pooja_repository_provider.dart';
import 'package:kshetra_poojari/features/pooja/application/states/pooja_list_state.dart';
import 'package:kshetra_poojari/features/pooja/domain/entities/booking.dart';
import 'package:kshetra_poojari/features/pooja/domain/entities/status_update.dart';

import '../support/fake_pooja_repository.dart';

const _gods = [GodVm(id: 3, name: 'ഗണപതി')];

PoojaTaskVm _task(int id, int orderId) => PoojaTaskVm(
  id: id,
  orderId: orderId,
  categoryId: 3,
  poojaName: 'ഗണപതി ഹോമം',
  person: 'Devotee $id',
  nakshatra: 'അശ്വതി',
  price: 250,
);

/// Order A (4182): two bookings. Order B (4190): one.
final _seed = [_task(9051, 4182), _task(9052, 4182), _task(9101, 4190)];

void main() {
  late ProviderContainer container;
  late FakePoojaRepository repo;
  late PoojaListController controller;

  List<PoojaTaskVm> tasks() => container.read(poojaTasksControllerProvider);
  PoojaTaskVm task(int id) => tasks().firstWhere((t) => t.id == id);

  setUp(() {
    repo = FakePoojaRepository();
    container = ProviderContainer(
      overrides: [
        godsSeedProvider.overrideWithValue(_gods),
        poojaSeedProvider.overrideWithValue(_seed),
        poojaRepositoryProvider.overrideWithValue(repo),
      ],
    );
    controller = container.read(poojaListControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('one order failing rolls back only its own rows', () async {
    // The back office gave order B away while the list was open.
    repo.markErrors = {
      4190: const ApiException(
        403,
        'Bookings [9101] are assigned to another poojari',
      ),
    };

    for (final id in [9051, 9052, 9101]) {
      controller.toggleTask(id);
    }
    final outcome = await controller.applyBulk();

    // Order A was accepted and stays done.
    expect(task(9051).isDone, isTrue);
    expect(task(9052).isDone, isTrue);
    // Order B reverts — undoing A too would contradict a write the server took.
    expect(task(9101).isPending, isTrue);

    expect(outcome.needsRefresh, isTrue);
    expect(outcome.toast, contains('2'));
  });

  test(
    'every order failing reverts everything and reports the error',
    () async {
      repo.markErrors = {
        4182: const ApiException(404, 'Pooja order not found'),
        4190: const ApiException(404, 'Pooja order not found'),
      };

      for (final id in [9051, 9052, 9101]) {
        controller.toggleTask(id);
      }
      final outcome = await controller.applyBulk();

      expect(tasks().every((t) => t.isPending), isTrue);
      expect(outcome.needsRefresh, isTrue);
    },
  );

  test(
    'the flip is optimistic — rows move before the server answers',
    () async {
      repo.markResults = {
        4182: StatusUpdateResult(
          message: 'ok',
          orderPoojaStatus: PoojaStatus.completed,
          orderStatus: 'confirmed',
          lineStatuses: const {9051: PoojaStatus.completed},
        ),
      };

      controller.toggleTask(9051);
      final pending = controller.applyBulk();

      // Already done, with the request still in flight.
      expect(task(9051).isDone, isTrue);
      await pending;
      expect(task(9051).isDone, isTrue);
    },
  );

  test('the server verdict wins over the optimistic guess', () async {
    // The server accepted the call but reports the line as still pending.
    repo.markResults = {
      4182: StatusUpdateResult(
        message: 'ok',
        orderPoojaStatus: PoojaStatus.pending,
        orderStatus: 'confirmed',
        lineStatuses: const {9051: PoojaStatus.pending},
      ),
    };

    controller.toggleTask(9051);
    await controller.applyBulk();

    expect(task(9051).isPending, isTrue);
  });

  test('a response mentioning other lines does not disturb them', () async {
    // The PATCH response carries EVERY line on the order, including ones we
    // never selected — applying it must not resurrect or clobber those.
    repo.markResults = {
      4182: StatusUpdateResult(
        message: 'ok',
        orderPoojaStatus: PoojaStatus.pending,
        orderStatus: 'confirmed',
        lineStatuses: const {
          9051: PoojaStatus.completed,
          9052: PoojaStatus.pending,
        },
      ),
    };

    controller.toggleTask(9051);
    await controller.applyBulk();

    expect(task(9051).isDone, isTrue);
    expect(task(9052).isPending, isTrue);
    // Untouched by this order entirely.
    expect(task(9101).isPending, isTrue);
  });

  test('a failed undo puts the row back to done', () async {
    // Complete it first.
    controller.toggleTask(9051);
    await controller.applyBulk();
    expect(task(9051).isDone, isTrue);

    repo.markErrors = {4182: const ApiException(500, 'boom')};
    final outcome = await controller.undo(9051);

    expect(task(9051).isDone, isTrue);
    expect(outcome.toast, isNotEmpty);
  });

  test('a cancel that refunds surfaces the amount, not just a tick', () async {
    repo.markResults = {
      4182: StatusUpdateResult(
        message: 'Bookings cancelled successfully. Refund has been initiated.',
        refundId: 'rfnd_Nx7Kq2',
        refundAmount: 250,
        orderPoojaStatus: PoojaStatus.pending,
        orderStatus: 'confirmed',
        lineStatuses: const {9051: PoojaStatus.cancelled},
      ),
    };

    controller.toggleTask(9051);
    controller.openBulk(BulkMode.cancel);
    final outcome = await controller.applyBulk();

    expect(task(9051).isCancelled, isTrue);
    expect(outcome.refundId, 'rfnd_Nx7Kq2');
    expect(outcome.toast, contains('റീഫണ്ട്'));
  });

  test(
    'a cancel is NOT optimistic — nothing moves until the server agrees',
    () async {
      repo.markErrors = {4182: const ApiException(500, 'gateway down')};

      controller.toggleTask(9051);
      controller.openBulk(BulkMode.cancel);
      await controller.applyBulk();

      // The cancel did not happen, so the row must not look cancelled.
      expect(task(9051).isPending, isTrue);
      expect(task(9051).isCancelled, isFalse);
    },
  );

  test('money moved but the record did not — block, do not retry', () async {
    repo.markErrors = {
      4182: const ApiException(
        500,
        'Refund was initiated but the database update failed',
        refundId: 'rfnd_Broken1',
      ),
    };

    controller.toggleTask(9051);
    controller.openBulk(BulkMode.cancel);
    final outcome = await controller.applyBulk();

    expect(outcome.needsManualReconciliation, isTrue);
    expect(outcome.unreconciledRefundId, 'rfnd_Broken1');
  });
}
