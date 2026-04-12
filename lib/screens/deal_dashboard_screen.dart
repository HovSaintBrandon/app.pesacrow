import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/deal.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';
import '../core/notifications.dart';
import '../widgets/status_badge.dart';
import '../widgets/step_wizard.dart';
import '../widgets/timeline_widget.dart';
import '../widgets/escrow_badge.dart';
import '../widgets/hakikisha_modal.dart';
import 'payment_screen.dart';
import 'dispute_screen.dart';
import 'proof_upload_screen.dart';
import '../services/receipt_service.dart';
import '../models/fee_breakdown.dart';
import '../services/fee_service.dart';
import '../utils/phone_formatter.dart';


class DealDashboardScreen extends StatefulWidget {
  final String transactionId;
  const DealDashboardScreen({super.key, required this.transactionId});

  @override
  State<DealDashboardScreen> createState() => _DealDashboardScreenState();
}

class _DealDashboardScreenState extends State<DealDashboardScreen> {
  Deal? _deal;
  bool _loading = true;
  bool _actionLoading = false;
  FeeBreakdown? _feeBreakdown;
  bool _fetchingFees = false;
  late ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));
    _fetchDeal();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDeal() async {
    LoggerService.logEvent('DEAL_FETCH', {'transactionId': widget.transactionId});
    try {
      final deal = await ApiService.getDealDetails(widget.transactionId);
      if (mounted) {
        setState(() {
          _deal = deal;
          _loading = false;
          _fetchingFees = true;
        });
        _loadFees(deal.amount.toDouble());
        if (deal.status == 'released' || deal.status == 'approved') {
          _confettiCtrl.play();
        }
      }
    } catch (e) {
      LoggerService.logError('Fetch deal failed', e);
      if (mounted) setState(() => _loading = false);
      AppNotifications.showError(context, 'Failed to load deal details');
    }
  }

  Future<void> _loadFees(double amount) async {
    try {
      final breakdown = await FeeService.calculateFees(amount);
      if (mounted) {
        setState(() {
          _feeBreakdown = breakdown;
          _fetchingFees = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _fetchingFees = false);
      LoggerService.logError('Load dashboard fees failed', e);
    }
  }



  Future<void> _doAction(Future<void> Function() action, String successMsg) async {
    HapticFeedback.mediumImpact();
    setState(() => _actionLoading = true);
    try {
      await action();
      LoggerService.logEvent('DEAL_ACTION_SUCCESS', {'transactionId': widget.transactionId});
      AppNotifications.showSuccess(context, successMsg);
      _fetchDeal();
    } catch (e) {
      LoggerService.logError('Deal action failed', e);
      AppNotifications.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _nudgeBuyer() async {
    LoggerService.logEvent('DEAL_NUDGE_BUYER', {'transactionId': widget.transactionId});
    final url = 'whatsapp://send?phone=${_deal!.buyerPhone}&text=Hey! I\'ve delivered the item for our deal (${_deal!.transactionId}). Please approve the payout on PesaCrow when you\'re happy. 🙏';
    try {
      await launchUrl(Uri.parse(url));
    } catch (_) {
      AppNotifications.showError(context, 'Could not open WhatsApp');
    }
  }

  void _copyTxId() {
    Clipboard.setData(ClipboardData(text: _deal!.transactionId));
    AppNotifications.showSuccess(context, 'Transaction ID copied');
  }

  Future<void> _cancelDeal() async {
    final fmt = NumberFormat('#,###');
    final isPaid = _deal!.status == 'held';

    final confirmed = await showHakikishaModal(
      context,
      title: 'Cancel This Deal?',
      confirmLabel: 'YES, CANCEL DEAL',
      confirmColor: Colors.red,
      icon: Icons.cancel_outlined,
      escrowNote: isPaid
          ? 'This deal has been paid. Cancelling will trigger an automatic M-Pesa reversal (refund) to the buyer.'
          : 'This deal is not yet paid. Cancelling will permanently close this transaction.',
      rows: [
        HakikishaRow('Description', _deal!.description),
        HakikishaRow('Amount', 'KSh ${fmt.format(_deal!.amount)}'),
        const HakikishaRow.divider(),
        HakikishaRow('Action', isPaid ? 'Reverse Payment' : 'Close Deal', isBold: true),
      ],
    );

    if (confirmed) {
      _doAction(() => ApiService.cancelDeal(_deal!.transactionId), 'Deal cancelled successfully');
    }
  }

  Future<void> _retryPayout() async {
    final phoneCtrl = TextEditingController(text: context.read<AuthProvider>().phone ?? '');
    bool isConfirming = false;
    bool isLoading = false;
    String? errorMsg;
    final fmt = NumberFormat('#,###');

    String formatPhone(String raw) {
      String p = raw.replaceAll(RegExp(r'\D'), '');
      if (p.isEmpty) return '';
      if (p.startsWith('0')) return '254${p.substring(1)}';
      if (p.startsWith('254')) return p;
      if (p.startsWith('7') || p.startsWith('1')) return '254$p';
      return p;
    }

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          Widget buildEntryStep() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.error_outline, color: Colors.red.shade600, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Payout Failed', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800))),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Your previous payout was rejected by M-Pesa. This typically happens if an account limit was reached or your Payout profile routing failed.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'To safely recover your funds instantly, please enter a valid standard personal M-Pesa number.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade900),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  decoration: InputDecoration(
                    labelText: 'Replacement M-Pesa Phone',
                    hintText: 'e.g. 0712345678 or 254...',
                    helperText: 'Kenyan lines starting with 07, 01, or 254',
                    errorText: errorMsg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.phone_android),
                  ),
                  onChanged: (v) {
                    if (errorMsg != null) setState(() => errorMsg = null);
                  },
                ),
              ],
            );
          }

          Widget buildConfirmStep() {
            final formatted = formatPhone(phoneCtrl.text);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.verified_user_outlined, color: Colors.orange.shade700, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Confirm Retry', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800))),
                  ],
                ),
                const SizedBox(height: 20),
                if (errorMsg != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(errorMsg!, style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    children: [
                      const Text('Deal Value', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('KSh ${fmt.format(_deal!.amount)}', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(ctx).colorScheme.primary)),
                      const Divider(height: 24),
                      const Text('Payout Directly To', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(PhoneFormatter.formatForDisplay(formatted), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('By confirming, an immediate disbursement request will be queued to this M-Pesa line. Please ensure this number is correct.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600, height: 1.4),
                ),
              ],
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(24),
            content: isConfirming ? buildConfirmStep() : buildEntryStep(),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            actions: [
              if (!isConfirming) ...[
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final p = formatPhone(phoneCtrl.text);
                    if (p.length < 12 || !p.startsWith('254')) {
                      setState(() => errorMsg = 'Please enter a valid Kenyan number');
                      return;
                    }
                    setState(() {
                      isConfirming = true;
                      errorMsg = null;
                    });
                  },
                  child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ] else ...[
                TextButton(
                  onPressed: isLoading ? null : () => setState(() { isConfirming = false; errorMsg = null; }),
                  child: const Text('BACK', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: isLoading ? null : () async {
                    setState(() { isLoading = true; errorMsg = null; });
                    try {
                      final p = formatPhone(phoneCtrl.text);
                      await ApiService.retryPayoutSeller(_deal!.transactionId, p);
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      setState(() {
                        isLoading = false;
                        errorMsg = e.toString().replaceFirst('Exception: ', '');
                      });
                    }
                  },
                  child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('CONFIRM SETUP', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ],
            ],
          );
        },
      ),
    );

    if (success == true) {
      AppNotifications.showSuccess(context, 'Payout retry initiated successfully!');
      _fetchDeal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isBuyer = auth.activeRole == 'buyer';
    final isSeller = auth.activeRole == 'seller';
    final fmt = NumberFormat('#,###');
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_deal == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Deal not found')));
    }

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusBillboard(theme, isBuyer, isSeller).animate().fadeIn().slideY(begin: 0.05),
        const SizedBox(height: 32),
        
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ORDER STATUS',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: theme.colorScheme.primary, letterSpacing: 2),
              ),
              const SizedBox(height: 32),
              StepWizard(status: _deal!.status),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 32),
        
        if (!isDesktop) ...[
          _buildInfoCard(fmt, theme),
          const SizedBox(height: 32),
          _buildActivitySection(theme),
          const SizedBox(height: 32),
        ] else
          _buildItemDescription(theme),
        
        // Inline Cancel Button
        if ((isSeller || isBuyer) && (_deal!.status == 'pending_payment' || _deal!.status == 'held'))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: TextButton.icon(
                onPressed: _actionLoading ? null : _cancelDeal,
                style: TextButton.styleFrom(foregroundColor: Colors.red.shade300),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: Text('CANCEL THIS DEAL', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),

        const SizedBox(height: 32),
        const EscrowBadge(),
        const SizedBox(height: 120),
      ],
    );

    final sidebar = Column(
      children: [
        _buildInfoCard(fmt, theme),
        const SizedBox(height: 32),
        _buildActivitySection(theme),
        if (_deal!.proofs.isNotEmpty) ...[
          const SizedBox(height: 32),
          _buildEvidenceSection(theme),
        ],
      ],
    );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('ESCROW ID: ${_deal!.transactionId.substring(0, 12)}...', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade600)),
            centerTitle: true,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
            actions: [
              IconButton(onPressed: _fetchDeal, icon: const Icon(Icons.refresh_rounded, size: 20)),
              const SizedBox(width: 8),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: RefreshIndicator(
                onRefresh: _fetchDeal,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 48 : 20,
                    vertical: 24,
                  ),
                  child: isDesktop 
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: mainContent),
                          const SizedBox(width: 40),
                          Expanded(flex: 2, child: sidebar),
                        ],
                      )
                    : mainContent,
                ),
              ),
            ),
          ),
          bottomNavigationBar: _buildStickyFooter(theme, isBuyer, isSeller, fmt, auth),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBillboard(ThemeData theme, bool isBuyer, bool isSeller) {
    String title = '', sub = '';
    Color color = Colors.grey;
    IconData icon = Icons.info_outline;

    switch (_deal!.status) {
      case 'pending_payment':
        title = isBuyer ? 'Action Required: Secure Funds' : 'Awaiting Buyer Payment';
        sub = isBuyer
            ? 'Deposit the deal amount to lock it in escrow and protect your purchase.'
            : 'The buyer needs to send payment before you ship the items.';
        color = Colors.orange;
        icon = Icons.hourglass_top_rounded;
      case 'held':
        title = isSeller ? '✓ Verified Safe to Ship' : 'Funds Safely Escrowed';
        sub = isSeller
            ? 'The buyer has paid. Your funds are secured by PesaCrow. Ship the items now.'
            : 'Your money is locked in escrow. The seller has been notified to ship.';
        color = const Color(0xFF2E9D5B);
        icon = Icons.verified_user_rounded;
      case 'delivered':
        title = isBuyer ? 'Shipment Received?' : 'Delivery Notified';
        sub = isBuyer
            ? 'The seller has marked this as delivered. Please verify and approve to release funds.'
            : 'Waiting for the buyer to confirm receipt and approve your payout.';
        color = const Color(0xFF3182CE);
        icon = Icons.local_shipping_rounded;
      case 'released':
      case 'approved':
        title = 'Transaction Completed';
        sub = 'Payment has been disbursed successfully. Both parties are now protected.';
        color = const Color(0xFF2E9D5B);
        icon = Icons.check_circle_rounded;
      case 'disputed':
        title = 'Transaction in Dispute';
        sub = 'Our legal team is reviewing the active evidence. You will be notified of the outcome.';
        color = Colors.red;
        icon = Icons.gavel_rounded;
      case 'failed':
        title = 'Transaction Failed';
        sub = _deal!.disbursementStatus == 'failed' ? 'M-Pesa rejected the payout. Please retry with a standard account.' : 'An error occurred during processing.';
        color = Colors.red;
        icon = Icons.error_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 40, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 48),
        ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(title, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(sub, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 14, height: 1.6, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildItemDescription(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ITEM DETAILS',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: theme.colorScheme.primary, letterSpacing: 2),
          ),
          const SizedBox(height: 32),
          Text(_deal!.description, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text('Quantity: 1 Unit', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(NumberFormat fmt, ThemeData theme) {
    final isBuyer = context.read<AuthProvider>().activeRole == 'buyer';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FINANCIAL RECORD',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 2),
              ),
              GestureDetector(
                onTap: _copyTxId,
                child: Icon(Icons.copy_rounded, size: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Total Large
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deal Value', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('KSh ${fmt.format(_deal!.amount)}', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
            ],
          ),

          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(color: Colors.white10)),

          // Breakdown
          if (_fetchingFees)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_feeBreakdown != null)
            _buildDetailedBreakdown(fmt, isBuyer, _feeBreakdown!)
          else if (_deal!.feeBreakdownData != null)
            _buildDetailedBreakdown(fmt, isBuyer, FeeBreakdown.fromJson(_deal!.feeBreakdownData!)),

          const SizedBox(height: 12),
          _infoRow(Icons.person_pin_rounded, 'Seller', PhoneFormatter.formatForDisplay(_deal!.sellerPhone)),
          const SizedBox(height: 12),
          _infoRow(Icons.person_rounded, 'Buyer', _deal!.buyerPhone != null ? PhoneFormatter.formatForDisplay(_deal!.buyerPhone) : 'Awaiting...'),
        ],
      ),
    );
  }

  Widget _buildActivitySection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVITY HISTORY',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 2),
          ),
          const SizedBox(height: 32),
          TimelineWidget(
            events: TimelineWidget.fromDeal(
              status: _deal!.status,
              createdAt: _deal!.createdAt,
              paymentConfirmedAt: _deal!.paymentConfirmedAt,
              deliveredAt: _deal!.deliveredAt,
              approvedAt: _deal!.approvedAt,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SHIPMENT EVIDENCE',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 2),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _deal!.proofs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _proofThumb(_deal!.proofs[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedBreakdown(NumberFormat fmt, bool isBuyer, FeeBreakdown fb) {
    return Column(
      children: [
        if (isBuyer) ...[
          if ((fb.bouquetCharge ?? 0) > 0) ...[
            _infoRow(Icons.business_center_rounded, 'Bouquet Charge', '+ KSh ${fmt.format(fb.bouquetCharge)}'),
            const SizedBox(height: 12),
          ],
          _infoRow(Icons.security_rounded, 'Escrow Service', '+ KSh ${fmt.format(fb.transactionFee)}'),
          const SizedBox(height: 12),
          _infoRow(Icons.account_balance_wallet_rounded, 'Locked Total', 'KSh ${fmt.format(fb.totalBuyerPays)}', isBold: true),
        ] else ...[
          _infoRow(Icons.transit_enterexit_rounded, 'Transfer Cost', '- KSh ${fmt.format(fb.releaseFee)}'),
          const SizedBox(height: 12),
          _infoRow(Icons.savings_rounded, 'Net Payout', 'KSh ${fmt.format(fb.netToSeller)}', isBold: true),
        ],
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isBold = false}) {
    final theme = Theme.of(context);
    return Row(children: [
      Icon(icon, size: 16, color: Colors.grey.shade600),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500))),
      Text(value, style: GoogleFonts.inter(fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, fontSize: 14, color: isBold ? theme.colorScheme.onSurface : Colors.grey.shade400)),
    ]);
  }

  Widget _proofThumb(String path) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.image_rounded, color: Colors.grey.shade600, size: 24),
        const SizedBox(height: 8),
        Text('Media Proof', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget? _buildStickyFooter(ThemeData theme, bool isBuyer, bool isSeller, NumberFormat fmt, AuthProvider auth) {
    Widget? primary;
    Widget? secondary;

    if (_deal!.status == 'pending_payment' && isBuyer) {
      primary = ElevatedButton.icon(
        onPressed: _actionLoading ? null : () async {
          final res = await Navigator.push(context, MaterialPageRoute(
            builder: (_) => PaymentScreen(transactionId: _deal!.transactionId, amount: _deal!.amount),
          ));
          if (res == true) _fetchDeal();
        },
        icon: const Icon(Icons.flash_on_rounded, size: 20),
        label: const Text('SECURE WITH M-PESA'),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.2));
    }

    if (_deal!.status == 'held' && isSeller) {
      primary = ElevatedButton.icon(
        onPressed: _actionLoading ? null : () async {
          final res = await Navigator.push(context, MaterialPageRoute(
            builder: (_) => ProofUploadScreen(transactionId: _deal!.transactionId),
          ));
          if (res == true) _fetchDeal();
        },
        icon: const Icon(Icons.local_shipping_rounded, size: 20),
        label: const Text('MARK AS DELIVERED'),
      );
    }

    if (_deal!.status == 'delivered' && isBuyer) {
      primary = ElevatedButton.icon(
        onPressed: _actionLoading ? null : () async {
          final confirmed = await showHakikishaModal(
            context,
            title: 'Approve & Release Funds',
            confirmLabel: 'YES – RELEASE FUNDS',
            confirmColor: const Color(0xFF2E9D5B),
            icon: Icons.check_circle_rounded,
            escrowNote: 'This will release KSh ${fmt.format(_deal!.amount)} to the seller. Only approve once you have the items.',
            rows: [
              HakikishaRow('Amount', 'KSh ${fmt.format(_deal!.amount)}'),
              HakikishaRow('Seller', PhoneFormatter.formatForDisplay(_deal!.sellerPhone)),
            ],
          );
          if (confirmed) _doAction(() => ApiService.approveDeal(_deal!.transactionId), 'Payout approved!');
        },
        icon: const Icon(Icons.check_circle_rounded, size: 20),
        label: const Text('APPROVE & RELEASE'),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E9D5B)),
      );
      secondary = OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 64)),
        onPressed: () async {
          final res = await Navigator.push(context, MaterialPageRoute(
            builder: (_) => DisputeScreen(transactionId: _deal!.transactionId),
          ));
          if (res == true) _fetchDeal();
        },
        child: const Text('RAISE DISPUTE'),
      );
    }

    if (_deal!.status == 'delivered' && isSeller) {
      primary = ElevatedButton.icon(
        onPressed: _nudgeBuyer,
        icon: const Icon(Icons.notifications_active_rounded, size: 20),
        label: const Text('NUDGE BUYER'),
      );
    }

    if (_deal!.status == 'released' || _deal!.status == 'approved') {
      primary = ElevatedButton.icon(
        onPressed: () => ReceiptService.generateAndShowReceipt(_deal!, activeRole: auth.activeRole!),
        icon: const Icon(Icons.file_download_rounded, size: 20),
        label: const Text('DOWNLOAD RECEIPT'),
        style: ElevatedButton.styleFrom(backgroundColor: isBuyer ? const Color(0xFF2E9D5B) : const Color(0xFF3182CE)),
      );
    }

    if ((_deal!.status == 'failed' || _deal!.disbursementStatus == 'failed') && isSeller) {
      primary = ElevatedButton.icon(
        onPressed: _actionLoading ? null : _retryPayout,
        icon: const Icon(Icons.refresh_rounded, size: 20),
        label: const Text('RETRY M-PESA PAYOUT'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
      );
    }

    if (primary == null && secondary == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (secondary != null) ...[secondary, const SizedBox(height: 12)],
              if (primary != null) primary,
            ],
          ),
        ),
      ),
    );
  }
}
