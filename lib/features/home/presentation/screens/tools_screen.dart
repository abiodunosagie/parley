// FILE: features/home/presentation/screens/tools_screen.dart
// The Tools tab: features that are a single request rather than a conversation. Each row shows
// what the tool actually does with a real before and after (a rewrite, a receipt, a job post),
// so you know which one you want before you open it.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/parley_colors.dart';
import '../widgets/feature_app_bar.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: const FeatureAppBar(title: 'Tools'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text(
            'One request, one result. Everything you make is kept in its history.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 12),
          const _ToolRow(
            route: AppRoutes.rewrite,
            title: 'Rewrite',
            before: 'cant make 3pm, can we do tmrw?',
            after: 'I can’t make 3 PM today. Could we meet tomorrow instead?',
            shows: _Shows.change,
          ),
          const _ToolRow(
            route: AppRoutes.receipts,
            title: 'Receipts',
            before: 'A photo of a receipt',
            after: 'Cafe Luma  ·  Food EUR 14.30  ·  Drinks EUR 7.20',
          ),
          const _ToolRow(
            route: AppRoutes.extract,
            title: 'Extract',
            before: 'A messy job post, pasted',
            after: 'Mid-level Mobile Engineer  ·  Brightloop  ·  Remote',
          ),
          Divider(height: 1, thickness: 1, color: colors.line),
        ],
      ),
    );
  }
}

/// How a row's example reads: an edit of the text, or a result made from it.
enum _Shows {
  /// The old text crossed out over the new, as Rewrite's "Show changes" does.
  change,

  /// What went in, then an arrow to what came out.
  result,
}

/// One tool: its name, then a small before and after of what it does.
class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.route,
    required this.title,
    required this.before,
    required this.after,
    this.shows = _Shows.result,
  });

  final String route;
  final String title;
  final String before;
  final String after;
  final _Shows shows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final change = shows == _Shows.change;
    return InkWell(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: text.headlineSmall)),
                Icon(Icons.arrow_forward, color: colors.accent),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              before,
              style: TextStyle(
                color: colors.muted,
                decoration: change ? TextDecoration.lineThrough : null,
                decorationColor: colors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!change)
                  Padding(
                    padding: const EdgeInsets.only(right: 6, top: 2),
                    child: Icon(
                      Icons.subdirectory_arrow_right,
                      size: 16,
                      color: colors.accent,
                    ),
                  ),
                Expanded(child: Text(after, style: text.bodyLarge)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
