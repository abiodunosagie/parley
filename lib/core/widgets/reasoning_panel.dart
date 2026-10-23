// FILE: core/widgets/reasoning_panel.dart
// Claude's summarized reasoning above a reply (Chat, Look, Read) or a step (Tasks). Open while
// Claude is still thinking, so you watch it work; folded into one line once the answer starts,
// and tap to read it again.

import 'package:flutter/material.dart';

import '../theme/parley_colors.dart';

class ReasoningPanel extends StatefulWidget {
  const ReasoningPanel({
    super.key,
    required this.thinking,
    required this.answering,
  });

  final String thinking;

  /// True once the reply text has started: the panel then folds itself.
  final bool answering;

  @override
  State<ReasoningPanel> createState() => _ReasoningPanelState();
}

class _ReasoningPanelState extends State<ReasoningPanel> {
  /// Null until you tap: the panel follows [ReasoningPanel.answering] until then.
  bool? _open;

  bool get _isOpen => _open ?? !widget.answering;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = widget.answering ? 'Reasoning' : 'Thinking';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_isOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 18,
                    color: colors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: colors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: colors.muted,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topLeft,
            child: _isOpen
                ? Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: colors.line, width: 2),
                      ),
                    ),
                    child: Text(
                      widget.thinking.trim(),
                      style: TextStyle(color: colors.muted, height: 1.4),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
