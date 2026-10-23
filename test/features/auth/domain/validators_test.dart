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
    ]) {
      expect(validateName(ok, which: 'first'), isNull, reason: ok);
    }
    expect(validateName('   ', which: 'first'), 'Enter your first name.');
    expect(validateName('', which: 'last'), 'Enter your last name.');
    expect(validateName('Ada1', which: 'first'), isNotNull);
    expect(validateName('<script>', which: 'first'), isNotNull);
    expect(validateName('-Ada', which: 'first'), isNotNull);
    expect(validateName('A' * 51, which: 'first'), isNotNull);
  });

  test('names are saved trimmed with single spaces', () {
    expect(cleanName('  Mary   Jane '), 'Mary Jane');
  });
}
