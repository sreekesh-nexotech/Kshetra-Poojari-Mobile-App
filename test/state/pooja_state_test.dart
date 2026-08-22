import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kshetra_poojari/features/dashboard/application/providers/attendance_controller.dart';
import 'package:kshetra_poojari/features/dashboard/application/providers/home_providers.dart';
import 'package:kshetra_poojari/features/pooja/application/providers/pooja_data_providers.dart';
import 'package:kshetra_poojari/features/pooja/application/providers/pooja_list_controller.dart';
import 'package:kshetra_poojari/features/pooja/application/states/pooja_list_state.dart';

import 'package:kshetra_poojari/features/pooja/application/providers/pooja_repository_provider.dart';

import '../support/fake_pooja_repository.dart';
import '../support/fixture_overrides.dart';

void main() {
  late ProviderContainer container;
  late FakePoojaRepository repo;

  setUp(() {
    repo = FakePoojaRepository();
    container = ProviderContainer(
      overrides: [
        ...kFixtureOverrides,
        poojaRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });
  tearDown(() => container.dispose());

  test('seed matches the design demo dataset (35 tasks, 5 done, 14%)', () {
    final tasks = container.read(poojaTasksControllerProvider);
    expect(tasks.length, 35);
    expect(tasks.where((t) => t.isDone).length, 5);

    final progress = container.read(homeProgressProvider);
    expect(progress.percentInt, 14);
    expect(progress.fracLabel, '5/35');
  });

  test('completing a whole group updates progress and the home tally', () async {
    final listCtrl = container.read(poojaListControllerProvider.notifier);

    // First pending group under ശ്രീ ഗണപതി / പെൻഡിംഗ് tab = ഗണപതി ഹോമം (5 tasks).
    final firstGroup = container.read(poojaGroupsProvider).first;
    expect(firstGroup.name, 'ഗണപതി ഹോമം');
    expect(firstGroup.pendingIds.length, 5);

    listCtrl.toggleGroup(firstGroup.pendingIds);
    expect(container.read(poojaListControllerProvider).selectedCount, 5);

    final outcome = await listCtrl.applyBulk();
    expect(outcome.toast, contains('പൂർത്തിയായി'));
    expect(outcome.needsRefresh, isFalse);

    // The whole group sits on one order, so it is one PATCH — and it names
    // its lines rather than letting the server move the entire order.
    expect(repo.markCalls, hasLength(1));
    expect(repo.markCalls.single.bookingIds, firstGroup.pendingIds);
    expect(repo.markCalls.single.status.name, 'completed');

    // 5 (already done) + 5 (just completed) = 10 / 35 = 29%.
    final progress = container.read(homeProgressProvider);
    expect(progress.fracLabel, '10/35');
    expect(progress.percentInt, 29);

    // Selection cleared after applying.
    expect(container.read(poojaListControllerProvider).hasSelection, isFalse);
  });

  test('bulk cancel cancels the bookings without completing them', () async {
    final listCtrl = container.read(poojaListControllerProvider.notifier);
    final group = container.read(poojaGroupsProvider).first;
    listCtrl.toggleGroup(group.pendingIds);
    listCtrl.openBulk(BulkMode.cancel);
    final outcome = await listCtrl.applyBulk();

    expect(outcome.toast, contains('കാൻസൽ'));
    expect(repo.markCalls.single.status.name, 'cancelled');

    final tasks = container.read(poojaTasksControllerProvider);
    expect(tasks.where((t) => t.isCancelled).length, group.pendingIds.length);
    // Cancelled tasks are neither pending nor counted as done.
    expect(container.read(homeProgressProvider).fracLabel, '5/35');
  });

  test('undo returns a completed task to pending', () async {
    final listCtrl = container.read(poojaListControllerProvider.notifier);
    final tasksCtrl = container.read(poojaTasksControllerProvider.notifier);
    // Ids are server order-line ids now, so pick one rather than assume it.
    final pending = container
        .read(poojaTasksControllerProvider)
        .firstWhere((t) => t.isPending)
        .id;

    tasksCtrl.bulkComplete([pending], '07:00 AM');
    expect(container.read(homeProgressProvider).fracLabel, '6/35');

    await listCtrl.undo(pending);
    expect(container.read(homeProgressProvider).fracLabel, '5/35');
    expect(repo.markCalls.single.status.name, 'pending');
  });

  test('tally flips to today-summary after check-out', () {
    final attCtrl = container.read(attendanceControllerProvider.notifier);
    expect(container.read(homeTallyProvider).title, 'ഇന്ന് ചെയ്യാനുള്ളവ');

    attCtrl.checkIn('06:05 AM');
    attCtrl.checkOut('08:10 PM');
    expect(container.read(isCheckedOutProvider), isTrue);
    expect(container.read(homeTallyProvider).title, 'ഇന്നത്തെ സമ്മറി');
  });

  test('switching deity resets the tab and selection', () {
    final listCtrl = container.read(poojaListControllerProvider.notifier);
    listCtrl.selectTab(2);
    final g = container.read(poojaGroupsProvider).first;
    listCtrl.toggleGroup(g.pendingIds);
    expect(container.read(poojaListControllerProvider).hasSelection, isTrue);

    listCtrl.selectGod(5);
    final state = container.read(poojaListControllerProvider);
    expect(state.selectedCategoryId, 5);
    expect(state.activeTab, 0);
    expect(state.hasSelection, isFalse);
  });
}
