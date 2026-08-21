import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kshetra_poojari/features/dashboard/application/providers/attendance_controller.dart';
import 'package:kshetra_poojari/features/dashboard/application/providers/home_providers.dart';
import 'package:kshetra_poojari/features/pooja/application/providers/pooja_data_providers.dart';
import 'package:kshetra_poojari/features/pooja/application/providers/pooja_list_controller.dart';
import 'package:kshetra_poojari/features/pooja/application/states/pooja_list_state.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('seed matches the design demo dataset (35 tasks, 5 done, 14%)', () {
    final tasks = container.read(poojaTasksControllerProvider);
    expect(tasks.length, 35);
    expect(tasks.where((t) => t.isDone).length, 5);

    final progress = container.read(homeProgressProvider);
    expect(progress.percentInt, 14);
    expect(progress.fracLabel, '5/35');
  });

  test('completing a whole group updates progress and the home tally', () {
    final listCtrl = container.read(poojaListControllerProvider.notifier);

    // First pending group under ശ്രീ ഗണപതി / പെൻഡിംഗ് tab = ഗണപതി ഹോമം (5 tasks).
    final firstGroup = container.read(poojaGroupsProvider).first;
    expect(firstGroup.name, 'ഗണപതി ഹോമം');
    expect(firstGroup.pendingIds.length, 5);

    listCtrl.toggleGroup(firstGroup.pendingIds);
    expect(container.read(poojaListControllerProvider).selectedCount, 5);

    final toast = listCtrl.applyBulk();
    expect(toast, contains('പൂർത്തിയായി'));

    // 5 (already done) + 5 (just completed) = 10 / 35 = 29%.
    final progress = container.read(homeProgressProvider);
    expect(progress.fracLabel, '10/35');
    expect(progress.percentInt, 29);

    // Selection cleared after applying.
    expect(container.read(poojaListControllerProvider).hasSelection, isFalse);
  });

  test('bulk cancel marks tasks cancelled (reassign) without completing', () {
    final listCtrl = container.read(poojaListControllerProvider.notifier);
    final group = container.read(poojaGroupsProvider).first;
    listCtrl.toggleGroup(group.pendingIds);
    listCtrl.openBulk(BulkMode.cancel);
    final toast = listCtrl.applyBulk();

    expect(toast, contains('റീ-അസൈൻ'));
    final tasks = container.read(poojaTasksControllerProvider);
    expect(tasks.where((t) => t.isCancelled).length, group.pendingIds.length);
    // Cancelled tasks are neither pending nor counted as done.
    expect(container.read(homeProgressProvider).fracLabel, '5/35');
  });

  test('undo returns a completed task to pending', () {
    final listCtrl = container.read(poojaListControllerProvider.notifier);
    final tasksCtrl = container.read(poojaTasksControllerProvider.notifier);
    tasksCtrl.bulkComplete([2], '07:00 AM');
    expect(container.read(homeProgressProvider).fracLabel, '6/35');

    listCtrl.undo(2);
    expect(container.read(homeProgressProvider).fracLabel, '5/35');
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

    listCtrl.selectGod('g2');
    final state = container.read(poojaListControllerProvider);
    expect(state.selectedGodId, 'g2');
    expect(state.activeTab, 0);
    expect(state.hasSelection, isFalse);
  });
}
