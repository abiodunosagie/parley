import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parley/core/theme/app_theme.dart';
import 'package:parley/core/widgets/composer.dart';
import 'package:parley/core/widgets/keyboard_dismiss.dart';

/// KeyboardDismiss wraps every screen (app/app.dart). It must close the keyboard on a tap outside
/// a field, and never steal the tap that should open it.
Widget _app() => MaterialApp(
  theme: parleyTheme(Brightness.light),
  builder: (context, child) => KeyboardDismiss(child: child!),
  home: Scaffold(
    body: Column(
      children: [
        const Expanded(child: SizedBox.expand()),
        Composer(busy: false, onSend: (_) {}, onStop: () {}),
      ],
    ),
  ),
);

void main() {
  testWidgets('tapping the message box focuses it and opens the keyboard', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('tapping outside the box closes the keyboard', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.tapAt(const Offset(200, 100));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
  });
}
