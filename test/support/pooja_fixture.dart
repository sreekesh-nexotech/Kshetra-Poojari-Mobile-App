import 'package:kshetra_poojari/features/pooja/application/models/god.dart';
import 'package:kshetra_poojari/features/pooja/application/models/pooja_task.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// TEST FIXTURE — the design's demo dataset.
///
/// 12 pooja groups → 35 bookings across two shrines. This used to be the
/// app's mock seam; now that the feature reads the API it lives here, pinning
/// the goldens and the state tests to a dataset that never moves.
///
/// Wire it in with `kFixtureOverrides` (see `fixture_overrides.dart`).
/// ─────────────────────────────────────────────────────────────────────────
abstract final class PoojaFixture {
  PoojaFixture._();

  /// Two assigned deities (design demo: `gods_assigned_demo = 2`).
  /// Ids are server `category_id`s; the thumbnails stay local so the mock
  /// renders offline.
  static const List<GodVm> gods = [
    GodVm(
      id: 3,
      name: 'ശ്രീ ഗണപതി',
      imageAsset: 'assets/images/god-elephant.jpg',
    ),
    GodVm(id: 5, name: 'ശ്രീ ഭഗവതി', imageAsset: 'assets/images/god-durga.jpg'),
  ];

  /// Flattened task list, id-numbered in declaration order — identical to the
  /// design's `buildTasks()`.
  static List<PoojaTaskVm> tasks() {
    final out = <PoojaTaskVm>[];
    // Booking ids and order ids in the server's range, so nothing downstream
    // can quietly depend on them being small or contiguous.
    var lineId = 9001;
    var orderId = 4001;
    for (final g in _groups) {
      final order = orderId++;
      for (final p in g.people) {
        out.add(
          PoojaTaskVm(
            id: lineId++,
            orderId: order,
            categoryId: g.categoryId,
            poojaName: g.name,
            person: p.person,
            nakshatra: p.nakshatra,
            remark: p.remark,
            price: 250,
            special: g.special,
            incentive: g.incentive,
            reassigned: g.reassigned,
            status: g.doneAt == null ? TaskStatus.pending : TaskStatus.done,
            doneAt: g.doneAt,
          ),
        );
      }
    }
    return out;
  }

  static const List<_Group> _groups = [
    // ── ശ്രീ ഗണപതി (category 3) ───────────────────────────────────────────────────
    _Group(
      3,
      'ഗണപതി ഹോമം',
      incentive: true,
      people: [
        _P('Ramesh Kumar', 'അശ്വതി'),
        _P('Sunitha', 'രോഹിണി', 'ജോലിക്ക്'),
        _P('Vijayan', 'മകം'),
        _P('Anu', 'ചിത്തിര'),
        _P('Prakash', 'പൂയം'),
      ],
    ),
    _Group(
      3,
      'പഞ്ചാമൃത ഹോമം',
      special: true,
      incentive: true,
      people: [
        _P('Harichandran', 'പൂരം', 'ജോലിക്ക്'),
        _P('Devika', 'പൂരം', 'പരീക്ഷയ്ക്ക്'),
      ],
    ),
    _Group(
      3,
      'ഭാഗ്യസൂക്ത അർച്ചന',
      people: [
        _P('Latha', 'അത്തം'),
        _P('Rajesh', 'മൂലം', 'പുതിയ സംരംഭം'),
        _P('Meera', 'രേവതി'),
        _P('Ajith', 'ഭരണി'),
      ],
    ),
    _Group(
      3,
      'സഹസ്രനാമ അർച്ചന',
      incentive: true,
      people: [
        _P('Geetha', 'തിരുവോണം'),
        _P('Mohan', 'അവിട്ടം', 'രോഗശാന്തിക്ക്'),
        _P('Shalini', 'ചോതി'),
      ],
    ),
    _Group(
      3,
      'മോദക നിവേദ്യം',
      reassigned: true,
      people: [_P('Nandu', 'പുണർതം'), _P('Sreeja', 'ആയില്യം')],
    ),
    _Group(
      3,
      'അപ്പം നിവേദ്യം',
      doneAt: '07:40 AM',
      people: [
        _P('Babu', 'മകയിരം'),
        _P('Reshmi', 'വിശാഖം'),
        _P('Krishnan', 'ഉത്രം'),
      ],
    ),
    // ── ശ്രീ ഭഗവതി (category 5) ───────────────────────────────────────────────────
    _Group(
      5,
      'ഭഗവതി സേവ',
      special: true,
      incentive: true,
      people: [
        _P('Lakshmi Menon', 'അശ്വതി', 'വിവാഹത്തിന്'),
        _P('Anil Kumar', 'ഭരണി'),
      ],
    ),
    _Group(
      5,
      'കുങ്കുമാർച്ചന',
      people: [
        _P('Sindhu', 'കാർത്തിക'),
        _P('Radhika', 'തൃക്കേട്ട', 'പരീക്ഷയ്ക്ക്'),
        _P('Unni', 'ചതയം'),
      ],
    ),
    _Group(
      5,
      'കുങ്കുമാർച്ചന',
      reassigned: true,
      people: [_P('Vinod', 'ഉത്രാടം'), _P('Maya', 'പൂരാടം')],
    ),
    _Group(
      5,
      'രക്തപുഷ്പാഞ്ജലി',
      people: [
        _P('Deepa', 'ചിത്തിര', 'ജന്മദിനം'),
        _P('Shaji', 'അനിഴം'),
        _P('Ramya', 'മകം'),
      ],
    ),
    _Group(
      5,
      'നെയ് വിളക്ക്',
      people: [
        _P('Satheesan', 'പൂയം'),
        _P('Ammu', 'രോഹിണി'),
        _P('Jayan', 'മൂലം'),
        _P('Nimmi', 'അത്തം'),
      ],
    ),
    _Group(
      5,
      'ത്രികാല പൂജ',
      doneAt: '06:30 AM',
      people: [_P('Suresh', 'തിരുവാതിര'), _P('Kamala', 'ഉത്രട്ടാതി')],
    ),
  ];
}

/// Internal seed shapes (not exposed outside the mock layer).
class _Group {
  const _Group(
    this.categoryId,
    this.name, {
    required this.people,
    this.special = false,
    this.incentive = false,
    this.reassigned = false,
    this.doneAt,
  });

  final int categoryId;
  final String name;
  final List<_P> people;
  final bool special;
  final bool incentive;
  final bool reassigned;
  final String? doneAt;
}

class _P {
  const _P(this.person, this.nakshatra, [this.remark]);
  final String person;
  final String nakshatra;
  final String? remark;
}
