// FILE: features/auth/presentation/screens/sign_in_screen.dart
// Sign in or create an account: one form, two modes. Creating an account also asks for your
// first and last name, so Parley can greet you. All state (mode, password visibility, sending,
// errors) is in AuthFormController; this widget only owns the text controllers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/parley_colors.dart';
import '../../../../core/widgets/notice.dart';
import '../../../../core/widgets/parley_mark.dart';
import '../../domain/validators/auth_validators.dart';
import '../providers/auth_form_controller.dart';
import '../widgets/email_field.dart';
import '../widgets/name_fields.dart';
import '../widgets/password_field.dart';
import '../widgets/submit_button.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    ref
        .read(authFormControllerProvider.notifier)
        .submit(
          email: _email.text,
          password: _password.text,
          firstName: _firstName.text,
          lastName: _lastName.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(authFormControllerProvider);
    final controller = ref.read(authFormControllerProvider.notifier);
    final creating = form.mode == AuthMode.signUp;
    final status = form.status;

    final text = Theme.of(context).textTheme;
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          // One group, so the phone can fill name, email and password together.
          child: AutofillGroup(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight - 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    // The mark and the welcome up top; the form down by the thumb.
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The halves meet once as the screen opens, like the launch splash.
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: MediaQuery.disableAnimationsOf(context)
                                  ? 1
                                  : 0,
                              end: 1,
                            ),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (_, meet, _) =>
                                ParleyMark(size: 56, meet: meet),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            creating
                                ? 'Create your\naccount.'
                                : 'Welcome\nback.',
                            style: text.headlineMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            creating
                                ? 'Your first name is how Parley will greet you.'
                                : 'Pick up your conversations where you left them.',
                            style: text.bodyLarge?.copyWith(
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AnimatedSize(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: creating
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: NameFields(
                                        first: _firstName,
                                        last: _lastName,
                                      ),
                                    )
                                  : const SizedBox(width: double.infinity),
                            ),
                            EmailField(controller: _email),
                            const SizedBox(height: 12),
                            PasswordField(
                              controller: _password,
                              obscured: form.obscurePassword,
                              onToggleVisibility:
                                  controller.togglePasswordVisibility,
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
                                  style: text.bodyMedium,
                                ),
                              ),
                            const SizedBox(height: 20),
                            SubmitButton(
                              label: creating ? 'Create account' : 'Sign in',
                              busy: form.busy,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: 8),
                            // Wraps onto two lines on narrow phones or with large text.
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  creating
                                      ? 'Have an account?'
                                      : 'New to Parley?',
                                  style: TextStyle(color: colors.muted),
                                ),
                                TextButton(
                                  onPressed: form.busy
                                      ? null
                                      : controller.toggleMode,
                                  child: Text(
                                    creating ? 'Sign in' : 'Create an account',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
