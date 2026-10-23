// FILE: features/auth/auth_screen.dart
// The sign-in / create-account form. One form, two modes, switched by the second
// button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/blocks.dart';
import 'auth_controller.dart';

/// Sign in or create an account. One form, two modes.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _creating = false;
  var _hidden = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final auth = ref.read(authControllerProvider.notifier);
    _creating
        ? auth.signUp(_email.text, _password.text)
        : auth.signIn(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final colors = context.colors;

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
                  color: colors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              ScreenIntro(
                title: _creating ? 'Create your account.' : 'Welcome back.',
                body: 'Chat, photos, structured answers and an agent that runs your task list, all powered by Claude.',
              ),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Email'),
                validator: (v) => AuthController.checkEmail(v ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _hidden,
                autofillHints: [
                  _creating
                      ? AutofillHints.newPassword
                      : AutofillHints.password,
                ],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Password',
                  suffixIcon: IconButton(
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (v) => _creating
                    ? AuthController.checkPassword(v ?? '')
                    : ((v ?? '').isEmpty ? 'Enter your password.' : null),
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Notice(state.error!),
                ),
              if (state.info != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    state.info!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: state.busy ? null : _submit,
                child: state.busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_creating ? 'Create account' : 'Sign in'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: state.busy
                    ? null
                    : () => setState(() => _creating = !_creating),
                child: Text(
                  _creating ? 'I already have an account' : 'Create an account',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
