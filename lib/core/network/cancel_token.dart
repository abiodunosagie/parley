// FILE: core/network/cancel_token.dart
// Lets a screen stop a request that is still running: the Stop button, starting a new chat, or
// signing out. Passed down to the HTTP request, which aborts as soon as it is cancelled.

import 'dart:async';

class CancelToken {
  final _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;
  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}
