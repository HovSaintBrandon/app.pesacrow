import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../models/deal.dart';
import '../utils/phone_utils.dart';
import '../services/logger_service.dart';
import '../core/notifications.dart';
import '../services/fee_service.dart';
import '../models/fee_breakdown.dart';
import 'deal_dashboard_screen.dart';
import '../utils/phone_formatter.dart';


class JoinDealScreen extends StatefulWidget {
  final bool isInScaffold;
  const JoinDealScreen({super.key, this.isInScaffold = false});

  @override
  State<JoinDealScreen> createState() => _JoinDealScreenState();
}

class _JoinDealScreenState extends State<JoinDealScreen> {
  final _idCtrl = TextEditingController();
  bool _loading = false;
  Deal? _previewDeal;
  FeeBreakdown? _feeBreakdown;
  bool _fetchingFees = false;
  static const _green = Color(0xFF2E9D5B);

  Future<void> _preview() async {
    final id = _idCtrl.text.trim();
    if (id.isEmpty) return;
    LoggerService.logEvent('JOIN_PREVIEW_ATTEMPT', {'transactionId': id});
    setState(() { _loading = true; _previewDeal = null; });
    try {
      final deal = await ApiService.getDealDetails(id);
      LoggerService.logEvent('JOIN_PREVIEW_SUCCESS', {'transactionId': id});
      if (mounted) {
        setState(() {
          _previewDeal = deal;
          _fetchingFees = true;
        });
        _loadFees(deal.amount.toDouble());
      }
    } catch (e) {
      LoggerService.logError('Preview deal failed', e);
      AppNotifications.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
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
      LoggerService.logError('Load fees failed', e);
    }
  }



  Future<void> _scanQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _QRScannerPage()),
    );
    if (result != null) {
      _idCtrl.text = result;
      _preview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,###');
    final accent = const Color(0xFF2E9D5B);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo / Branding
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _green.withOpacity(0.08), shape: BoxShape.circle),
            child: Image.asset('assets/launcher_foreground.png', width: 48, height: 48, fit: BoxFit.contain),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
        
        const SizedBox(height: 32),
        Text('Secure Entrance', style: GoogleFonts.inter(fontSize: isDesktop ? 34 : 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
        const SizedBox(height: 12),
        Text(
          'Protect your purchase with PesaCrow escrow.\nEnter a Transaction ID to verify and secure your funds.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.6),
        ),
        
        const SizedBox(height: 48),

        // High-Impact Input Area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _idCtrl,
                  autofocus: true,
                  style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 1, color: theme.colorScheme.onSurface),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'ESC-KE-XXXX',
                    hintStyle: GoogleFonts.jetBrainsMono(color: Colors.grey.shade700, fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    if (val.length >= 10) _preview();
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _scanQR,
                tooltip: 'Scan QR Code',
                padding: const EdgeInsets.all(12),
                style: IconButton.styleFrom(backgroundColor: accent.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                icon: Icon(Icons.camera_alt_rounded, color: accent, size: 22),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

        const SizedBox(height: 32),
        
        if (_loading)
          const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E9D5B))).animate().fadeIn(),

        if (_previewDeal != null)
          _buildPreviewCard(_previewDeal!, fmt, theme).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
      ],
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Join Secure Deal', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(Deal deal, NumberFormat fmt, ThemeData theme) {
    final accent = const Color(0xFF2E9D5B);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: accent.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: accent.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.verified_user_rounded, color: accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verified Protected Deal', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, letterSpacing: -0.5)),
                    Text('Secure Link Active', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          _previewRow('MARKET ITEM', deal.description, isHeader: true),
          _previewRow('VERIFIED SELLER', PhoneFormatter.formatForDisplay(deal.sellerPhone)),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white10),
          ),

          _previewRow('ITEM AMOUNT', 'KSh ${fmt.format(deal.amount)}'),
          if ((_feeBreakdown?.bouquetCharge ?? 0) > 0)
            _previewRow('BOUQUET SERVICE', 'KSh ${fmt.format(_feeBreakdown!.bouquetCharge!)}', valueColor: Colors.grey.shade600),
          _previewRow('ESCROW SECURITY', 'KSh ${fmt.format(_feeBreakdown?.transactionFee ?? 0)}', valueColor: Colors.grey.shade600),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: accent.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: accent.withOpacity(0.1))),
            child: _fetchingFees
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E9D5B))))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL COMMITMENT', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, color: theme.colorScheme.onSurface, letterSpacing: 1)),
                      Text('KSh ${fmt.format(_feeBreakdown?.totalBuyerPays ?? deal.amount)}', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 20, color: accent)),
                    ],
                  ),
          ),

          if (_feeBreakdown?.warning != null) ...[
            const SizedBox(height: 12),
            Text(_feeBreakdown!.warning!, style: TextStyle(color: Colors.orange.shade400, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],

          const SizedBox(height: 48),

          ElevatedButton(
            onPressed: () {
              LoggerService.logEvent('JOIN_CONFIRMED', {'transactionId': deal.transactionId});
              Navigator.pushNamed(context, '/deal/${deal.transactionId}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              minimumSize: const Size(double.infinity, 70),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 12,
              shadowColor: accent.withOpacity(0.4),
            ),
            child: Text('JOIN & SECURE MY MONEY', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
          ).animate().shimmer(duration: 2.seconds, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value, {Color? valueColor, bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
          Flexible(child: Text(value, style: GoogleFonts.inter(fontWeight: isHeader ? FontWeight.w900 : FontWeight.w700, fontSize: isHeader ? 15 : 13, color: valueColor ?? Theme.of(context).colorScheme.onSurface), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _QRScannerPage extends StatelessWidget {
  const _QRScannerPage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Scan Secure QR'), backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFF2E9D5B), width: 2), borderRadius: BorderRadius.circular(32)),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(height: 2, color: const Color(0xFF2E9D5B)).animate(onPlay: (c) => c.repeat()).moveY(begin: 0, end: 250, duration: 2.seconds, curve: Curves.easeInOut),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
