// FILE: features/auth/presentation/widgets/password_field.dart
// The password box with a show/hide eye. Visibility lives in AuthFormController, not in widget
// state, so it survives rebuilds.

import 'package:flutter/material.dart';

class PasswordField extends StatelessWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.obscured,
    required this.onToggleVisibility,
    required this.isNewPassword,
    required this.validator,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool obscured;
  final VoidCallback onToggleVisibility;

  /// Tells password managers to suggest a new password instead of filling a saved one.
  final bool isNewPassword;
  final FormFieldValidator<String> validator;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscured,
      autofillHints: [
        isNewPassword ? AutofillHints.newPassword : AutofillHints.password,
      ],
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => onSubmitted(),
      validator: validator,
      decoration: InputDecoration(
        hintText: 'Password',
        suffixIcon: IconButton(
          tooltip: obscured ? 'Show password' : 'Hide password',
          onPressed: onToggleVisibility,
          icon: Icon(
            obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}
