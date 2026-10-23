// FILE: core/models/claude_model.dart
// The three Claude models you can pick in the app bar. The ids must match `MODELS` in
// supabase/functions/claude/config.ts; the server refuses anything else.

enum ClaudeModel {
  haiku('claude-haiku-5-5', 'Haiku 5.5', 'Fastest, cheapest'),
  sonnet('claude-sonnet-5-5', 'Sonnet 5.5', 'Balanced'),
  opus('claude-opus-5-5', 'Opus 5.5', 'Most capable');

  const ClaudeModel(this.id, this.label, this.blurb);

  final String id;
  final String label;
  final String blurb;
}
