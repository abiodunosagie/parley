// Runs integration_test/ on a device and writes each screenshot into docs/screenshots/.
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshots_test.dart --dart-define-from-file=config/parley.json
// Sign in on the Simulator first. On iOS, flutter drive removes the app when it finishes, so the
// next run needs signing in again.

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    await File('docs/screenshots/$name.png').writeAsBytes(bytes);
    return true;
  },
);
