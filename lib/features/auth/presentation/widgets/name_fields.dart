// FILE: features/auth/presentation/widgets/name_fields.dart
// First and last name boxes side by side: capitalised words, autofill from the phone's contact
// card, and the shared name rules. Used when creating an account and when editing the name.

import 'package:flutter/material.dart';

import '../../domain/validators/auth_validators.dart';

class NameFields extends StatelessWidget {
  const NameFields({
    super.key,
    required this.first,
    required this.last,
    this.autofocus = false,
  });

  final TextEditingController first;
  final TextEditingController last;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    TextFormField field(
      TextEditingController controller, {
      required String which,
      required String hint,
      required String autofill,
      bool focus = false,
    }) => TextFormField(
      controller: controller,
      autofocus: focus,
      textCapitalization: TextCapitalization.words,
      autofillHints: [autofill],
      autocorrect: false,
      maxLength: maxNameLength,
      buildCounter: (
        _, {
        required currentLength,
        required isFocused,
        maxLength,
      }) => null,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(hintText: hint),
      validator: (value) => validateName(value ?? '', which: which),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: field(
            first,
            which: 'first',
            hint: 'First name',
            autofill: AutofillHints.givenName,
            focus: autofocus,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: field(
            last,
            which: 'last',
            hint: 'Last name',
            autofill: AutofillHints.familyName,
          ),
        ),
      ],
    );
  }
}
