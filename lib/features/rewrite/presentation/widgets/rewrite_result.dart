// FILE: features/rewrite/presentation/widgets/rewrite_result.dart
// The rewritten text, with a switch to highlight the changes: words added in the accent tint,
// words removed struck through. Copy puts the rewrite on the clipboard.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/dimens.dart';
import '../../../../core/theme/parley_colors.dart';
import '../../domain/services/word_diff.dart';

class RewriteResult extends StatefulWidget {
  const RewriteResult({
    super.key,
    required this.before,
    required this.after,
    required this.finished,
  });

  final String before;
  final String after;

  /// False while the rewrite is still streaming: changes are only worked out once it is done.
  final bool finished;

  @override
  State<RewriteResult> createState() => _RewriteResultState();
}

class _RewriteResultState extends State<RewriteResult> {
  bool _showChanges = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.after));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final body = Theme.of(context).textTheme.bodyLarge;
    final changes = widget.finished && _showChanges;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.code, borderRadius: kRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (changes)
            Text.rich(
              TextSpan(
                style: body,
                children: [
                  for (final part in wordDiff(widget.before, widget.after))
                    TextSpan(
                      text: part.text,
                      style: switch (part.op) {
                        DiffOp.same => null,
                        DiffOp.added => TextStyle(
                          backgroundColor: colors.accentSoft,
                          color: colors.ink,
                        ),
                        DiffOp.removed => TextStyle(
                          color: colors.muted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      },
                    ),
                ],
              ),
            )
          else
            SelectableText(widget.after, style: body),
          if (widget.finished) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Switch.adaptive(
                  value: _showChanges,
                  onChanged: (v) => setState(() => _showChanges = v),
                ),
                const SizedBox(width: 4),
                const Expanded(child: Text('Show changes')),
                TextButton.icon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
