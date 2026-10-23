import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parley/core/models/saved_summary.dart';
import 'package:parley/core/theme/app_theme.dart';
import 'package:parley/core/widgets/history_sheet.dart';

final _entries = FutureProvider<List<SavedSummary>>(
  (ref) async => [
    SavedSummary(
      id: 'a',
      title: 'First chat',
      updatedAt: DateTime.utc(2026, 10, 23),
    ),
    SavedSummary(
      id: 'b',
      title: 'Second chat',
      updatedAt: DateTime.utc(2026, 10, 22),
    ),
  ],
);

void main() {
  testWidgets('swiping a row deletes it and it leaves the list at once', (
    tester,
  ) async {
    final deleted = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: parleyTheme(Brightness.light),
          home: Scaffold(
            body: HistorySheet(
              entries: _entries,
              onOpen: (_) {},
              onDelete: deleted.add,
              empty: 'Nothing',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.text('First chat'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(deleted, ['a']);
    expect(find.text('First chat'), findsNothing);
    expect(find.text('Second chat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('history dates read naturally', () {
    final now = DateTime(2026, 10, 23, 18);
    expect(whenLabel(DateTime(2026, 10, 23, 9, 5), now: now), 'Today 09:05');
    expect(whenLabel(DateTime(2026, 10, 22, 23), now: now), 'Yesterday');
    expect(whenLabel(DateTime(2026, 10, 19), now: now), 'Mon 19 Oct');
    expect(whenLabel(DateTime(2025, 10, 19), now: now), 'Sun 19 Oct 2025');
  });
}
