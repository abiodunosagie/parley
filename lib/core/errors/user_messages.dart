// FILE: core/errors/user_messages.dart
// The words screens show when a request ends badly or Claude stops early. One place, so every
// feature says the same thing for the same situation. Plain Dart, so domain code can use it;
// logging an unexpected error is the caller's job (see core/errors/error_log.dart).

import 'app_exception.dart';

/// The message for a failed request. Unexpected errors get a generic line, so nothing internal
/// reaches the screen.
String messageFor(Object error, {required bool cancelled}) {
  if (error is AppException) return error.message;
  if (cancelled) return 'Stopped.';
  return 'Something went wrong. Try again.';
}

/// True when [error] is not one of ours, so it is worth logging.
bool isUnexpected(Object error, {required bool cancelled}) =>
    error is! AppException && !cancelled;

/// The note for a reply that ended for a reason other than finishing normally.
String? stopReasonNote(String? stopReason) => switch (stopReason) {
  'refusal' => 'Claude declined this request. Try asking a different way.',
  'max_tokens' => 'The reply hit its length limit and was cut short.',
  'pause_turn' =>
    'Claude was still searching when the reply ended. Ask it to continue.',
  _ => null,
};
