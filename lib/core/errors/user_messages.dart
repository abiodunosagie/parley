// FILE: core/errors/user_messages.dart
// The words screens show when a request ends badly or Claude stops early. One place, so every
// feature says the same thing for the same situation.

import 'package:flutter/foundation.dart';

import 'app_exception.dart';

/// The message for a failed request. Unexpected errors are logged with [tag] and shown as a
/// generic line, so nothing internal reaches the screen.
String messageFor(
  Object error, {
  required bool cancelled,
  required String tag,
}) {
  if (error is AppException) return error.message;
  if (cancelled) return 'Stopped.';
  debugPrint('Parley $tag error: $error');
  return 'Something went wrong. Try again.';
}

/// The note for a reply that ended for a reason other than finishing normally.
String? stopReasonNote(String? stopReason) => switch (stopReason) {
  'refusal' => 'Claude declined this request. Try asking a different way.',
  'max_tokens' => 'The reply hit its length limit and was cut short.',
  _ => null,
};
