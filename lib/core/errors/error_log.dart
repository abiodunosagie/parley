// FILE: core/errors/error_log.dart
// Turns a failure into the line to show, and logs it to the console when it was unexpected.
// Presentation code calls this; domain code uses the plain messageFor in user_messages.dart.

import 'package:flutter/foundation.dart';

import 'user_messages.dart';

String reportError(
  Object error, {
  required bool cancelled,
  required String tag,
}) {
  if (isUnexpected(error, cancelled: cancelled)) {
    debugPrint('Parley $tag error: $error');
  }
  return messageFor(error, cancelled: cancelled);
}
