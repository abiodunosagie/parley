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
}
