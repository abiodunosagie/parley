import 'package:flutter/material.dart';

import '../app/theme.dart';

/// The message box at the bottom of chat-style screens. While a reply is running the send
/// button becomes Stop.
class Composer extends StatefulWidget {
  const Composer({
    super.key,
    required this.busy,
    required this.onSend,
    required this.onStop,
    this.hint = 'Message Parley',
  });

  final bool busy;
  final ValueChanged<String> onSend;
  final VoidCallback onStop;
  final String hint;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.busy) return;
    _controller.clear();
    widget.onSend(text);
  }

  // Stop shows ink-on-background, send shows the accent pair.
  Color _iconColor(ParleyColors colors) => widget.busy ? colors.background : colors.onAccent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(hintText: widget.hint),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox.square(
              dimension: 48,
              child: IconButton.filled(
                onPressed: widget.busy ? widget.onStop : _send,
                tooltip: widget.busy ? 'Stop' : 'Send',
                style: IconButton.styleFrom(
                  backgroundColor: widget.busy ? colors.ink : colors.accent,
                  foregroundColor: _iconColor(colors),
                  shape: const RoundedRectangleBorder(borderRadius: kRadius),
                ),
                icon: Icon(widget.busy ? Icons.stop_rounded : Icons.arrow_upward_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
