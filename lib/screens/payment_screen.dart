import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/logger_service.dart';
import '../services/sse_service.dart';
import '../core/notifications.dart';
import '../providers/auth_provider.dart';
import '../utils/phone_utils.dart';
import '../widgets/hakikisha_modal.dart';
import '../widgets/escrow_badge.dart';
import '../services/fee_service.dart';
import '../models/fee_breakdown.dart';

class PaymentScreen extends StatefulWidget {
  final String transactionId;
  final int amount;

  const PaymentScreen({super.key, required this.transactionId, required this.amount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _phoneCtrl = TextEditingController();
  bool _stkLoading = false;
  String? _statusMessage;
  bool _paymentInitiated = false;
  // --- SSE + polling ---------------------------------------------------------
  StreamSubscription<SseEvent>? _sseSubscription;
  Timer? _pollTimer;
  int _pollCount = 0;
  // ---------------------------------------------------------------------------
  FeeBreakdown? _feeBreakdown;
  bool _fetchingFees = true;

  static const _green = Color(0xFF2E9D5B);

  int get _fee => (widget.amount * 0.015).ceil();
  int get _total => widget.amount + _fee;

  @override
  void initState() {
    super.initState();
    // Pre-fill with the logged-in user's phone
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phone = context.read<AuthProvider>().phone;
      if (phone != null && phone.isNotEmpty) {
        _phoneCtrl.text = phone;
      }
      _loadFees();
    });
  }

  Future<void> _loadFees() async {
    try {
      final breakdown = await FeeService.calculateFees(widget.amount.toDouble());
      if (mounted) {
        setState(() {
          _feeBreakdown = breakdown;
          _fetchingFees = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _fetchingFees = false);
      LoggerService.logError('Load fees failed', e);
    }
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    _pollTimer?.cancel();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _onPayTap() async {
    final phoneRaw = _phoneCtrl.text.trim();
    final phone = PhoneUtils.normalize(phoneRaw);
    if (phone.isEmpty) { AppNotifications.showError(context, 'Enter a valid M-Pesa number'); return; }

    final fmt = NumberFormat('#,###');

    // Show Hakikisha confirmation first
    final confirmed = await showHakikishaModal(
      context,
      title: 'Confirm M-Pesa Payment',
      confirmLabel: 'CONFIRM & SEND STK PUSH',
      confirmColor: _green,
      icon: Icons.security,
      escrowNote: 'Your money goes directly to PesaCrow Escrow — NOT the seller. Funds are only released when you approve the delivery.',
      rows: [
        HakikishaRow('Item Amount', 'KSh ${fmt.format(widget.amount)}'),
        HakikishaRow('Escrow Fee', 'KSh ${fmt.format(_feeBreakdown?.transactionFee ?? 0)}'),
        const HakikishaRow.divider(),
        HakikishaRow('Total Deducted', 'KSh ${fmt.format(_feeBreakdown?.totalBuyerPays ?? widget.amount)}', isBold: true),
        if (_feeBreakdown?.warning != null) ...[
          const HakikishaRow.divider(),
          HakikishaRow('Note', _feeBreakdown!.warning!, isBold: false),
        ],
        const HakikishaRow.divider(),
        HakikishaRow('M-Pesa Number', '+$phone'),
      ],
    );

    if (!confirmed || !mounted) return;
    _initiatePayment(phone);
  }

  Future<void> _initiatePayment(String phone) async {
    LoggerService.logEvent('PAYMENT_INITIATE', {'transactionId': widget.transactionId, 'phone': phone, 'amount': widget.amount});
    setState(() { _stkLoading = true; _statusMessage = 'Requesting M-Pesa STK Push...'; _paymentInitiated = true; });

    try {
      await ApiService.initiateStk(transactionId: widget.transactionId, buyerPhone: phone);
      if (mounted) setState(() => _statusMessage = 'STK sent! Check your phone for the PIN prompt.');
      _startListening();
    } catch (e) {
      LoggerService.logError('Payment initiate failed', e);
      if (mounted) setState(() { _stkLoading = false; _statusMessage = null; _paymentInitiated = false; });
      AppNotifications.showError(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ---------------------------------------------------------------------------
  // Payment confirmation listeners
  // ---------------------------------------------------------------------------

  /// Primary listener: SSE stream — instant confirmation with no polling cost.
  /// Fallback listener: REST polling every 3 s — always runs in parallel so
  /// that a temporary SSE hiccup never blocks payment confirmation.
  void _startListening() {
    _cancelListeners();

    // --- SSE (primary) -------------------------------------------------------
    if (SseService.isConnected) {
      _sseSubscription = SseService.stream
          .where((e) =>
              e.transactionId == widget.transactionId && e.status == 'held')
          .listen((_) {
        LoggerService.logEvent('PAYMENT_CONFIRMED_VIA_SSE',
            {'transactionId': widget.transactionId});
        _onPaymentConfirmed();
      });
    }

    // --- Polling (fallback / safety net) ------------------------------------
    _pollCount = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _pollCount++;
      if (_pollCount > 40) {
        timer.cancel();
        _onPaymentTimeout();
        return;
      }
      try {
        final status =
            await ApiService.getDealStatus(widget.transactionId);
        if (status == 'held') {
          LoggerService.logEvent('PAYMENT_CONFIRMED_VIA_POLL',
              {'transactionId': widget.transactionId});
          _onPaymentConfirmed();
        }
      } catch (_) {}
    });
  }

  void _cancelListeners() {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _onPaymentConfirmed() {
    _cancelListeners();
    if (!mounted) return;
    setState(() {
      _stkLoading = false;
      _statusMessage = '🎉 Payment secured in escrow!';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context, true);
    });
  }

  void _onPaymentTimeout() {
    if (!mounted) return;
    setState(() {
      _stkLoading = false;
      _statusMessage = 'Timeout — please check M-Pesa and try again.';
    });
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,###');
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Cinematic Trust Icon / Logo
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: _green.withOpacity(0.05), shape: BoxShape.circle),
          child: Image.asset('assets/launcher_foreground.png', width: 48, height: 48, fit: BoxFit.contain),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),

        const SizedBox(height: 32),
        Text('Secure Payment', style: GoogleFonts.inter(fontSize: isDesktop ? 34 : 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
        const SizedBox(height: 12),
        Text(
          'Your funds are held in a secure escrow account and only released when you authorize delivery.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.6),
        ),

        const SizedBox(height: 48),

        // Secured Receipt
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20))],
          ),
          child: _fetchingFees
              ? const Center(child: CircularProgressIndicator(color: _green))
              : Column(
                  children: [
                    _summaryRow('MARKET ITEM VALUE', 'KSh ${fmt.format(widget.amount)}', isHeader: true),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white10)),
                    
                    if ((_feeBreakdown?.bouquetCharge ?? 0) > 0)
                      _summaryRow('BOUQUET SERVICE', 'KSh ${fmt.format(_feeBreakdown!.bouquetCharge!)}', sub: true),
                    _summaryRow('ESCROW PROTECTION', 'KSh ${fmt.format(_feeBreakdown?.transactionFee ?? 0)}', sub: true),
                    
                    const SizedBox(height: 32),
                    
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: _green.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: _green.withOpacity(0.1))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL DUE', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, color: theme.colorScheme.onSurface, letterSpacing: 1)),
                          Text('KSh ${fmt.format(_feeBreakdown?.totalBuyerPays ?? widget.amount)}', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 24, color: _green)),
                        ],
                      ),
                    ),
                    
                    if (_feeBreakdown?.warning != null) ...[
                      const SizedBox(height: 16),
                      Text(_feeBreakdown!.warning!, style: TextStyle(color: Colors.orange.shade400, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                    ],
                  ],
                ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

        const SizedBox(height: 48),

        // Cyber-Input for M-Pesa
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            enabled: !_paymentInitiated,
            style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w800, fontSize: 18, color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'M-PESA WALLET NUMBER',
              labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              hintText: '07XX...',
              hintStyle: TextStyle(color: Colors.grey.shade800),
              prefixIcon: Container(
                padding: const EdgeInsets.only(right: 12, top: 18),
                child: Text('254', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w900, color: _green, fontSize: 16)),
              ),
              border: InputBorder.none,
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          ),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 48),

        // High-Impact Pay Button
        if (!_paymentInitiated)
          ElevatedButton(
            onPressed: _onPayTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              minimumSize: const Size(double.infinity, 70),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 12,
              shadowColor: _green.withOpacity(0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 12),
                Text('SECURE PAYMENT WITH M-PESA', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
              ],
            ),
          ).animate().shimmer(duration: 2.seconds, color: Colors.white24).fadeIn(delay: 400.ms),

        const SizedBox(height: 48),
        const EscrowBadge(),
      ],
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Payment Terminal', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _paymentInitiated ? const SizedBox.shrink() : null,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: content,
                ),
              ),
            ),
          ),
          
          if (_paymentInitiated)
            _buildCinematicOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildCinematicOverlay(ThemeData theme) {
    return Container(
      color: theme.scaffoldBackgroundColor.withOpacity(0.95),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(color: _green.withOpacity(0.1), shape: BoxShape.circle),
                child: Center(
                  child: Icon(Icons.phonelink_ring_rounded, color: _green, size: 48).animate(onPlay: (c) => c.repeat()).scale(duration: 1.seconds, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), curve: Curves.easeInOut).fadeIn(),
                ),
              ),
              const SizedBox(height: 48),
              Text(_statusMessage ?? 'Requesting STK...', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 16),
              Text('Please enter your M-Pesa PIN on the prompt sent to your phone. We are listening for the secure signal.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.6)),
              const SizedBox(height: 48),
              if (_stkLoading)
                const CircularProgressIndicator(strokeWidth: 2, color: _green),
              const SizedBox(height: 60),
              OutlinedButton(
                onPressed: () {
                  _cancelListeners();
                  setState(() {
                    _stkLoading = false;
                    _paymentInitiated = false;
                    _statusMessage = null;
                  });
                },
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), side: BorderSide(color: Colors.white10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text('Cancel Request', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _summaryRow(String label, String value, {bool isHeader = false, bool sub = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: sub ? Colors.grey.shade600 : Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
          Text(value, style: GoogleFonts.inter(fontWeight: isHeader ? FontWeight.w900 : FontWeight.w700, fontSize: isHeader ? 16 : 14, color: isHeader ? null : (sub ? Colors.grey.shade600 : null))),
        ],
      ),
    );
  }
}
