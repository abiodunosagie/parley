// FILE: core/storage/local_store.dart
// Saved history on the phone: one JSON file per saved item, grouped by account and feature, plus
// a small index per feature so a history list loads without opening every file. Photos and PDFs
// are saved next to their item as plain files. Features use it through their own history
// repositories (data/), never from widgets.
//
// History never leaves the phone: the history folder is excluded from iCloud backup on iOS
// (see ios/Runner/AppDelegate.swift), and Android backups are off for the app.
//
// Layout under the app support folder:
//   history/<userId>/<collection>/index.json      the list a history sheet shows
//   history/<userId>/<collection>/<id>.json       one saved item: {"summary": ..., "data": ...}
//   history/<userId>/<collection>/<id>/<name>     its photo or PDF
// Each item keeps its own summary too, so a damaged index is rebuilt from the items instead of
// losing the whole history.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/saved_summary.dart';

export '../models/saved_summary.dart';

/// Marks [dir] so iOS never copies it to iCloud. Android needs nothing: the app turns backups off.
Future<void> keepOffBackups(Directory dir) async {
  if (!Platform.isIOS) return;
  await const MethodChannel('parley/storage')
      .invokeMethod<void>('excludeFromBackup', dir.path);
}

class LocalStore {
  LocalStore({
    Future<Directory> Function()? root,
    Future<void> Function(Directory dir)? excludeFromBackup,
  }) : _root = root ?? getApplicationSupportDirectory,
       _excludeFromBackup = excludeFromBackup ?? keepOffBackups;

  final Future<Directory> Function() _root;
  final Future<void> Function(Directory dir) _excludeFromBackup;

  /// The history folder, created and kept off backups before anything is written to it.
  Future<Directory>? _history;

  /// Every operation runs after the previous one, so two quick saves never interleave on disk.
  Future<void> _queue = Future.value();

  static final _safe = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  Future<T> _serial<T>(Future<T> Function() task) {
    final result = _queue.then((_) => task());
    _queue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<Directory> _dir(String userId, [String? collection]) async {
    for (final part in [userId, ?collection]) {
      // Ids become folder names, so anything that could climb out of the folder is refused.
      if (!_safe.hasMatch(part)) throw ArgumentError.value(part, 'id');
    }
    final base = Directory('${(await _historyRoot()).path}/$userId');
    return collection == null ? base : Directory('${base.path}/$collection');
  }

  Future<Directory> _historyRoot() => _history ??= () async {
    final dir = Directory('${(await _root()).path}/history');
    await dir.create(recursive: true);
    try {
      await _excludeFromBackup(dir);
    } catch (e) {
      // Saving must still work if the mark fails; try again on the next launch.
      debugPrint('Parley: could not keep history off backups ($e)');
    }
    return dir;
  }();

  File _item(Directory dir, String id) {
    // "index" would land on the index file itself.
    if (!_safe.hasMatch(id) || id == 'index') {
      throw ArgumentError.value(id, 'id');
    }
    return File('${dir.path}/$id.json');
  }

  Future<List<SavedSummary>> _readIndex(Directory dir) async {
    final file = File('${dir.path}/index.json');
    if (!await file.exists()) return [];
    try {
      final list = jsonDecode(await file.readAsString());
      return [for (final entry in list as List) ?SavedSummary.fromJson(entry)];
    } catch (e) {
      debugPrint('Parley: history index unreadable, rebuilding it ($e)');
      await file.rename('${file.path}.bak');
      final rebuilt = await _rebuildIndex(dir);
      await _writeIndex(dir, rebuilt);
      return rebuilt;
    }
  }

  /// The index again, from the summary each saved item carries.
  Future<List<SavedSummary>> _rebuildIndex(Directory dir) async {
    final summaries = <SavedSummary>[];
    await for (final entry in dir.list()) {
      final name = entry.uri.pathSegments.last;
      if (entry is! File || !name.endsWith('.json') || name == 'index.json') {
        continue;
      }
      try {
        final item = jsonDecode(await entry.readAsString());
        final summary = item is Map
            ? SavedSummary.fromJson(item['summary'])
            : null;
        if (summary != null) summaries.add(summary);
      } catch (_) {
        // An unreadable item stays out of the list; the rest of the history survives.
      }
    }
    return summaries;
  }

  Future<void> _writeIndex(Directory dir, List<SavedSummary> index) =>
      _atomicWrite(
        File('${dir.path}/index.json'),
        jsonEncode([for (final s in index) s.toJson()]),
      );

  /// Writes to a temporary file first, so a crash mid-save never leaves half a file behind.
  Future<void> _atomicWrite(File file, String text) async {
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(text, flush: true);
    await temp.rename(file.path);
  }

  /// The saved items of one feature, newest first.
  Future<List<SavedSummary>> list(String userId, String collection) =>
      _serial(() async {
        final index = await _readIndex(await _dir(userId, collection));
        return index..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      });

  Future<Map<String, dynamic>?> read(
    String userId,
    String collection,
    String id,
  ) => _serial(() async {
    final file = _item(await _dir(userId, collection), id);
    if (!await file.exists()) return null;
    try {
      final item =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return item['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Parley: saved item unreadable ($e)');
      return null;
    }
  });

  /// Saves an item and puts its summary at the top of the feature's history.
  Future<void> write(
    String userId,
    String collection,
    SavedSummary summary,
    Map<String, dynamic> json,
  ) => _serial(() async {
    final dir = await _dir(userId, collection);
    await _atomicWrite(
      _item(dir, summary.id),
      jsonEncode({'summary': summary.toJson(), 'data': json}),
    );
    final index = await _readIndex(dir)
      ..removeWhere((s) => s.id == summary.id)
      ..add(summary);
    await _writeIndex(dir, index);
  });

  Future<void> delete(String userId, String collection, String id) =>
      _serial(() async {
        final dir = await _dir(userId, collection);
        final file = _item(dir, id);
        if (await file.exists()) await file.delete();
        final blobs = Directory('${dir.path}/$id');
        if (await blobs.exists()) await blobs.delete(recursive: true);
        final index = await _readIndex(dir)
          ..removeWhere((s) => s.id == id);
        await _writeIndex(dir, index);
      });

  /// Saves a photo or PDF that belongs to item [id].
  Future<void> writeBlob(
    String userId,
    String collection,
    String id,
    String name,
    Uint8List bytes,
  ) => _serial(() async {
    final file = await _blob(userId, collection, id, name);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  });

  Future<bool> hasBlob(
    String userId,
    String collection,
    String id,
    String name,
  ) =>
      _serial(() async => (await _blob(userId, collection, id, name)).exists());

  Future<Uint8List?> readBlob(
    String userId,
    String collection,
    String id,
    String name,
  ) => _serial(() async {
    final file = await _blob(userId, collection, id, name);
    return await file.exists() ? file.readAsBytes() : null;
  });

  Future<File> _blob(
    String userId,
    String collection,
    String id,
    String name,
  ) async {
    if (!_safe.hasMatch(id) || !_safe.hasMatch(name)) {
      throw ArgumentError.value('$id/$name', 'blob');
    }
    return File('${(await _dir(userId, collection)).path}/$id/$name');
  }

  /// Removes everything saved for an account. Runs after the account is deleted.
  Future<void> forgetUser(String userId) => _serial(() async {
    final dir = await _dir(userId);
    if (await dir.exists()) await dir.delete(recursive: true);
  });
}

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore());
