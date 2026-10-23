// FILE: features/conversation/presentation/widgets/search_lines.dart
// One line per web search Claude ran while writing a reply, so you can see what it looked up.

import 'package:flutter/material.dart';

import '../../../../core/theme/parley_colors.dart';

class SearchLines extends StatelessWidget {
  const SearchLines(this.queries, {super.key});
  final List<String> queries;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final query in queries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.travel_explore, size: 16, color: muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Searched the web for "$query"',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
