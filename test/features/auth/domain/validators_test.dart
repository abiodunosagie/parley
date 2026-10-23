import 'package:flutter_test/flutter_test.dart';
import 'package:parley/features/auth/domain/validators.dart';

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
}
