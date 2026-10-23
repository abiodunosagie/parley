// FILE: features/home/presentation/widgets/feature_app_bar.dart
// The app bar every feature tab shares: the title, the model picker, any screen-specific actions
// (New chat, New photo), and the account button at the end.

import 'package:flutter/material.dart';

import '../../../../core/widgets/model_picker_button.dart';
import '../../../auth/presentation/widgets/account_button.dart';

class FeatureAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FeatureAppBar({
    super.key,
    required this.title,
    this.actions = const [],
  });
  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [const ModelPickerButton(), ...actions, const AccountButton()],
    );
  }
}
