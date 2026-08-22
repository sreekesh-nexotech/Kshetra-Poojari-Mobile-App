import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/device/location_gate.dart';
import '../../core/widgets/ks_block_dialog.dart';
import '../../core/widgets/ks_toast.dart';
import '../../core/widgets/navbar.dart';
import '../../features/dashboard/application/providers/attendance_controller.dart';

/// Hosts the three bottom-nav tabs (home / pooja / account) with the design's
/// [KsBottomNav], the global [KsToastHost], and the attendance gate that blocks
/// the pooja tab until check-in.
class KsNavShell extends ConsumerWidget {
  const KsNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const int _poojaIndex = 1;

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    if (index == _poojaIndex && !ref.read(isCheckedInProvider)) {
      showKsBlockDialog(
        context,
        title: GateCopy.notCheckedInTitle,
        message: GateCopy.notCheckedInMessage,
      );
      return;
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Scaffold(
          body: navigationShell,
          bottomNavigationBar: KsBottomNav(
            currentIndex: navigationShell.currentIndex,
            onTap: (i) => _onTap(context, ref, i),
          ),
        ),
        const KsToastHost(),
      ],
    );
  }
}
