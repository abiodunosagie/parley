import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parley/core/speech/voice_input.dart';

import '../../helpers/fakes.dart';

void main() {
  test(
    'dictation adds after what was typed and ends when listening stops',
    () async {
      final speech = FakeSpeech();
      final text = TextEditingController(text: 'Remind me');
      final voice = VoiceInput(speech, text);
      await voice.start();
      expect(voice.listening, isTrue);

      speech.say('to call');
      speech.say('to call mum');
      expect(text.text, 'Remind me to call mum');
      expect(voice.level, greaterThan(0));

      speech.finish();
      expect(voice.listening, isFalse);
      expect(voice.level, 0);
    },
  );

  test('no permission leaves a message once and stops listening', () async {
    final voice = VoiceInput(
      FakeSpeech(available: false),
      TextEditingController(),
    );
    await voice.start();
    expect(voice.listening, isFalse);
    expect(voice.takeProblem(), contains('microphone'));
    expect(voice.takeProblem(), isNull);
  });

  test(
    'the final words that arrive just after stopping still land in the box',
    () async {
      final speech = FakeSpeech();
      final text = TextEditingController();
      final voice = VoiceInput(speech, text);
      await voice.start();
      speech.say('call mom');
      final active = speech.active!;
      await voice.stop();
      active.onWords('call mum');
      expect(text.text, 'call mum');
    },
  );

  test(
    'closing the box while the permission prompt is up closes the mic',
    () async {
      final speech = FakeSpeech();
      final voice = VoiceInput(speech, TextEditingController());
      final starting = voice.start();
      voice.dispose();
      await starting;
      expect(speech.active, isNull);
    },
  );
}
