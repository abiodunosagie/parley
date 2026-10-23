// FILE: core/claude_models.dart
// The three Claude models you can pick in the app bar, and the provider that remembers
// which one is selected. Every feature reads `selectedModelProvider` when it sends a request.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The three Claude models the server allows. The ids must match `MODELS` in
/// `supabase/functions/claude/config.ts`; the server refuses anything else.
enum ClaudeModel {
  haiku('claude-haiku-5-5', 'Haiku 5.5', 'Fastest, cheapest'),
  sonnet('claude-sonnet-5-5', 'Sonnet 5.5', 'Balanced'),
  opus('claude-opus-5-5', 'Opus 5.5', 'Most capable');

  const ClaudeModel(this.id, this.label, this.blurb);

  final String id;
  final String label;
  final String blurb;
}

/// The model every feature uses, picked from the app bar.
final selectedModelProvider = NotifierProvider<SelectedModel, ClaudeModel>(
  SelectedModel.new,
);

class SelectedModel extends Notifier<ClaudeModel> {
  @override
  ClaudeModel build() => ClaudeModel.opus;

  void select(ClaudeModel model) => state = model;
}
