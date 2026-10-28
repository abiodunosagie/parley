// Fakes shared by the tests: an account system, a task store, saved history and dictation, all
// in memory.

import 'dart:async';
import 'dart:typed_data';

import 'package:parley/core/speech/speech_service.dart';
import 'package:parley/core/storage/local_store.dart';
import 'package:parley/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:parley/features/auth/domain/entities/app_user.dart';
import 'package:parley/features/auth/domain/repositories/api_key_repository.dart';
import 'package:parley/features/auth/domain/repositories/auth_repository.dart';
import 'package:parley/features/tasks/domain/entities/task.dart';
import 'package:parley/features/tasks/domain/repositories/task_repository.dart';

class FakeAuth implements AuthRepository {
  FakeAuth([this.currentUser]);

  @override
  AppUser? currentUser;
  final _changes = StreamController<AppUser?>.broadcast();
  final calls = <String>[];
  Object? deleteError;
  Object? nameError;

  void emit(AppUser? user) {
    currentUser = user;
    _changes.add(user);
  }

  @override
  Stream<AppUser?> watchUser() => _changes.stream;

  @override
  Future<String> accessToken({bool fresh = false}) async => 'token';

  @override
  Future<void> deleteAccount() async {
    calls.add('delete');
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    calls.add('signIn');
    emit(AppUser(id: 'u1', email: email));
  }

  @override
  Future<void> signOut({bool everywhere = true}) async {
    calls.add(everywhere ? 'signOut' : 'signOutLocal');
    emit(null);
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    calls.add('signUp $firstName $lastName');
    return SignUpOutcome.confirmEmail;
  }

  @override
  Future<void> updateName({
    required String firstName,
    required String lastName,
  }) async {
    calls.add('updateName $firstName $lastName');
    if (nameError != null) throw nameError!;
    final user = currentUser;
    if (user != null) {
      emit(
        AppUser(
          id: user.id,
          email: user.email,
          firstName: firstName,
          lastName: lastName,
        ),
      );
    }
  }
}

class MemoryTasks implements TaskRepository {
  final saved = <String, List<Task>>{};

  @override
  Future<void> forget(String userId) async => saved.remove(userId);

  @override
  Future<List<Task>> load(String userId) async => saved[userId] ?? const [];

  @override
  Future<void> save(String userId, List<Task> tasks) async =>
      saved[userId] = tasks;
}

/// LocalStore without the disk: every collection is a map.
class MemoryStore extends LocalStore {
  final items = <String, Map<String, dynamic>>{};
  final summaries = <String, Map<String, SavedSummary>>{};
  final blobs = <String, Uint8List>{};

  String _key(String userId, String collection, [String? id, String? name]) =>
      [userId, collection, ?id, ?name].join('/');

  @override
  Future<List<SavedSummary>> list(String userId, String collection) async =>
      [...?summaries[_key(userId, collection)]?.values]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Future<Map<String, dynamic>?> read(
    String userId,
    String collection,
    String id,
  ) async => items[_key(userId, collection, id)];

  @override
  Future<void> write(
    String userId,
    String collection,
    SavedSummary summary,
    Map<String, dynamic> json,
  ) async {
    items[_key(userId, collection, summary.id)] = json;
    (summaries[_key(userId, collection)] ??= {})[summary.id] = summary;
  }

  @override
  Future<void> delete(String userId, String collection, String id) async {
    items.remove(_key(userId, collection, id));
    summaries[_key(userId, collection)]?.remove(id);
    blobs.removeWhere(
      (k, _) => k.startsWith('${_key(userId, collection, id)}/'),
    );
  }

  @override
  Future<void> writeBlob(
    String userId,
    String collection,
    String id,
    String name,
    Uint8List bytes,
  ) async => blobs[_key(userId, collection, id, name)] = bytes;

  @override
  Future<bool> hasBlob(
    String userId,
    String collection,
    String id,
    String name,
  ) async => blobs.containsKey(_key(userId, collection, id, name));

  @override
  Future<Uint8List?> readBlob(
    String userId,
    String collection,
    String id,
    String name,
  ) async => blobs[_key(userId, collection, id, name)];

  @override
  Future<void> forgetUser(String userId) async {
    items.removeWhere((k, _) => k.startsWith('$userId/'));
    summaries.removeWhere((k, _) => k.startsWith('$userId/'));
    blobs.removeWhere((k, _) => k.startsWith('$userId/'));
  }
}

/// Dictation the test drives: [say] delivers words, [finish] ends listening.
class FakeSpeech implements SpeechService {
  FakeSpeech({this.available = true});
  final bool available;
  SpeechCallbacks? active;

  @override
  Future<bool> start(SpeechCallbacks callbacks) async {
    if (!available) return false;
    active = callbacks;
    return true;
  }

  @override
  Future<void> stop() async => finish();

  void say(String words, {double level = 0.6}) {
    active?.onLevel(level);
    active?.onWords(words);
  }

  void finish() {
    final callbacks = active;
    active = null;
    callbacks?.onDone();
  }
}

/// The welcome-pages flag, in memory.
class MemoryOnboarding implements OnboardingRepository {
  MemoryOnboarding({this.seen = false});

  @override
  bool seen;
  var saves = 0;

  @override
  Future<void> markSeen() async {
    saves++;
    seen = true;
  }
}

/// Own Claude keys in memory, one per account, like the phone's secure storage.
class FakeApiKeys implements ApiKeyRepository {
  final keys = <String, String>{};
  Object? saveError;
  Object? readError;

  @override
  Future<String?> read(String userId) async {
    if (readError != null) throw readError!;
    return keys[userId];
  }

  @override
  Future<void> save(String userId, String key) async {
    if (saveError != null) throw saveError!;
    keys[userId] = key;
  }

  @override
  Future<void> remove(String userId) async => keys.remove(userId);
}
