// FILE: core/speech/speech_service.dart
// Speech to text on the phone itself (Apple's and Google's recognisers through speech_to_text).
// Nothing you say is sent to Parley's server: only the words, once you send them. One recogniser
// for the whole app, so starting a new dictation ends the one before.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Callbacks for one dictation.
class SpeechCallbacks {
  const SpeechCallbacks({
    required this.onWords,
    required this.onLevel,
    required this.onDone,
  });

  /// Everything heard so far in this dictation (it is revised as you speak).
  final ValueChanged<String> onWords;

  /// Loudness from 0 (silence) to 1, many times a second, for the animation.
  final ValueChanged<double> onLevel;

  /// Listening ended: you stopped, went quiet, or something failed.
  final VoidCallback onDone;
}

abstract interface class SpeechService {
  /// Starts listening. Returns false when speech recognition is unavailable or not allowed.
  Future<bool> start(SpeechCallbacks callbacks);

  /// Stops listening and keeps what was heard.
  Future<void> stop();
}

/// One dictation. Its words keep arriving until the recogniser says it is done, because the final
/// (best) transcript often lands just after you tap stop.
class _Session {
  _Session(this.callbacks);
  final SpeechCallbacks callbacks;
  final done = Completer<void>();
  bool replaced = false;

  void finish() {
    if (done.isCompleted) return;
    done.complete();
    callbacks.onDone();
  }
}

class DeviceSpeechService implements SpeechService {
  final _speech = SpeechToText();
  bool? _ready;
  _Session? _session;

  /// How long to wait for the recogniser to confirm it stopped before treating it as stopped.
  static const _stopGrace = Duration(seconds: 2);

  // Recognisers report loudness on different scales (iOS in negative decibels, Android from
  // about -2 to 10), so each dictation tracks its own quietest and loudest values.
  double _low = double.infinity;
  double _high = double.negativeInfinity;

  Future<bool> _init() async => _ready ??= await _speech.initialize(
    onStatus: (status) {
      if (status == SpeechToText.doneStatus ||
          status == SpeechToText.notListeningStatus) {
        _session?.finish();
      }
    },
    onError: (_) => _session?.finish(),
  );

  @override
  Future<bool> start(SpeechCallbacks callbacks) async {
    final previous = _session;
    if (previous != null && !previous.done.isCompleted) {
      // Let the last dictation end properly first, so its late "done" cannot end this one.
      previous.replaced = true;
      await _speech.stop();
      await previous.done.future.timeout(
        _stopGrace,
        onTimeout: previous.finish,
      );
    }
    try {
      if (!await _init()) {
        _ready = null; // Ask again next time: the person may have allowed it in Settings.
        return false;
      }
    } catch (e) {
      debugPrint('Parley: speech recognition unavailable ($e)');
      _ready = null;
      return false;
    }
    final session = _session = _Session(callbacks);
    _low = double.infinity;
    _high = double.negativeInfinity;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (!session.replaced) callbacks.onWords(result.recognizedWords);
      },
      onSoundLevelChange: (level) {
        if (session.done.isCompleted) return;
        if (level < _low) _low = level;
        if (level > _high) _high = level;
        final span = _high - _low;
        callbacks.onLevel(
          span <= 0 ? 0 : ((level - _low) / span).clamp(0.0, 1.0),
        );
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        autoPunctuation: true,
        pauseFor: const Duration(seconds: 4),
        listenFor: const Duration(minutes: 2),
      ),
    );
    return true;
  }

  @override
  Future<void> stop() async {
    final session = _session;
    if (session == null || session.done.isCompleted) return;
    await _speech.stop();
    // The recogniser normally reports "done" itself; never leave the mic button stuck if not.
    unawaited(
      session.done.future.timeout(_stopGrace, onTimeout: session.finish),
    );
  }
}

final speechServiceProvider = Provider<SpeechService>(
  (ref) => DeviceSpeechService(),
);
