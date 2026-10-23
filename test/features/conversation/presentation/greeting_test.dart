import 'package:flutter_test/flutter_test.dart';
import 'package:parley/features/conversation/presentation/widgets/greeting.dart';

void main() {
  DateTime at(int hour) => DateTime(2026, 10, 23, hour);

  test('greets by the time of day', () {
    expect(greetingFor(at(5), 'Ada'), 'Good morning, Ada.');
    expect(greetingFor(at(11), 'Ada'), 'Good morning, Ada.');
    expect(greetingFor(at(12), 'Ada'), 'Good afternoon, Ada.');
    expect(greetingFor(at(16), 'Ada'), 'Good afternoon, Ada.');
    expect(greetingFor(at(17), 'Ada'), 'Good evening, Ada.');
    expect(greetingFor(at(2), 'Ada'), 'Good evening, Ada.');
  });

  test('without a name it still greets', () {
    expect(greetingFor(at(9), ''), 'Good morning.');
    expect(greetingFor(at(9), '  '), 'Good morning.');
  });
}
