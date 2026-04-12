import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/deal.dart';

class FinanceHubOverlay extends StatelessWidget {
  final String pendingDeals;
  final String escrowHeld;
  final Color accentColor;
  final List<Deal> recentDeals;

  const FinanceHubOverlay({
    super.key,
    required this.pendingDeals,
    required this.escrowHeld,
    required this.accentColor,
    required this.recentDeals,
  });

  static void show(BuildContext context, {
    required String pendingDeals,
    required String escrowHeld,
    required Color accentColor,
    required List<Deal> recentDeals,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FinanceHubOverlay(
        pendingDeals: pendingDeals,
        escrowHeld: escrowHeld,
        accentColor: accentColor,
        recentDeals: recentDeals,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0A), // Cyber Dark
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'FINANCE HUB',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Balance Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentColor.withOpacity(0.2), Colors.transparent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total in Escrow', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                          const SizedBox(height: 8),
                          Text(
                            escrowHeld,
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const Divider(height: 32, color: Colors.white10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Pending Deals', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                              Text(
                                pendingDeals,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),

                    const SizedBox(height: 40),

                    Text(
                      'RECENT ACTIVITY',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.3),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (recentDeals.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text('No recent activity', style: TextStyle(color: Colors.white.withOpacity(0.2))),
                        ),
                      )
                    else
                      ...recentDeals.take(10).indexed.map((entry) => _HistoryItem(deal: entry.$2, index: entry.$1)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}



class _HistoryItem extends StatelessWidget {
  final Deal deal;
  final int index;
  const _HistoryItem({required this.deal, required this.index});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/deal/${deal.transactionId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(deal.status).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getStatusIcon(deal.status), size: 16, color: _getStatusColor(deal.status)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deal.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(deal.transactionId.toUpperCase(), style: TextStyle(color: Colors.white30, fontSize: 10, fontFamily: 'monospace')),
                ],
              ),
            ),
            Text('${_isOutgoing(deal.status) ? '-' : '+'} KSh ${fmt.format(deal.amount)}', 
              style: TextStyle(color: _isOutgoing(deal.status) ? Colors.white70 : const Color(0xFF2E9D5B), fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
      ),
    ).animate(delay: (400 + (index * 50)).ms).fadeIn().slideX(begin: 0.1);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'released': case 'approved': return const Color(0xFF2E9D5B);
      case 'held': return Colors.orange;
      case 'delivered': return Colors.blue;
      case 'disputed': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'released': case 'approved': return Icons.check_circle_outline;
      case 'held': return Icons.lock_outline;
      case 'delivered': return Icons.local_shipping_outlined;
      case 'disputed': return Icons.gavel_outlined;
      default: return Icons.compare_arrows_rounded;
    }
  }

  bool _isOutgoing(String status) {
    // Just a placeholder logic for history sign
    return status == 'held' || status == 'pending_payment';
  }
}
