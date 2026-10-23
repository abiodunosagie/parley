// FILE: features/receipt/presentation/widgets/receipt_card.dart
// A read receipt: the shop and date, spend per category as bars, every line item, then tax, tip
// and the total. Flags a total that does not add up, so a misread line gets a second look.

import 'package:flutter/material.dart';

import '../../../../core/theme/dimens.dart';
import '../../../../core/theme/parley_colors.dart';
import '../../domain/entities/receipt.dart';

class ReceiptCard extends StatelessWidget {
  const ReceiptCard(this.receipt, {super.key});
  final Receipt receipt;

  String _money(double v) => '${receipt.currency} ${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final categories = receipt.byCategory;
    final biggest = categories.isEmpty ? 1.0 : categories.first.$2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          receipt.merchant.isEmpty ? 'Receipt' : receipt.merchant,
          style: text.headlineSmall,
        ),
        if (receipt.date.isNotEmpty)
          Text(receipt.date, style: TextStyle(color: colors.muted)),
        const SizedBox(height: 16),
        Text('By category', style: text.titleSmall),
        const SizedBox(height: 8),
        for (final (category, amount) in categories)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(width: 92, child: Text(category.label)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: kRadius,
                    child: LinearProgressIndicator(
                      value: biggest <= 0 ? 0 : amount / biggest,
                      minHeight: 10,
                      color: colors.accent,
                      backgroundColor: colors.accentSoft,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 96,
                  child: Text(_money(amount), textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Divider(color: colors.line),
        for (final item in receipt.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.quantity == 1
                        ? item.name
                        : '${_quantity(item.quantity)} × ${item.name}',
                  ),
                ),
                Text(_money(item.price)),
              ],
            ),
          ),
        Divider(color: colors.line),
        if (receipt.tax > 0) _TotalRow('Tax', _money(receipt.tax)),
        if (receipt.tip > 0) _TotalRow('Tip', _money(receipt.tip)),
        _TotalRow('Total', _money(receipt.total), strong: true),
        if (receipt.totalMismatch)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'The lines add up to ${_money(receipt.itemsTotal + receipt.tax + receipt.tip)}, not the printed total. Check the photo for a missed line.',
              style: TextStyle(color: colors.danger),
            ),
          ),
      ],
    );
  }

  static String _quantity(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
