import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parley/core/errors/app_exception.dart';
import 'package:parley/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:parley/features/auth/domain/entities/app_user.dart';
import 'package:parley/features/auth/presentation/providers/account_sheet_controller.dart';
import 'package:parley/features/auth/presentation/providers/current_user_provider.dart';

import '../../../helpers/fakes.dart';

void main() {
  late FakeAuth auth;
  late ProviderContainer container;

  setUp(() async {
    auth = FakeAuth(const AppUser(id: 'u1', email: 'ada@example.com'));
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    container.listen(accountSheetControllerProvider, (_, _) {});
    container.listen(currentUserProvider, (_, _) {});
    await pumpEventQueue();
  });

  AccountSheetController sheet() =>
      container.read(accountSheetControllerProvider.notifier);

  test('an account without a name shows its email as the name', () {
    const user = AppUser(id: 'u1', email: 'ada@example.com');
    expect(user.hasName, isFalse);
    expect(user.displayName, 'ada@example.com');
    expect(
      const AppUser(
        id: 'u1',
        email: 'a@b.c',
        firstName: 'Ada',
        lastName: 'Lovelace',
      ).displayName,
      'Ada Lovelace',
    );
  });

  test(
    'saving a name updates the signed-in user and returns to the overview',
    () async {
      sheet().editName();
      await sheet().saveName(firstName: ' Ada ', lastName: 'Lovelace');
      await pumpEventQueue();
      expect(auth.calls, ['updateName Ada Lovelace']);
      expect(
        container.read(accountSheetControllerProvider),
        isA<AccountOverview>(),
      );
      expect(container.read(currentUserProvider).value?.firstName, 'Ada');
    },
  );

  test('a failed save stays in the editor with the reason', () async {
    auth.nameError = const AppException(
      'No connection. Check your internet and try again.',
    );
    sheet().editName();
    await sheet().saveName(firstName: 'Ada', lastName: 'Lovelace');
    final state = container.read(accountSheetControllerProvider);
    expect(state, isA<EditingName>());
    expect((state as EditingName).error, contains('No connection'));
  });
}
