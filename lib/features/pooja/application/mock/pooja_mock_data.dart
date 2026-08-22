import '../models/god.dart';
import '../models/pooja_task.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// MOCK DATA SEAM — pooja feature.
///
/// This is the single place the pooja/home static data lives. It mirrors the
/// design's demo dataset exactly (12 pooja groups → 35 person-tasks across two
/// deities). When the API is integrated, replace [PoojaMockData] with a call
/// into `infrastructure/` (a `PoojaRepository` that returns the same
/// [GodVm] / [PoojaTaskVm] shapes) and point `poojaSeedProvider` at it — no UI
/// or controller change is required.
/// ─────────────────────────────────────────────────────────────────────────
abstract final class PoojaMockData {
  PoojaMockData._();

  /// Two assigned deities (design demo: `gods_assigned_demo = 2`).
  static const List<GodVm> gods = [
    GodVm(
      id: 'g1',
      name: 'ശ്രീ ഗണപതി',
      imageAsset: 'assets/images/god-elephant.jpg',
    ),
    GodVm(
      id: 'g2',
      name: 'ശ്രീ ഭഗവതി',
      imageAsset: 'assets/images/god-durga.jpg',
    ),
  ];

  /// Flattened task list, id-numbered in declaration order — identical to the
  /// design's `buildTasks()`.
  static List<PoojaTaskVm> tasks() {
    final out = <PoojaTaskVm>[];
    var id = 1;
    for (final g in _groups) {
      for (final p in g.people) {
        out.add(
          PoojaTaskVm(
            id: id++,
            godId: g.godId,
            poojaName: g.name,
            person: p.person,
            nakshatra: p.nakshatra,
            remark: p.remark,
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
    // ── ശ്രീ ഗണപതി (g1) ───────────────────────────────────────────────────
    _Group(
      'g1',
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
      'g1',
      'പഞ്ചാമൃത ഹോമം',
      special: true,
      incentive: true,
      people: [
        _P('Harichandran', 'പൂരം', 'ജോലിക്ക്'),
        _P('Devika', 'പൂരം', 'പരീക്ഷയ്ക്ക്'),
      ],
    ),
    _Group(
      'g1',
      'ഭാഗ്യസൂക്ത അർച്ചന',
      people: [
        _P('Latha', 'അത്തം'),
        _P('Rajesh', 'മൂലം', 'പുതിയ സംരംഭം'),
        _P('Meera', 'രേവതി'),
        _P('Ajith', 'ഭരണി'),
      ],
    ),
    _Group(
      'g1',
      'സഹസ്രനാമ അർച്ചന',
      incentive: true,
      people: [
        _P('Geetha', 'തിരുവോണം'),
        _P('Mohan', 'അവിട്ടം', 'രോഗശാന്തിക്ക്'),
        _P('Shalini', 'ചോതി'),
      ],
    ),
    _Group(
      'g1',
      'മോദക നിവേദ്യം',
      reassigned: true,
      people: [_P('Nandu', 'പുണർതം'), _P('Sreeja', 'ആയില്യം')],
    ),
    _Group(
      'g1',
      'അപ്പം നിവേദ്യം',
      doneAt: '07:40 AM',
      people: [
        _P('Babu', 'മകയിരം'),
        _P('Reshmi', 'വിശാഖം'),
        _P('Krishnan', 'ഉത്രം'),
      ],
    ),
    // ── ശ്രീ ഭഗവതി (g2) ───────────────────────────────────────────────────
    _Group(
      'g2',
      'ഭഗവതി സേവ',
      special: true,
      incentive: true,
      people: [
        _P('Lakshmi Menon', 'അശ്വതി', 'വിവാഹത്തിന്'),
        _P('Anil Kumar', 'ഭരണി'),
      ],
    ),
    _Group(
      'g2',
      'കുങ്കുമാർച്ചന',
      people: [
        _P('Sindhu', 'കാർത്തിക'),
        _P('Radhika', 'തൃക്കേട്ട', 'പരീക്ഷയ്ക്ക്'),
        _P('Unni', 'ചതയം'),
      ],
    ),
    _Group(
      'g2',
      'കുങ്കുമാർച്ചന',
      reassigned: true,
      people: [_P('Vinod', 'ഉത്രാടം'), _P('Maya', 'പൂരാടം')],
    ),
    _Group(
      'g2',
      'രക്തപുഷ്പാഞ്ജലി',
      people: [
        _P('Deepa', 'ചിത്തിര', 'ജന്മദിനം'),
        _P('Shaji', 'അനിഴം'),
        _P('Ramya', 'മകം'),
      ],
    ),
    _Group(
      'g2',
      'നെയ് വിളക്ക്',
      people: [
        _P('Satheesan', 'പൂയം'),
        _P('Ammu', 'രോഹിണി'),
        _P('Jayan', 'മൂലം'),
        _P('Nimmi', 'അത്തം'),
      ],
    ),
    _Group(
      'g2',
      'ത്രികാല പൂജ',
      doneAt: '06:30 AM',
      people: [_P('Suresh', 'തിരുവാതിര'), _P('Kamala', 'ഉത്രട്ടാതി')],
    ),
  ];
}

/// Internal seed shapes (not exposed outside the mock layer).
class _Group {
  const _Group(
    this.godId,
    this.name, {
    required this.people,
    this.special = false,
    this.incentive = false,
    this.reassigned = false,
    this.doneAt,
  });

  final String godId;
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
