// FILE: core/widgets/voice_button.dart
// A mic button for any text box: tap to dictate into [controller], tap again (or go quiet) to
// stop. While listening it shows the live waveform instead of the mic.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../speech/speech_service.dart';
import '../speech/voice_input.dart';
import 'voice_wave.dart';

class VoiceButton extends ConsumerStatefulWidget {
  const VoiceButton({super.key, required this.controller});
  final TextEditingController controller;

  @override
  ConsumerState<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends ConsumerState<VoiceButton> {
  late final _voice = VoiceInput(
    ref.read(speechServiceProvider),
    widget.controller,
  )..addListener(_changed);

  void _changed() {
    if (!mounted) return;
    final problem = _voice.takeProblem();
    if (problem != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
    }
    setState(() {});
  }

  @override
  void dispose() {
    _voice
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _voice.listening ? 'Stop dictation' : 'Dictate',
      onPressed: _voice.toggle,
      icon: _voice.listening
          ? VoiceWave(level: _voice.level, bars: 4, height: 20)
          : const Icon(Icons.mic_none),
    );
  }
}
