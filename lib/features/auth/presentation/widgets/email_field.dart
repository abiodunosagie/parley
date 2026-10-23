// FILE: features/auth/presentation/widgets/email_field.dart
// The email box: email keyboard, no autocorrect, autofill from the phone's saved accounts.

import 'package:flutter/material.dart';

import '../../domain/validators/auth_validators.dart';

class EmailField extends StatelessWidget {
  const EmailField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(hintText: 'Email'),
      validator: (value) => validateEmail(value ?? ''),
    );
  }
}
