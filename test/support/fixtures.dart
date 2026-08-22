import 'dart:convert';
import 'dart:io';

/// Loads a JSON fixture from `test/fixtures/`.
///
/// These are the literal sample bodies from `docs-flutter/pooja.md`, so a
/// parser change that breaks against the documented contract fails here.
Map<String, dynamic> loadFixture(String name) {
  final file = File('test/fixtures/$name');
  if (!file.existsSync()) {
    throw StateError('Missing fixture: ${file.path}');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}
