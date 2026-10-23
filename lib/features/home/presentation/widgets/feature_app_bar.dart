// FILE: features/home/presentation/widgets/feature_app_bar.dart
// The app bar every feature tab shares: the title, the model picker, any screen-specific actions
// (History, New chat, New photo), and the account button at the end. Screens pushed on top of a
// tab (the tools) leave the account button to the tab underneath, so their title has room.

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
      // On a narrow phone with several actions the title shrinks a little instead of being cut.
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(title),
      ),
      actions: [
        const ModelPickerButton(),
        ...actions,
        if (!(ModalRoute.of(context)?.canPop ?? false)) const AccountButton(),
      ],
    );
  }
}
