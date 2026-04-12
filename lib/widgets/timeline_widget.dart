import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimelineEvent {
  final String label;
  final String? timestamp;
  final bool isCompleted;
  final bool isActive;
  final IconData icon;
  final Color color;

  const TimelineEvent({
    required this.label,
    this.timestamp,
    required this.isCompleted,
    required this.isActive,
    required this.icon,
    required this.color,
  });
}

class TimelineWidget extends StatelessWidget {
  final List<TimelineEvent> events;

  const TimelineWidget({super.key, required this.events});

  /// Builds a deal timeline from status + optional timestamps
  static List<TimelineEvent> fromDeal({
    required String status,
    String? createdAt,
    String? paymentConfirmedAt,
    String? deliveredAt,
    String? approvedAt,
  }) {
    final steps = ['pending_payment', 'held', 'delivered', 'released'];
    final currentIdx = steps.indexOf(status == 'approved' ? 'released' : status);

    return [
      TimelineEvent(
        label: 'Deal Created',
        timestamp: _formatTs(createdAt),
        isCompleted: true,
        isActive: currentIdx == 0,
        icon: Icons.add_circle_outline,
        color: const Color(0xFF2E9D5B),
      ),
      TimelineEvent(
        label: 'Payment Secured',
        timestamp: _formatTs(paymentConfirmedAt),
        isCompleted: currentIdx >= 1,
        isActive: currentIdx == 1,
        icon: Icons.lock_outline,
        color: const Color(0xFF2E9D5B),
      ),
      TimelineEvent(
        label: 'Item Delivered',
        timestamp: _formatTs(deliveredAt),
        isCompleted: currentIdx >= 2,
        isActive: currentIdx == 2,
        icon: Icons.local_shipping_outlined,
        color: const Color(0xFF3182CE),
      ),
      TimelineEvent(
        label: 'Funds Released',
        timestamp: _formatTs(approvedAt),
        isCompleted: currentIdx >= 3,
        isActive: currentIdx == 3,
        icon: Icons.check_circle_outline,
        color: const Color(0xFF2E9D5B),
      ),
    ];
  }

  static String _formatTs(String? ts) {
    if (ts == null || ts.isEmpty) return 'Pending';
    try {
      final dt = DateTime.parse(ts).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]}, $h:$m';
    } catch (_) {
      return ts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(events.length, (i) {
        final event = events[i];
        final isLast = i == events.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: icon + connector line
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: event.isCompleted
                            ? event.color
                            : (event.isActive ? event.color.withOpacity(0.1) : Colors.grey.shade100),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: event.isCompleted || event.isActive ? event.color : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        event.isCompleted ? Icons.check : event.icon,
                        size: 16,
                        color: event.isCompleted
                            ? Colors.white
                            : (event.isActive ? event.color : Colors.grey.shade400),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: event.isCompleted ? event.color.withOpacity(0.3) : Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right: label + timestamp
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.label,
                        style: GoogleFonts.inter(
                          fontWeight: event.isActive || event.isCompleted ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                          color: event.isCompleted || event.isActive
                              ? const Color(0xFF1A1A1A)
                              : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.timestamp ?? 'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          color: event.isCompleted
                              ? event.color
                              : Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
