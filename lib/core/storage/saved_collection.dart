// FILE: core/storage/saved_collection.dart
// One feature's saved items in LocalStore: the list, loading one (an unreadable file is logged
// and skipped, never thrown), saving one with an optional photo or PDF beside it, and deleting.
// Every feature's history repository is a thin layer over this.

import 'package:flutter/foundation.dart';

import 'local_store.dart';

export 'local_store.dart' show LocalStore, SavedSummary;

/// The photo or PDF saved beside an item.
typedef SavedFile = ({String name, Uint8List bytes});

class SavedCollection {
  const SavedCollection(this._store, this.name);
  final LocalStore _store;

  /// The folder name, for example "chat" or "receipts".
  final String name;

  Future<List<SavedSummary>> history(String userId) =>
      _store.list(userId, name);

  /// Rebuilds a saved item with [parse]. Null when it is missing or [parse] fails on it.
  Future<T?> load<T>(
    String userId,
    String id,
    Future<T?> Function(Map<String, dynamic> json) parse,
  ) async {
    final json = await _store.read(userId, name, id);
    if (json == null) return null;
    try {
      return await parse(json);
    } catch (e) {
      debugPrint('Parley: saved $name item unreadable ($e)');
      return null;
    }
  }

  Future<Uint8List?> file(String userId, String id, String fileName) =>
      _store.readBlob(userId, name, id, fileName);

  /// Saves an item. [file] is written first, once per item; if the item itself then fails to
  /// save, a file written by this call is removed again, so nothing is left behind unlisted.
  Future<void> save(
    String userId,
    SavedSummary summary,
    Map<String, dynamic> json, {
    SavedFile? file,
  }) async {
    var wroteFile = false;
    if (file != null &&
        !await _store.hasBlob(userId, name, summary.id, file.name)) {
      await _store.writeBlob(userId, name, summary.id, file.name, file.bytes);
      wroteFile = true;
    }
    try {
      await _store.write(userId, name, summary, json);
    } catch (_) {
      if (wroteFile) await _store.delete(userId, name, summary.id);
      rethrow;
    }
  }

  Future<void> delete(String userId, String id) =>
      _store.delete(userId, name, id);
}
