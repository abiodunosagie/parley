// FILE: features/auth/presentation/providers/auth_form_controller.dart
// Everything the sign-in screen shows, as one immutable state: which mode the form is in,
// whether the password is visible, and where the submit stands (idle, sending, failed, or
// waiting for an email confirmation). Made fresh each time the sign-in screen opens (autoDispose),
// so signing out always lands on "Welcome back", never on a create-account form left from before.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_log.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/validators/auth_validators.dart';

enum AuthMode { signIn, signUp }

sealed class SubmitStatus {
  const SubmitStatus();
}

class SubmitIdle extends SubmitStatus {
  const SubmitIdle();
}

class Submitting extends SubmitStatus {
  const Submitting();
}

class SubmitFailed extends SubmitStatus {
  const SubmitFailed(this.message);
  final String message;
}

class ConfirmEmailSent extends SubmitStatus {
  const ConfirmEmailSent();
}

@immutable
class AuthFormState {
  const AuthFormState({
    this.mode = AuthMode.signIn,
    this.obscurePassword = true,
    this.status = const SubmitIdle(),
  });
  final AuthMode mode;
  final bool obscurePassword;
  final SubmitStatus status;

  bool get busy => status is Submitting;

  AuthFormState copyWith({
    AuthMode? mode,
    bool? obscurePassword,
    SubmitStatus? status,
  }) => AuthFormState(
    mode: mode ?? this.mode,
    obscurePassword: obscurePassword ?? this.obscurePassword,
    status: status ?? this.status,
  );
}

class AuthFormController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  void toggleMode() => state = state.copyWith(
    mode: state.mode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn,
    status: const SubmitIdle(),
  );

  void togglePasswordVisibility() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);

  /// Signs in or creates the account (with [firstName] and [lastName], which only sign-up uses).
  /// On success the router moves to the app by itself, because it listens to the signed-in user.
  Future<void> submit({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
  }) async {
    if (state.busy) return;
    state = state.copyWith(status: const Submitting());
    final repository = ref.read(authRepositoryProvider);
    try {
      if (state.mode == AuthMode.signIn) {
        await repository.signIn(email: email, password: password);
        if (ref.mounted) state = state.copyWith(status: const SubmitIdle());
      } else {
        final outcome = await repository.signUp(
          email: email,
          password: password,
          firstName: cleanName(firstName),
          lastName: cleanName(lastName),
        );
        if (!ref.mounted) return;
        state = state.copyWith(
          status: outcome == SignUpOutcome.confirmEmail
              ? const ConfirmEmailSent()
              : const SubmitIdle(),
        );
      }
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          status: SubmitFailed(reportError(e, cancelled: false, tag: 'auth')),
        );
      }
    }
  }
}

final authFormControllerProvider =
    NotifierProvider.autoDispose<AuthFormController, AuthFormState>(
      AuthFormController.new,
    );
