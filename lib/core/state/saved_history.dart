// FILE: core/state/saved_history.dart
// What every feature with a History sheet shares: the list provider for the signed-in account,
// and a mixin for controllers that open, save and delete saved items. One place handles the
// signed-out case, refreshing the list, and logging a storage failure without breaking the
// screen. Features pass in the signed-in user's id (auth's currentUserIdProvider), so core never
// imports a feature.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show ProviderListenable, ProviderOrFamily;

import '../errors/error_log.dart';
import '../models/saved_summary.dart';

/// A feature's history list for the signed-in account, newest first. Empty while signed out;
/// reloads when the account changes or the list is invalidated after a save or delete.
FutureProvider<List<SavedSummary>> savedListProvider(
  ProviderListenable<String?> userId,
  Future<List<SavedSummary>> Function(Ref ref, String userId) load,
) => FutureProvider.autoDispose((ref) async {
  final id = ref.watch(userId);
  if (id == null) return const [];
  return load(ref, id);
});

mixin SavedHistory<StateT> on Notifier<StateT> {
  /// The signed-in account. Nothing is opened, saved or deleted while signed out.
  String? get historyUserId;

  /// The history list to refresh after a save or delete.
  ProviderOrFamily get historyList;

  /// Loads a saved item. Null when signed out, missing, or unreadable (a storage failure is
  /// logged, never thrown into the screen).
  Future<T?> loadSaved<T>(Future<T?> Function(String userId) load) async {
    final userId = historyUserId;
    if (userId == null) return null;
    try {
      return await load(userId);
    } catch (e) {
      reportError(e, cancelled: false, tag: 'history');
      return null;
    }
  }

  /// Saves or deletes, then refreshes the list. False when signed out or the change failed.
  Future<bool> changeSaved(Future<void> Function(String userId) change) async {
    final userId = historyUserId;
    if (userId == null) return false;
    try {
      await change(userId);
      if (ref.mounted) ref.invalidate(historyList);
      return true;
    } catch (e) {
      // Saving is a convenience: a full disk must not break what is on screen.
      reportError(e, cancelled: false, tag: 'history');
      return false;
    }
  }
}
