import 'package:flutter/material.dart';

/// Persistent "Escrow Protected by PesaCrow" badge.
/// Used at the bottom of all transaction screens.
class EscrowBadge extends StatelessWidget {
  final bool showBorder;
  const EscrowBadge({super.key, this.showBorder = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: showBorder
          ? BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
            )
          : null,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_outlined, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Text(
              'Escrow Protected by PesaCrow',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
