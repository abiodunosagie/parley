// FILE: features/home/presentation/screens/tools_screen.dart
// The Tools tab: the one-shot features, each a single request with a fixed result. Rewrite
// (streamed text), Receipts (photo to structured fields) and Extract (text to structured fields).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/dimens.dart';
import '../../../../core/theme/parley_colors.dart';
import '../../../../core/widgets/screen_intro.dart';
import '../widgets/feature_app_bar.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static const _tools = [
    _Tool(
      route: AppRoutes.rewrite,
      icon: Icons.edit_note,
      title: 'Rewrite',
      body: 'Shorter, formal, friendly, fixed or translated, with every change highlighted.',
      feature: 'Streaming',
    ),
    _Tool(
      route: AppRoutes.receipts,
      icon: Icons.receipt_long_outlined,
      title: 'Receipts',
      body: 'Snap a receipt and see what you spent, by category.',
      feature: 'Vision + structured output',
    ),
    _Tool(
      route: AppRoutes.extract,
      icon: Icons.document_scanner_outlined,
      title: 'Extract',
      body: 'Paste a messy job post, get clean fields back.',
      feature: 'Structured output',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FeatureAppBar(title: 'Tools'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ScreenIntro(
            title: 'One request, one result.',
            body: 'Each tool is a single Claude call with a fixed kind of answer. Everything you make is kept in its history.',
          ),
          for (final tool in _tools)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ToolTile(tool),
            ),
        ],
      ),
    );
  }
}

class _Tool {
  const _Tool({
    required this.route,
    required this.icon,
    required this.title,
    required this.body,
    required this.feature,
  });
  final String route;
  final IconData icon;
  final String title;
  final String body;

  /// Which Claude API feature the tool shows off.
  final String feature;
}

class _ToolTile extends StatelessWidget {
  const _ToolTile(this.tool);
  final _Tool tool;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.code,
      borderRadius: kRadius,
      child: InkWell(
        borderRadius: kRadius,
        onTap: () => context.go(tool.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(tool.icon, color: colors.accent, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(tool.body),
                    const SizedBox(height: 6),
                    Text(
                      tool.feature,
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
