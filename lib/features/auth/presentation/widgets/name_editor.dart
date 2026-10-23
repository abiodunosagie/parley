// FILE: features/auth/presentation/widgets/name_editor.dart
// The account sheet's name step: first and last name, prefilled with the current name, then Save
// or Cancel. Owns only its text controllers; saving is AccountSheetController.saveName.

import 'package:flutter/material.dart';

import '../../../../core/widgets/notice.dart';
import 'name_fields.dart';

class NameEditor extends StatefulWidget {
  const NameEditor({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.saving,
    required this.onSave,
    required this.onCancel,
    this.error,
  });

  final String firstName;
  final String lastName;
  final bool saving;
  final String? error;
  final void Function({required String firstName, required String lastName})
  onSave;
  final VoidCallback onCancel;

  @override
  State<NameEditor> createState() => _NameEditorState();
}

class _NameEditorState extends State<NameEditor> {
  final _form = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.firstName);
  late final _last = TextEditingController(text: widget.lastName);

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    widget.onSave(firstName: _first.text, lastName: _last.text);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NameFields(first: _first, last: _last, autofocus: true),
            if (widget.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Notice(widget.error!),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: widget.saving ? null : _save,
              child: Text(widget.saving ? 'Saving...' : 'Save name'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: widget.saving ? null : widget.onCancel,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
