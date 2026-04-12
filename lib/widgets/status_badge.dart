import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig[status] ?? _StatusConfig('Unknown', Colors.grey, Colors.grey.shade100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Text(
        config.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: config.color),
      ),
    );
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  final Color bg;
  _StatusConfig(this.label, this.color, this.bg);
}

final _statusConfig = {
  'pending_payment': _StatusConfig('Pending Payment', const Color(0xFFD69E2E), const Color(0xFFFEFCBF)),
  'held': _StatusConfig('Funds Held', const Color(0xFF3182CE), const Color(0xFFEBF8FF)),
  'delivered': _StatusConfig('Delivered', const Color(0xFF2E9D5B), const Color(0xFFE8F5EE)),
  'released': _StatusConfig('Released', const Color(0xFF2E9D5B), const Color(0xFFE8F5EE)),
  'approved': _StatusConfig('Approved', const Color(0xFF2E9D5B), const Color(0xFFE8F5EE)),
  'disputed': _StatusConfig('Disputed', const Color(0xFFE53E3E), const Color(0xFFFFF5F5)),
  'failed': _StatusConfig('Failed', const Color(0xFFE53E3E), const Color(0xFFFFF5F5)),
  'cancelled': _StatusConfig('Cancelled', Colors.grey, Colors.grey.shade100),
  'refunded': _StatusConfig('Refunded', Colors.grey, Colors.grey.shade100),
};
