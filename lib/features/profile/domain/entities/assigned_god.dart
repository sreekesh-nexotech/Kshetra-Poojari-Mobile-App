/// One row of `GET /api/poojari/gods/` — a shrine this poojari keeps.
/// (poojari-app.md §2)
class AssignedGod {
  const AssignedGod({required this.name});

  /// Malayalam script, e.g. `"ഗണപതി"`.
  final String name;

  factory AssignedGod.fromJson(Map<String, dynamic> j) => AssignedGod(
    name: (j['god'] as Map<String, dynamic>?)?['name'] as String? ?? '',
  );
}
