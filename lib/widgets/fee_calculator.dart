import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeeCalculator extends StatelessWidget {
  final int amount;
  const FeeCalculator({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    if (amount < 20) return const SizedBox.shrink();
    final fmt = NumberFormat('#,###');
    final txFee = (amount * 2.0 / 100).ceil();
    final releaseFee = (amount * 1.5 / 100).ceil();
    final buyerPays = amount + txFee;
    final sellerReceives = amount - releaseFee;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _row(context, 'Buyer pays', 'KSh ${fmt.format(buyerPays)}', bold: true),
          const SizedBox(height: 4),
          _row(context, 'Platform fee', 'KSh ${fmt.format(txFee)}'),
          const Divider(height: 12),
          _row(context, 'Seller receives', 'KSh ${fmt.format(sellerReceives)}',
              bold: true, color: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              color: color,
            )),
      ],
    );
  }
}
