// FILE: features/conversation/presentation/widgets/web_search_toggle.dart
// The "Search the web" switch above Chat's composer. On: Claude may search while it answers and
// cites the pages it used. Off: it answers from what it already knows.

import 'package:flutter/material.dart';

import '../../../../core/theme/parley_colors.dart';

class WebSearchToggle extends StatelessWidget {
  const WebSearchToggle({
    super.key,
    required this.on,
    required this.onChanged,
    this.enabled = true,
  });

  final bool on;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
      child: Row(
        children: [
          Icon(
            Icons.travel_explore,
            size: 18,
            color: on ? colors.accent : colors.muted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              on ? 'Searching the web when it helps' : 'Search the web',
              style: TextStyle(color: on ? colors.ink : colors.muted),
            ),
          ),
          Switch.adaptive(value: on, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}
