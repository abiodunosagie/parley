// FILE: features/auth/presentation/widgets/api_key_editor.dart
// The account sheet's own-key step: one hidden box for the user's Claude API key, a line on where
// it is kept, then Save or Cancel. Owns only its text controller and whether the key is shown;
// saving is AccountSheetController.saveApiKey.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/platform/open_link.dart';
import '../../../../core/widgets/notice.dart';
import '../../domain/validators/auth_validators.dart';

class ApiKeyEditor extends StatefulWidget {
  const ApiKeyEditor({
    super.key,
    required this.saving,
    required this.onSave,
    required this.onCancel,
    this.error,
  });

  final bool saving;
  final String? error;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  @override
  State<ApiKeyEditor> createState() => _ApiKeyEditorState();
}

class _ApiKeyEditorState extends State<ApiKeyEditor> {
  final _form = GlobalKey<FormState>();
  final _key = TextEditingController();
  var _obscured = true;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    widget.onSave(_key.text);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Use your own Claude API key. Your requests are then billed to your '
            'Anthropic account, without Parley\'s daily limits.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _key,
            autofocus: true,
            obscureText: _obscured,
            // Keys are not words: no suggestions, no corrections, and the keyboard never learns them.
            autocorrect: false,
            enableSuggestions: false,
            enableIMEPersonalizedLearning: false,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            inputFormatters: [LengthLimitingTextInputFormatter(300)],
            onFieldSubmitted: (_) => _save(),
            validator: (value) => validateApiKey(value ?? ''),
            decoration: InputDecoration(
              hintText: 'sk-ant-...',
              suffixIcon: IconButton(
                tooltip: _obscured ? 'Show key' : 'Hide key',
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kept only in this phone\'s secure storage, for this account. Parley\'s '
            'server uses it for each request and never saves it. It is removed when '
            'you sign out.',
            style: text.bodySmall,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  openLink('https://console.anthropic.com/settings/keys'),
              child: const Text('Get a key from the Anthropic Console'),
            ),
          ),
          if (widget.error != null) Notice(widget.error!),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: widget.saving ? null : _save,
            child: Text(widget.saving ? 'Saving...' : 'Save key'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: widget.saving ? null : widget.onCancel,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
