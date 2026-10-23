import 'package:flutter_test/flutter_test.dart';
import 'package:parley/core/errors/app_exception.dart';
import 'package:parley/features/auth/domain/entities/app_user.dart';
import 'package:parley/features/auth/domain/services/delete_account.dart';

import '../../../helpers/fakes.dart';

void main() {
  test(
    'deletes, runs every clean-up with the user id, then signs out locally',
    () async {
      final auth = FakeAuth(const AppUser(id: 'u1', email: 'a@example.com'));
      final cleaned = <String>[];
      final failures = await DeleteAccount(
        repository: auth,
        cleanups: [(id) async => cleaned.add(id)],
      )();
      expect(auth.calls, ['delete', 'signOutLocal']);
      expect(cleaned, ['u1']);
      expect(failures, isEmpty);
    },
  );

  test('a failing clean-up is reported but never stops the sign-out', () async {
    final auth = FakeAuth(const AppUser(id: 'u1', email: 'a@example.com'));
    final failures = await DeleteAccount(
      repository: auth,
      cleanups: [(_) async => throw StateError('disk')],
    )();
    expect(failures, hasLength(1));
    expect(auth.calls.last, 'signOutLocal');
  });

  test('when the server delete fails nothing else happens', () async {
    final auth = FakeAuth(const AppUser(id: 'u1', email: 'a@example.com'))
      ..deleteError = const AppException('nope');
    final cleaned = <String>[];
    await expectLater(
      DeleteAccount(
        repository: auth,
        cleanups: [(id) async => cleaned.add(id)],
      )(),
      throwsA(isA<AppException>()),
    );
    expect(cleaned, isEmpty);
    expect(auth.calls, ['delete']);
  });
}
