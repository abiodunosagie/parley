// The clean-architecture rules, checked on every test run so a shortcut cannot slip in:
//   - domain/ is plain Dart: no data/, presentation/, Flutter UI, Riverpod or Supabase.
//   - core/ never imports a feature.
//   - presentation/ reaches data/ only through *_repository_impl.dart (where the providers live).
//   - no widget or screen talks to Supabase or HTTP directly.
//   - every file starts with a `// FILE:` header that names its real path.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<File> _dart(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

Iterable<String> _imports(File f) =>
    f.readAsLinesSync().where((l) => l.startsWith('import '));

List<String> _violations(
  Iterable<File> files,
  bool Function(String importLine) bad,
) => [
  for (final f in files)
    for (final line in _imports(f))
      if (bad(line)) '${f.path}: $line',
];

void main() {
  final lib = _dart('lib');

  test('domain layer is plain Dart', () {
    final domain = lib.where((f) => f.path.contains('/domain/'));
    expect(
      _violations(
        domain,
        (l) => RegExp(
          r"/data/|/presentation/|supabase|package:flutter/material|package:flutter/widgets|flutter_riverpod",
        ).hasMatch(l),
      ),
      isEmpty,
    );
  });

  test('core never imports a feature', () {
    expect(
      _violations(
        lib.where((f) => f.path.startsWith('lib/core/')),
        (l) => l.contains('features/'),
      ),
      isEmpty,
    );
  });

  test('presentation reaches data only through repository implementations', () {
    final presentation = lib.where((f) => f.path.contains('/presentation/'));
    expect(
      _violations(
        presentation,
        (l) => l.contains('/data/') && !l.contains('_repository_impl.dart'),
      ),
      isEmpty,
    );
  });

  test('no screen or widget calls Supabase or HTTP directly', () {
    final ui = lib.where(
      (f) =>
          f.path.contains('/presentation/') ||
          f.path.startsWith('lib/core/widgets/'),
    );
    expect(
      _violations(
        ui,
        (l) => l.contains('supabase_flutter') || l.contains('package:http'),
      ),
      isEmpty,
    );
  });

  test('every file names its real path in its FILE header', () {
    final wrong = [
      for (final f in lib)
        if (f.readAsLinesSync().first !=
            '// FILE: ${f.path.substring('lib/'.length)}')
          f.path,
    ];
    expect(wrong, isEmpty);
  });

  test('no file grows past 300 lines', () {
    final big = [
      for (final f in lib)
        if (f.readAsLinesSync().length > 300)
          '${f.path}: ${f.readAsLinesSync().length}',
    ];
    expect(big, isEmpty);
  });
}
