import 'package:flutter_test/flutter_test.dart';
import 'package:parley/features/receipt/domain/entities/receipt.dart';

Receipt _receipt({double total = 10.45}) => Receipt.fromJson({
  'is_receipt': true,
  'merchant': 'CAFE LUMA',
  'date': '2026-10-20',
  'currency': 'EUR',
  'items': [
    {'name': 'Espresso', 'quantity': 2, 'price': 3, 'category': 'drinks'},
    {'name': 'Croissant', 'quantity': 1, 'price': 2.5, 'category': 'food'},
    {'name': 'Orange juice', 'quantity': 1, 'price': 3.2, 'category': 'drinks'},
    {'name': 'Water', 'quantity': 1, 'price': 1, 'category': 'unknown'},
  ],
  'tax': 0.75,
  'tip': 0,
  'total': total,
});

void main() {
  test('adds up spend per category, biggest first; unknown categories count as other', () {
    final byCategory = _receipt().byCategory;
    expect(byCategory.first.$1, ReceiptCategory.drinks);
    expect(byCategory.first.$2, closeTo(6.2, 1e-9));
    expect(byCategory.map((e) => e.$1), contains(ReceiptCategory.other));
  });

  test('a total that matches items plus tax is not flagged', () {
    expect(_receipt().totalMismatch, isFalse);
    expect(_receipt(total: 12).totalMismatch, isTrue);
  });

  test('survives a save and load', () {
    final again = Receipt.fromJson(_receipt().toJson());
    expect(again.items.length, 4);
    expect(again.items.last.category, ReceiptCategory.other);
    expect(again.total, 10.45);
  });
}
