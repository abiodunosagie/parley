import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:parley/core/storage/local_store.dart';

void main() {
  late Directory root;
  late LocalStore store;
  final excluded = <String>[];

  setUp(() async {
    root = await Directory.systemTemp.createTemp('parley_store_');
    excluded.clear();
    store = LocalStore(
      root: () async => root,
      excludeFromBackup: (d) async => excluded.add(d.path),
    );
  });
  tearDown(() => root.delete(recursive: true));

  SavedSummary summary(String id, int minute) => SavedSummary(
    id: id,
    title: 'T $id',
    updatedAt: DateTime.utc(2026, 10, 23, 12, minute),
  );

  test(
    'saves, lists newest first, reads back and deletes with its files',
    () async {
      await store.write('u1', 'chat', summary('a', 1), {'n': 1});
      await store.write('u1', 'chat', summary('b', 2), {'n': 2});
      await store.writeBlob(
        'u1',
        'chat',
        'a',
        'attachment',
        Uint8List.fromList([1, 2, 3]),
      );
      expect(
        [for (final s in await store.list('u1', 'chat')) s.id],
        ['b', 'a'],
      );
      expect(await store.read('u1', 'chat', 'a'), {'n': 1});
      expect(await store.hasBlob('u1', 'chat', 'a', 'attachment'), isTrue);

      await store.delete('u1', 'chat', 'a');
      expect([for (final s in await store.list('u1', 'chat')) s.id], ['b']);
      expect(await store.read('u1', 'chat', 'a'), isNull);
      expect(await store.readBlob('u1', 'chat', 'a', 'attachment'), isNull);
    },
  );

  test(
    'saving again replaces the entry instead of adding a second one',
    () async {
      await store.write('u1', 'chat', summary('a', 1), {'n': 1});
      await store.write('u1', 'chat', summary('a', 5), {'n': 2});
      final list = await store.list('u1', 'chat');
      expect(list, hasLength(1));
      expect(list.single.updatedAt.minute, 5);
    },
  );

  test(
    'accounts never see each other, and forgetting one removes only it',
    () async {
      await store.write('u1', 'chat', summary('a', 1), {});
      await store.write('u2', 'chat', summary('b', 1), {});
      expect(await store.list('u2', 'chat'), hasLength(1));
      await store.forgetUser('u1');
      expect(await store.list('u1', 'chat'), isEmpty);
      expect(await store.list('u2', 'chat'), hasLength(1));
    },
  );

  test('the history folder is kept off backups once, before the first save', () async {
    await store.write('u1', 'chat', summary('a', 1), {});
    await store.write('u1', 'chat', summary('b', 2), {});
    expect(excluded, ['${root.path}/history']);
  });

  test('ids that could leave the folder are refused', () async {
    expect(() => store.read('../u2', 'chat', 'a'), throwsArgumentError);
    expect(() => store.read('u1', 'chat', '../../x'), throwsArgumentError);
  });

  test('a damaged index is rebuilt from the saved items, not lost', () async {
    await store.write('u1', 'chat', summary('a', 1), {'n': 1});
    await store.write('u1', 'chat', summary('b', 2), {'n': 2});
    File('${root.path}/history/u1/chat/index.json')
        .writeAsStringSync('{not json');
    expect([for (final s in await store.list('u1', 'chat')) s.id], ['b', 'a']);
    // The repaired index was written back, so the next read needs no rebuild.
    expect([for (final s in await store.list('u1', 'chat')) s.id], ['b', 'a']);
    expect(await store.read('u1', 'chat', 'a'), {'n': 1});
  });

  test('"index" can never be an item id', () async {
    expect(() => store.read('u1', 'chat', 'index'), throwsArgumentError);
  });
}
