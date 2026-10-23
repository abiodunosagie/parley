import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parley/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:parley/features/auth/presentation/providers/auth_form_controller.dart';

import '../../../helpers/fakes.dart';

void main() {
  late FakeAuth auth;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuth();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
  });

  AuthFormController form() =>
      container.read(authFormControllerProvider.notifier);

  test('signs in and returns to idle', () async {
    await form().submit(email: 'a@example.com', password: 'secret123');
    expect(auth.calls, ['signIn']);
    expect(
      container.read(authFormControllerProvider).status,
      isA<SubmitIdle>(),
    );
  });

  test('sign-up that needs email confirmation says so', () async {
    form().toggleMode();
    await form().submit(email: 'a@example.com', password: 'secret123');
    expect(
      container.read(authFormControllerProvider).status,
      isA<ConfirmEmailSent>(),
    );
  });

  test(
    'switching mode clears a previous error, and the password eye toggles',
    () {
      form().togglePasswordVisibility();
      expect(
        container.read(authFormControllerProvider).obscurePassword,
        isFalse,
      );
      form().toggleMode();
      expect(container.read(authFormControllerProvider).mode, AuthMode.signUp);
    },
  );
}
