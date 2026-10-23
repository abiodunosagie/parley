// FILE: core/widgets/composer.dart
// The message box at the bottom of Chat, Look, Read and Tasks. With an empty box the round button is a mic:
// tap it, speak, and your words appear in the box as you say them while a waveform moves with
// your voice. Tap the button again (or go quiet) to finish, edit if needed, then send. While
// Claude is replying, the button turns into Stop, which cancels the request.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../speech/speech_service.dart';
import '../speech/voice_input.dart';
import '../theme/dimens.dart';
import '../theme/parley_colors.dart';
import 'voice_wave.dart';

class Composer extends ConsumerStatefulWidget {
  const Composer({
    super.key,
    required this.busy,
    required this.onSend,
    required this.onStop,
    this.hint = 'Message Parley',
  });

  final bool busy;
  final ValueChanged<String> onSend;
  final VoidCallback onStop;
  final String hint;

  @override
  ConsumerState<Composer> createState() => _ComposerState();
}

enum _Action { send, stop, dictate, finishDictation }

class _ComposerState extends ConsumerState<Composer> {
  final _controller = TextEditingController();
  late final _voice = VoiceInput(ref.read(speechServiceProvider), _controller);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
    _voice.addListener(_voiceChanged);
  }

  @override
  void dispose() {
    _voice
      ..removeListener(_voiceChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  void _voiceChanged() {
    if (!mounted) return;
    final problem = _voice.takeProblem();
    if (problem != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
    }
    setState(() {});
  }

  _Action get _action {
    if (widget.busy) return _Action.stop;
    if (_voice.listening) return _Action.finishDictation;
    return _controller.text.trim().isEmpty ? _Action.dictate : _Action.send;
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.busy) return;
    _controller.clear();
    widget.onSend(text);
  }

  void _press() => switch (_action) {
    _Action.send => _send(),
    _Action.stop => widget.onStop(),
    _Action.dictate || _Action.finishDictation => _voice.toggle(),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final action = _action;
    final (icon, tooltip) = switch (action) {
      _Action.send => (Icons.arrow_upward_rounded, 'Send'),
      _Action.stop => (Icons.stop_rounded, 'Stop'),
      _Action.dictate => (Icons.mic_none_rounded, 'Dictate'),
      _Action.finishDictation => (Icons.check_rounded, 'Finish dictation'),
    };
    // Stop shows ink-on-background, everything else the accent pair.
    final background = action == _Action.stop ? colors.ink : colors.accent;
    final foreground = action == _Action.stop
        ? colors.background
        : colors.onAccent;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              child: _voice.listening
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Row(
                        children: [
                          VoiceWave(level: _voice.level),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Listening. Tap the tick when you are done.',
                              style: TextStyle(color: colors.muted),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(hintText: widget.hint),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox.square(
                  dimension: 48,
                  child: IconButton.filled(
                    onPressed: _press,
                    tooltip: tooltip,
                    style: IconButton.styleFrom(
                      backgroundColor: background,
                      foregroundColor: foreground,
                      shape: const RoundedRectangleBorder(
                        borderRadius: kRadius,
                      ),
                    ),
                    icon: Icon(icon),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
