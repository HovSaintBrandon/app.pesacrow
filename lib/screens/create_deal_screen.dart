import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/phone_utils.dart';
import '../services/logger_service.dart';
import '../core/notifications.dart';
import '../services/fee_service.dart';
import '../models/fee_breakdown.dart';
import '../utils/debounce.dart';
import 'share_deal_screen.dart';

class CreateDealScreen extends StatefulWidget {
  final bool isInScaffold;
  const CreateDealScreen({super.key, this.isInScaffold = false});

  @override
  State<CreateDealScreen> createState() => _CreateDealScreenState();
}

class _CreateDealScreenState extends State<CreateDealScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _buyerPhoneCtrl = TextEditingController();
  bool _loading = false;
  String? _amountError;
  FeeBreakdown? _feeBreakdown;
  bool _isCalculating = false;
  final _debouncer = Debouncer(milliseconds: 400);

  static const _blue = Color(0xFF3182CE);

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(() {
      setState(() {});
      if (_amountError != null && _parsedAmount >= 20 && _parsedAmount <= 250000) {
        setState(() => _amountError = null);
      } else if (_parsedAmount > 250000) {
        setState(() => _amountError = 'Max limit is KSh 250,000');
      }
      final amount = _parsedAmount.toDouble();
      if (amount > 0) {
        _debouncer.run(() => _calculateFees(amount));
      } else {
        setState(() => _feeBreakdown = null);
      }
    });
    _descCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _buyerPhoneCtrl.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _calculateFees(double amount) async {
    if (amount <= 0) return;
    if (mounted) setState(() => _isCalculating = true);

    try {
      final breakdown = await FeeService.calculateFees(amount);
      if (mounted) {
        setState(() {
          _feeBreakdown = breakdown;
          _isCalculating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculating = false;
          _feeBreakdown = null;
        });
      }
      LoggerService.logError('Fee calculation failed', e);
    }
  }

  int get _parsedAmount => int.tryParse(_amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
  int get _fee => (_parsedAmount * 0.015).ceil();
  int get _buyerPays => _parsedAmount + _fee;

  Future<void> _create() async {
    if (_parsedAmount < 20) {
      setState(() => _amountError = 'Minimum deal amount is KSh 20');
      AppNotifications.showError(context, 'Minimum deal amount is KSh 20');
      return;
    }
    if (_parsedAmount > 250000) {
      if (mounted) setState(() => _amountError = 'Maximum deal amount is KSh 250,000');
      AppNotifications.showError(context, 'Maximum deal amount is KSh 250,000');
      return;
    }
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) { AppNotifications.showError(context, 'Description is required'); return; }

    final buyerPhoneRaw = _buyerPhoneCtrl.text.trim();
    final buyerPhone = PhoneUtils.normalize(buyerPhoneRaw);
    if (buyerPhone.isEmpty && buyerPhoneRaw.isNotEmpty) { AppNotifications.showError(context, 'Invalid phone number'); return; }

    final auth = context.read<AuthProvider>();
    final sellerPhone = auth.phone ?? '';
    if (sellerPhone.isEmpty) { AppNotifications.showError(context, 'Profile phone missing. Try relogging.'); return; }

    LoggerService.logEvent('CREATE_DEAL_ATTEMPT', {'amount': _parsedAmount});
    setState(() => _loading = true);
    try {
      final dealMap = await ApiService.createDeal(
        sellerPhone: sellerPhone,
        amount: _parsedAmount,
        description: desc,
        buyerPhone: buyerPhone.isNotEmpty ? buyerPhone : null,
      );
      final returnData = dealMap['data'] ?? dealMap;
      final transactionId = returnData['transactionId'] as String;
      final feeBreakdown = returnData['feeBreakdown'] as Map<String, dynamic>?;

      LoggerService.logEvent('CREATE_DEAL_SUCCESS', {'transactionId': transactionId});
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => ShareDealScreen(
            transactionId: transactionId,
            feeBreakdown: feeBreakdown,
          ),
        ));
      }
    } catch (e) {
      LoggerService.logError('Create deal failed', e);
      AppNotifications.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }



  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final auth = context.watch<AuthProvider>();

    final body = Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: (_currentStep + 1) / 3,
          backgroundColor: _blue.withOpacity(0.1),
          valueColor: const AlwaysStoppedAnimation<Color>(_blue),
          minHeight: 3,
        ),
        
        Expanded(
          child: AnimatedSwitcher(
            duration: 300.ms,
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: _buildStepContent(context, fmt, auth),
          ),
        ),
        
        // Navigation buttons
        _buildBottomNav(),
      ],
    );

    if (widget.isInScaffold) return Scaffold(backgroundColor: Colors.transparent, body: body);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('New Sale', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
        leading: _currentStep > 0 ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _currentStep--)) : null,
      ),
      body: body,
    );
  }

  Widget _buildStepContent(BuildContext context, NumberFormat fmt, AuthProvider auth) {
    switch (_currentStep) {
      case 0:
        return _stepWhat(context);
      case 1:
        return _stepHowMuch(context, fmt);
      case 2:
        return _stepWho(context);
      default:
        return _stepWhat(context);
    }
  }

  Widget _stepWhat(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 48, color: _blue).animate().scale().fadeIn(),
          const SizedBox(height: 24),
          Text('What are you selling?', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 12),
          Text('Enter a clear description so the buyer knows exactly what they are paying for.', style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5)),
          const SizedBox(height: 32),
          TextField(
            controller: _descCtrl,
            autofocus: true,
            maxLines: 4,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'e.g., iPhone 13 Pro Max - 256GB...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.1))),
              fillColor: Theme.of(context).cardColor,
              filled: true,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _stepHowMuch(BuildContext context, NumberFormat fmt) {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.payments_outlined, size: 48, color: _blue).animate().scale().fadeIn(),
          const SizedBox(height: 24),
          Text('Set your price', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 32),
          TextField(
            controller: _amountCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1),
            decoration: InputDecoration(
              prefixIcon: Padding(padding: const EdgeInsets.only(left: 20, right: 10), child: Text('KSh', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 24, color: _blue))),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              hintText: '0',
              errorText: _amountError,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              fillColor: Theme.of(context).cardColor,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 32),
            ),
          ),
          const SizedBox(height: 24),
          
          // Progressive Disclosure of Fees
          if (_feeBreakdown != null) 
            _buildFeeSummary(fmt).animate().fadeIn().slideY(begin: 0.05)
          else if (_isCalculating)
            const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _blue)).animate().fadeIn(),
        ],
      ),
    );
  }

  Widget _stepWho(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person_add_outlined, size: 48, color: _blue).animate().scale().fadeIn(),
          const SizedBox(height: 24),
          Text('Identify your buyer', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 12),
          Text('Optional: Provide their M-Pesa phone number to notify them instantly when the deal is ready.', style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5)),
          const SizedBox(height: 32),
          TextField(
            controller: _buyerPhoneCtrl,
            autofocus: true,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18),
            decoration: InputDecoration(
              labelText: 'Buyer Phone Number',
              hintText: '07.. or 01..',
              prefixIcon: const Icon(Icons.phone_iphone_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.1))),
              fillColor: Theme.of(context).cardColor,
              filled: true,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildFeeSummary(NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('You receive (Net)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
              Text('KSh ${fmt.format(_feeBreakdown!.netToSeller)}', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 20, color: _blue)),
            ],
          ),
          const Divider(height: 32),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text('View Full Breakdown', style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
              tilePadding: EdgeInsets.zero,
              children: [
                _feeRow('Basic Item Price', 'KSh ${fmt.format(_feeBreakdown!.dealAmount)}'),
                if ((_feeBreakdown!.bouquetCharge ?? 0) > 0)
                  _feeRow('Business Bouquet Charge', '+ KSh ${fmt.format(_feeBreakdown!.bouquetCharge)}', sub: true, isPositive: true),
                _feeRow('Escrow Service Fee', '+ KSh ${fmt.format(_feeBreakdown!.transactionFee)}', sub: true, isPositive: true),
                _feeRow('M-Pesa Payout Transfer', '- KSh ${fmt.format(_feeBreakdown!.releaseFee)}', sub: true, isPositive: false),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF2E9D5B).withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, color: Color(0xFF2E9D5B), size: 14),
                      const SizedBox(width: 8),
                      Text('Funds secured in PesaCrow Vault', style: TextStyle(color: const Color(0xFF2E9D5B), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final showNext = _currentStep < 2;
    final canProceed = _currentStep == 0 ? _descCtrl.text.trim().isNotEmpty : (_currentStep == 1 ? (_parsedAmount >= 20 && _parsedAmount <= 250000) : true);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: ElevatedButton(
        onPressed: !canProceed ? null : (showNext ? () => setState(() => _currentStep++) : _create),
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _loading 
          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  showNext ? 'CONTINUE' : 'FINALIZE & SHARE',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16),
                ),
                const SizedBox(width: 12),
                Icon(showNext ? Icons.arrow_forward_rounded : Icons.check_circle_rounded),
              ],
            ),
      ),
    );
  }

  Widget _feeRow(String label, String value, {bool bold = false, bool sub = false, bool? isPositive}) {
    Color valColor = const Color(0xFF1A1A1A);
    if (isPositive == true) valColor = const Color(0xFF2E9D5B);
    if (isPositive == false) valColor = Colors.red.shade600;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: bold ? 14 : 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: sub ? Colors.grey.shade500 : Theme.of(context).colorScheme.onSurface)),
        Text(value, style: GoogleFonts.inter(fontSize: bold ? 15 : 12, fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: bold ? (isPositive == false ? valColor : _blue) : valColor)),
      ],
    );
  }
}
