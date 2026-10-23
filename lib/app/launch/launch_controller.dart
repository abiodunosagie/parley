// FILE: app/launch/launch_controller.dart
// True once the launch animation has played. It plays once per app start; the router keeps every
// other screen back until then.

import 'package:flutter_riverpod/flutter_riverpod.dart';

class LaunchController extends Notifier<bool> {
  @override
  bool build() => false;

  void done() => state = true;
}

final launchDoneProvider = NotifierProvider<LaunchController, bool>(
  LaunchController.new,
);
