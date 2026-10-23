// FILE: features/auth/presentation/screens/sign_in_screen.dart
// Sign in or create an account: one form, two modes. All state (mode, password visibility,
// sending, errors) is in AuthFormController; this widget only owns the two text controllers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/parley_colors.dart';
import '../../../../core/widgets/notice.dart';
import '../../../../core/widgets/screen_intro.dart';
import '../../domain/validators/auth_validators.dart';
import '../providers/auth_form_controller.dart';
import '../widgets/email_field.dart';
import '../widgets/password_field.dart';
import '../widgets/submit_button.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    ref
        .read(authFormControllerProvider.notifier)
        .submit(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(authFormControllerProvider);
    final controller = ref.read(authFormControllerProvider.notifier);
    final creating = form.mode == AuthMode.signUp;
    final status = form.status;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            children: [
              Text(
                'Parley',
                style: TextStyle(
                  color: context.colors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              ScreenIntro(
                title: creating ? 'Create your account.' : 'Welcome back.',
                body: 'Chat, photos, structured answers and an agent that runs your task list, all powered by Claude.',
              ),
              EmailField(controller: _email),
              const SizedBox(height: 12),
              PasswordField(
                controller: _password,
                obscured: form.obscurePassword,
                onToggleVisibility: controller.togglePasswordVisibility,
                isNewPassword: creating,
                validator: (v) => creating
                    ? validateNewPassword(v ?? '')
                    : validateExistingPassword(v ?? ''),
                onSubmitted: _submit,
              ),
              if (status case SubmitFailed(:final message))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Notice(message),
                ),
              if (status is ConfirmEmailSent)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Check your inbox and confirm your email, then sign in.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              const SizedBox(height: 20),
              SubmitButton(
                label: creating ? 'Create account' : 'Sign in',
                busy: form.busy,
                onPressed: _submit,
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: form.busy ? null : controller.toggleMode,
                child: Text(
                  creating ? 'I already have an account' : 'Create an account',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
