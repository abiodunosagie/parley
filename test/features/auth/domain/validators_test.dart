import 'package:flutter_test/flutter_test.dart';
import 'package:parley/features/auth/domain/validators/auth_validators.dart';

void main() {
  test('email', () {
    expect(validateEmail('me@example.com'), isNull);
    expect(validateEmail('  me@example.com '), isNull);
    expect(validateEmail('me@example'), isNotNull);
    expect(validateEmail(''), isNotNull);
  });

  test('new passwords need 8 characters, like the server', () {
    expect(validateNewPassword('1234567'), isNotNull);
    expect(validateNewPassword('12345678'), isNull);
  });

  test('existing password only needs to be filled in', () {
    expect(validateExistingPassword(''), isNotNull);
    expect(validateExistingPassword('x'), isNull);
  });

  test('names: real names pass, empty, symbols and very long names do not', () {
    for (final ok in [
      'Ada',
      'Mary-Jane',
      "O'Neil",
      'José',
      'Chukwuemeka',
      'St. John',
      'Nguyễn',
      'Mohammad\u200Cali',
    ]) {
      expect(validateName(ok, part: NamePart.first), isNull, reason: ok);
    }
    expect(validateName('   ', part: NamePart.first), 'Enter your first name.');
    expect(validateName('', part: NamePart.last), 'Enter your last name.');
    expect(validateName('Ada1', part: NamePart.first), isNotNull);
    expect(validateName('<script>', part: NamePart.first), isNotNull);
    expect(validateName('-Ada', part: NamePart.first), isNotNull);
    expect(validateName('A' * 51, part: NamePart.first), isNotNull);
  });

  test('names are saved trimmed with single spaces', () {
    expect(cleanName('  Mary   Jane '), 'Mary Jane');
  });

  group('own API key', () {
    const key = 'sk-ant-api03-abcdefghijklmnopqrstuvwxyz_-0123';

    test(
      'accepts an Anthropic key, spaces and line breaks from a paste included',
      () {
        expect(validateApiKey(key), isNull);
        expect(
          validateApiKey(' sk-ant-api03-abcdefghij\nklmnopqrstuvwxyz '),
          isNull,
        );
        expect(cleanApiKey(' sk-ant-api03-abc\ndef '), 'sk-ant-api03-abcdef');
      },
    );

    test('refuses an empty box, other providers and junk', () {
      expect(validateApiKey(''), 'Paste your Claude API key.');
      for (final bad in [
        'sk-proj-abcdefghijklmnopqrstuvwxyz',
        'sk-ant-short',
        'sk-ant-${'a' * 300}',
        'sk-ant-abc!defghijklmnopqrstuvwxyz',
      ]) {
        expect(validateApiKey(bad), isNotNull, reason: bad);
      }
    });

    test('masks all but the last four characters', () {
      expect(maskApiKey(key), 'sk-ant-...0123');
      expect(maskApiKey('short'), 'sk-ant-...');
    });
  });
}
