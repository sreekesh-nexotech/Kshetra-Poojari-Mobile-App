import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
///
/// Also owns the hardware/gesture back button here: every tab is the root of
/// its own branch navigator with nothing beneath it, so without this the
/// system back button would exit the app straight from the pooja or account
/// tab instead of returning to home first (see `_onBack`).
class KsNavShell extends ConsumerStatefulWidget {
  const KsNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const int _homeIndex = 0;
  static const int _poojaIndex = 1;

  @override
  ConsumerState<KsNavShell> createState() => _KsNavShellState();
}

class _KsNavShellState extends ConsumerState<KsNavShell> {
  /// Set on the first back press from the home tab; a second press within
  /// [_exitWindow] actually exits. `null` once the window has lapsed.
  DateTime? _armedAt;
  static const _exitWindow = Duration(seconds: 2);

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    if (index == KsNavShell._poojaIndex && !ref.read(isCheckedInProvider)) {
      showKsBlockDialog(
        context,
        title: GateCopy.notCheckedInTitle,
        message: GateCopy.notCheckedInMessage,
      );
      return;
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  /// Not on home → jump to home instead of exiting. On home → require a
  /// second press within [_exitWindow] (with a toast on the first) before
  /// actually letting the app close.
  void _onBack() {
    if (widget.navigationShell.currentIndex != KsNavShell._homeIndex) {
      widget.navigationShell.goBranch(KsNavShell._homeIndex);
      return;
    }

    final now = DateTime.now();
    if (_armedAt != null && now.difference(_armedAt!) <= _exitWindow) {
      SystemNavigator.pop();
      return;
    }
    _armedAt = now;
    ref
        .read(toastProvider.notifier)
        .show('വീണ്ടും ബാക്ക് അമർത്തിയാൽ ആപ്പ് അടയും');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBack();
      },
      child: Stack(
        children: [
          Scaffold(
            body: widget.navigationShell,
            bottomNavigationBar: KsBottomNav(
              currentIndex: widget.navigationShell.currentIndex,
              onTap: (i) => _onTap(context, ref, i),
            ),
          ),
          const KsToastHost(),
        ],
      ),
    );
  }
}
