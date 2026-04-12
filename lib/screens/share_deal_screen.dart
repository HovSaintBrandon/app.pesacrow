import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/escrow_badge.dart';
import '../core/notifications.dart';
import 'main_scaffold.dart';

class ShareDealScreen extends StatefulWidget {
  final String transactionId;
  final Map<String, dynamic>? feeBreakdown;

  const ShareDealScreen({super.key, required this.transactionId, this.feeBreakdown});

  @override
  State<ShareDealScreen> createState() => _ShareDealScreenState();
}

class _ShareDealScreenState extends State<ShareDealScreen> {
  static const _blue = Color(0xFF3182CE);

  void _copyTxId() {
    Clipboard.setData(ClipboardData(text: widget.transactionId));
    AppNotifications.showSuccess(context, 'Transaction ID copied!');
  }

  void _shareToWhatsApp() {
    final String shareUrl = 'https://pesacrow.app/join/${widget.transactionId}';
    final String shareText = 'Hey! I created a secure deal on PesaCrow.\n\nUse this ID: ${widget.transactionId}\nor join here: $shareUrl';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fmt = NumberFormat('#,###');
    final fee = widget.feeBreakdown;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Deal Secured', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 24,
                vertical: 40,
              ),
              child: Column(
                children: [
                  // Success Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _blue.withOpacity(0.12),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: _blue.withOpacity(0.08), blurRadius: 40, spreadRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.verified_rounded, color: _blue, size: 60),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(duration: 1.seconds, begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), curve: Curves.easeInOut),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'Deal Created Successfully!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: isDesktop ? 36 : 28, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, letterSpacing: -1),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  
                  const SizedBox(height: 12),
                  
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Text(
                      'Your escrow link is live. Share it with the buyer to receive payment securely.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 54),

                  // Content Layout
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _buildShareCard(theme)),
                        const SizedBox(width: 32),
                        if (fee != null) Expanded(flex: 4, child: _buildFinancialSection(theme, fmt, fee)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildShareCard(theme),
                        if (fee != null) ...[
                          const SizedBox(height: 32),
                          _buildFinancialSection(theme, fmt, fee),
                        ],
                      ],
                    ),

                  const SizedBox(height: 60),

                  // Actions
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _shareToWhatsApp,
                          icon: const Icon(Icons.share_rounded, size: 22),
                          label: const Text('SHARE ON WHATSAPP'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            minimumSize: const Size(double.infinity, 70),
                          ),
                        ).animate().fadeIn(delay: 600.ms),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScaffold()), (_) => false),
                          icon: const Icon(Icons.dashboard_rounded, size: 22),
                          label: const Text('BACK TO DASHBOARD'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 70),
                            side: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                        ).animate().fadeIn(delay: 700.ms),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),
                  const EscrowBadge(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: QrImageView(
              data: widget.transactionId,
              version: QrVersions.auto,
              size: 220.0,
              foregroundColor: Colors.black,
            ),
          ),
          const SizedBox(height: 40),
          
          Text(
            'TRANSACTION ID',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          
          GestureDetector(
            onTap: _copyTxId,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.transactionId,
                      style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 18, color: theme.colorScheme.primary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.copy_rounded, size: 20, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildFinancialSection(ThemeData theme, NumberFormat fmt, Map<String, dynamic> fee) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BREAKDOWN',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 2),
          ),
          const SizedBox(height: 24),
          _receiptRow('Held Amount', 'KSh ${fmt.format(fee['heldAmount'] ?? 0)}'),
          if ((fee['bouquetCharge'] ?? 0) > 0)
            _receiptRow('Bouquet Fee', '+ KSh ${fmt.format(fee['bouquetCharge'])}'),
          _receiptRow('Escrow Fee', '+ KSh ${fmt.format(fee['transactionFee'] ?? 0)}'),
          _receiptRow('Disbursement', '- KSh ${fmt.format(fee['releaseFee'] ?? 0)}'),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(color: Colors.white10),
          ),
          
          _receiptRow('Total Buyer Pays', 'KSh ${fmt.format(fee['buyerPays'] ?? fee['paidAmount'] ?? 0)}', isSecondary: true),
          const SizedBox(height: 12),
          _receiptRow('Your Payout', 'KSh ${fmt.format(fee['amountToSeller'] ?? 0)}', isTotal: true, color: const Color(0xFF2E9D5B)),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _receiptRow(String label, String value, {bool isTotal = false, bool isSecondary = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.grey.shade400 : Colors.grey.shade500,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              fontSize: isTotal ? 20 : 15,
              color: color ?? (isTotal ? Colors.white : (isSecondary ? Colors.grey.shade300 : Colors.grey.shade400)),
            ),
          ),
        ],
      ),
    );
  }
}
