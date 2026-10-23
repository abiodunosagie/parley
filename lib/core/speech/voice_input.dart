// FILE: core/speech/voice_input.dart
// Dictation into one text box. Keeps what you had typed, adds what you say after it as you speak,
// and exposes whether it is listening and how loud you are, for the waveform. Widget plumbing,
// like a TextEditingController: each text box with a mic owns one.

import 'package:flutter/widgets.dart';

import 'speech_service.dart';

class VoiceInput extends ChangeNotifier {
  VoiceInput(this._service, this._target);
  final SpeechService _service;
  final TextEditingController _target;

  bool _listening = false;
  double _level = 0;
  String? _problem;
  bool _disposed = false;

  bool get listening => _listening;

  /// 0 (silence) to 1, for the waveform.
  double get level => _level;

  /// Why dictation could not start, once, for a snackbar. Cleared when read.
  String? takeProblem() {
    final problem = _problem;
    _problem = null;
    return problem;
  }

  Future<void> toggle() => _listening ? stop() : start();

  Future<void> start() async {
    final before = _target.text.trimRight();
    final callbacks = SpeechCallbacks(
      onWords: (words) {
        if (_disposed) return;
        final joined = before.isEmpty ? words : '$before $words';
        _target.value = TextEditingValue(
          text: joined,
          selection: TextSelection.collapsed(offset: joined.length),
        );
      },
      onLevel: (level) {
        if (_disposed) return;
        _level = level;
        notifyListeners();
      },
      onDone: () {
        if (_disposed) return;
        _listening = false;
        _level = 0;
        notifyListeners();
      },
    );
    _listening = true;
    notifyListeners();
    final started = await _service.start(callbacks);
    if (_disposed) {
      // The text box went away while the permission prompt was up: close the mic again.
      if (started) await _service.stop();
      return;
    }
    if (started) return;
    _listening = false;
    _problem = 'Parley needs microphone and speech recognition access. Turn them on in Settings.';
    notifyListeners();
  }

  Future<void> stop() => _service.stop();

  @override
  void dispose() {
    _disposed = true;
    if (_listening) _service.stop();
    super.dispose();
  }
}
