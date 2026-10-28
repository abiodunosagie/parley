import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parley/core/errors/app_exception.dart';
import 'package:parley/features/auth/data/repositories/api_key_repository_impl.dart';
import 'package:parley/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:parley/features/auth/domain/entities/app_user.dart';
import 'package:parley/features/auth/presentation/providers/account_sheet_controller.dart';
import 'package:parley/features/auth/presentation/providers/current_user_provider.dart';

import '../../../helpers/fakes.dart';

const _key = 'sk-ant-api03-abcdefghijklmnopqrstuvwxyz_9Xy7';

void main() {
  late FakeAuth auth;
  late FakeApiKeys keys;
  late ProviderContainer container;

  setUp(() async {
    auth = FakeAuth(const AppUser(id: 'u1', email: 'ada@example.com'));
    keys = FakeApiKeys();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        apiKeyRepositoryProvider.overrideWithValue(keys),
      ],
    );
    addTearDown(container.dispose);
    container.listen(accountSheetControllerProvider, (_, _) {});
    container.listen(currentUserProvider, (_, _) {});
    container.listen(savedApiKeyHintProvider, (_, _) {});
    await pumpEventQueue();
  });

  AccountSheetController sheet() =>
      container.read(accountSheetControllerProvider.notifier);

  Future<String?> hint() => container.read(savedApiKeyHintProvider.future);

  test(
    'a saved key belongs to the signed-in account and shows masked',
    () async {
      sheet().editApiKey();
      await sheet().saveApiKey(' $_key\n');
      expect(keys.keys, {'u1': _key});
      expect(
        container.read(accountSheetControllerProvider),
        isA<AccountOverview>(),
      );
      expect(await hint(), 'sk-ant-...9Xy7');
    },
  );

  test('a failed save stays in the editor with the reason', () async {
    keys.saveError = const AppException('Could not save the key.');
    sheet().editApiKey();
    await sheet().saveApiKey(_key);
    final state = container.read(accountSheetControllerProvider);
    expect(state, isA<EditingApiKey>());
    expect((state as EditingApiKey).error, 'Could not save the key.');
    expect(keys.keys, isEmpty);
  });

  test('removing the key goes back to the shared key', () async {
    keys.keys['u1'] = _key;
    container.invalidate(savedApiKeyHintProvider);
    expect(await hint(), isNotNull);
    await sheet().removeApiKey();
    expect(keys.keys, isEmpty);
    expect(await hint(), isNull);
  });

  test('a key that cannot be read shows as an error, not as no key', () async {
    keys.readError = const AppException(
      'Could not read your saved Claude key.',
    );
    container.invalidate(savedApiKeyHintProvider);
    await pumpEventQueue();
    final saved = container.read(savedApiKeyHintProvider);
    expect(saved.hasError, isTrue);
    expect(saved.error, isA<AppException>());
  });

  test("another account's key is never shown", () async {
    keys.keys['someone-else'] = _key;
    container.invalidate(savedApiKeyHintProvider);
    expect(await hint(), isNull);
  });
}
