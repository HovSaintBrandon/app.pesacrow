import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Hakikisha-style confirmation bottom sheet for high-stakes financial actions.
/// Shows a full breakdown and forces user to explicitly confirm before executing.
Future<bool> showHakikishaModal(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required Color confirmColor,
  required List<HakikishaRow> rows,
  String escrowNote = 'Your money goes to PesaCrow Escrow — not the seller directly. It is only released when you confirm delivery.',
  IconData icon = Icons.verified_user_outlined,
}) async {
  final screenWidth = MediaQuery.of(context).size.width;
  final isDesktop = screenWidth >= 1024;

  if (isDesktop) {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _HakikishaSheet(
            title: title,
            confirmLabel: confirmLabel,
            confirmColor: confirmColor,
            rows: rows,
            escrowNote: escrowNote,
            icon: icon,
            isDialog: true,
          ),
        ),
      ),
    );
    return result ?? false;
  }

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _HakikishaSheet(
      title: title,
      confirmLabel: confirmLabel,
      confirmColor: confirmColor,
      rows: rows,
      escrowNote: escrowNote,
      icon: icon,
      isDialog: false,
    ),
  );
  return result ?? false;
}

class HakikishaRow {
  final String label;
  final String value;
  final bool isBold;
  final bool isDivider;

  const HakikishaRow(this.label, this.value, {this.isBold = false, this.isDivider = false});
  const HakikishaRow.divider() : label = '', value = '', isBold = false, isDivider = true;
}

class _HakikishaSheet extends StatefulWidget {
  final String title, confirmLabel, escrowNote;
  final Color confirmColor;
  final List<HakikishaRow> rows;
  final IconData icon;
  final bool isDialog;

  const _HakikishaSheet({
    required this.title,
    required this.confirmLabel,
    required this.confirmColor,
    required this.rows,
    required this.escrowNote,
    required this.icon,
    required this.isDialog,
  });

  @override
  State<_HakikishaSheet> createState() => _HakikishaSheetState();
}

class _HakikishaSheetState extends State<_HakikishaSheet> {
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(32, widget.isDialog ? 32 : 16, 32, 32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: widget.isDialog ? BorderRadius.circular(28) : const BorderRadius.vertical(top: Radius.circular(32)),
        border: widget.isDialog ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.isDialog)
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
              ),
            ),

          // Icon + Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.confirmColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.confirmColor, size: 28),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Breakdown rows
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08)),
            ),
            child: Column(
              children: widget.rows.map((row) {
                if (row.isDivider) return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.1)));
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        row.label,
                        style: TextStyle(
                          color: row.isBold ? theme.colorScheme.onSurface : Colors.grey.shade500,
                          fontSize: row.isBold ? 15 : 14,
                          fontWeight: row.isBold ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                      Text(
                        row.value,
                        style: GoogleFonts.inter(
                          fontSize: row.isBold ? 18 : 14,
                          fontWeight: row.isBold ? FontWeight.w900 : FontWeight.w600,
                          color: row.isBold ? widget.confirmColor : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Escrow note
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF2E9D5B).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFF2E9D5B), size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.escrowNote,
                    style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Confirm Button
          ElevatedButton(
            onPressed: _confirming ? null : () {
              setState(() => _confirming = true);
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.confirmColor,
              minimumSize: const Size(double.infinity, 64),
            ),
            child: _confirming
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                : Text(widget.confirmLabel),
          ),
          const SizedBox(height: 16),

          // Cancel
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 64)),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
