// FILE: features/receipt/domain/entities/receipt.dart
// A receipt as Claude read it from a photo: the shop, the date, each line item with a category,
// and the totals. The shape matches RECEIPT_SCHEMA in supabase/functions/claude/schemas.ts.

import 'package:meta/meta.dart';

/// The categories Claude sorts items into. Must match RECEIPT_CATEGORIES on the server.
enum ReceiptCategory {
  food('Food'),
  drinks('Drinks'),
  groceries('Groceries'),
  household('Household'),
  transport('Transport'),
  health('Health'),
  other('Other');

  const ReceiptCategory(this.label);
  final String label;

  static ReceiptCategory parse(Object? value) =>
      values.asNameMap()[value] ?? ReceiptCategory.other;
}

@immutable
class ReceiptItem {
  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.category,
  });

  final String name;
  final double quantity;

  /// The line total for this item.
  final double price;
  final ReceiptCategory category;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
    name: json['name'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
    price: (json['price'] as num?)?.toDouble() ?? 0,
    category: ReceiptCategory.parse(json['category']),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'price': price,
    'category': category.name,
  };
}

@immutable
class Receipt {
  const Receipt({
    required this.isReceipt,
    required this.merchant,
    required this.date,
    required this.currency,
    required this.items,
    required this.tax,
    required this.tip,
    required this.total,
  });

  /// False when the photo was not a receipt at all.
  final bool isReceipt;
  final String merchant;

  /// YYYY-MM-DD as printed, or empty.
  final String date;

  /// Three-letter code, for example EUR.
  final String currency;
  final List<ReceiptItem> items;
  final double tax;
  final double tip;

  /// The grand total printed on the receipt.
  final double total;

  /// What the item lines add up to, before tax and tip.
  double get itemsTotal => items.fold(0, (sum, item) => sum + item.price);

  /// True when the printed total does not match items plus tax and tip (to the cent). Worth a
  /// second look: a line may have been misread or left out.
  bool get totalMismatch => (itemsTotal + tax + tip - total).abs() >= 0.01;

  /// Spend per category, biggest first. Categories with no items are left out.
  List<(ReceiptCategory, double)> get byCategory {
    final sums = <ReceiptCategory, double>{};
    for (final item in items) {
      sums.update(
        item.category,
        (v) => v + item.price,
        ifAbsent: () => item.price,
      );
    }
    return [for (final e in sums.entries) (e.key, e.value)]
      ..sort((a, b) => b.$2.compareTo(a.$2));
  }

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
    isReceipt: json['is_receipt'] == true,
    merchant: json['merchant'] as String? ?? '',
    date: json['date'] as String? ?? '',
    currency: json['currency'] as String? ?? '',
    items: [
      for (final item in (json['items'] as List? ?? const []).whereType<Map>())
        ReceiptItem.fromJson(Map<String, dynamic>.from(item)),
    ],
    tax: (json['tax'] as num?)?.toDouble() ?? 0,
    tip: (json['tip'] as num?)?.toDouble() ?? 0,
    total: (json['total'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'is_receipt': isReceipt,
    'merchant': merchant,
    'date': date,
    'currency': currency,
    'items': [for (final item in items) item.toJson()],
    'tax': tax,
    'tip': tip,
    'total': total,
  };
}
