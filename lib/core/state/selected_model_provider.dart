// FILE: core/state/selected_model_provider.dart
// The model every feature uses, picked from the app bar (core/widgets/model_picker_button.dart).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/claude_model.dart';

final selectedModelProvider = NotifierProvider<SelectedModel, ClaudeModel>(
  SelectedModel.new,
);

class SelectedModel extends Notifier<ClaudeModel> {
  @override
  ClaudeModel build() => ClaudeModel.opus;

  void select(ClaudeModel model) => state = model;
}
