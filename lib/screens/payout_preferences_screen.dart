import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/notifications.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';
class PayoutPreferencesScreen extends StatefulWidget {
  final bool isInScaffold;
  const PayoutPreferencesScreen({super.key, this.isInScaffold = false});

  @override
  State<PayoutPreferencesScreen> createState() => _PayoutPreferencesScreenState();
}

class _PayoutPreferencesScreenState extends State<PayoutPreferencesScreen> {
  final _phoneCtrl = TextEditingController();
  final _shortcodeCtrl = TextEditingController();
  final _accountRefCtrl = TextEditingController();
  final _tillCtrl = TextEditingController();
  
  String _payoutType = 'normal'; // 'normal', 'paybill', 'buy_goods', 'pochi'
  String _signupPhone = '';
  bool _loading = false;
  bool _fetching = true;


  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final phone = context.read<AuthProvider>().phone ?? '';
      _signupPhone = phone;
      final pref = await ApiService.getPayoutPreference();

      
      if (mounted) {
        setState(() {
          _payoutType = pref['preferredChannel'] ?? 'normal';
          _phoneCtrl.text = pref['payoutPhone'] ?? pref['phone'] ?? _signupPhone;
          _shortcodeCtrl.text = pref['paybillShortcode'] ?? '';

          _accountRefCtrl.text = pref['paybillAccountReference'] ?? '';
          _tillCtrl.text = pref['buyGoodsTill'] ?? '';
          _fetching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _payoutType = 'normal';
          _phoneCtrl.text = context.read<AuthProvider>().phone ?? '';
          _fetching = false;
        });
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _loading = true);
    
    try {
      final data = <String, dynamic>{
        'preferredChannel': _payoutType,
      };
      
      if (_payoutType == 'paybill') {
        data['paybillShortcode'] = _shortcodeCtrl.text.trim();
        data['paybillAccountReference'] = _accountRefCtrl.text.trim();
      } else if (_payoutType == 'buy_goods') {
        data['buyGoodsTill'] = _tillCtrl.text.trim();
      } else {
        data['payoutPhone'] = _phoneCtrl.text.trim();
      }


      
      LoggerService.logEvent('PAYOUT_PREFERENCE_SAVE_ATTEMPT', data);
      await ApiService.setPayoutPreference(data);
      LoggerService.logEvent('PAYOUT_PREFERENCE_SAVE_SUCCESS', data);
      
      if (mounted) {
        AppNotifications.showSuccess(context, 'Payout preferences saved!');
        if (!widget.isInScaffold) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        LoggerService.logError('Payout preferences save failed', e);
        AppNotifications.showError(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fetching) {
      return widget.isInScaffold 
        ? const Center(child: CircularProgressIndicator()) 
        : Scaffold(body: const Center(child: CircularProgressIndicator()));
    }
    
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 850;

    final body = SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 48 : 24,
              vertical: 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payout Settings',
                  style: GoogleFonts.inter(
                    fontSize: 32, 
                    fontWeight: FontWeight.w900, 
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose where you want your funds disbursed. Changes apply instantly to all new deals.',
                  style: TextStyle(
                    color: Colors.grey.shade500, 
                    fontSize: 15, 
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 54),
                
                Text(
                  'RECEIVING METHOD',
                  style: GoogleFonts.inter(
                    fontSize: 12, 
                    fontWeight: FontWeight.w800, 
                    color: theme.colorScheme.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),

                if (isDesktop)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: [
                      _buildPayoutCard('Standard M-Pesa', 'normal', Icons.phone_iphone_rounded, 'Direct to your phone number'),
                      _buildPayoutCard('M-Pesa Paybill', 'paybill', Icons.account_balance_wallet_rounded, 'Business shortcodes'),
                      _buildPayoutCard('M-Pesa Buy Goods', 'buy_goods', Icons.shopping_cart_rounded, 'Till numbers (Lipa na M-Pesa)'),
                      _buildPayoutCard('Pochi la Biashara', 'pochi', Icons.storefront_rounded, 'Personal merchant wallets'),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildPayoutCard('Standard M-Pesa', 'normal', Icons.phone_iphone_rounded, 'Direct to your mobile number'),
                      const SizedBox(height: 12),
                      _buildPayoutCard('M-Pesa Paybill', 'paybill', Icons.account_balance_wallet_rounded, 'Business shortcodes'),
                      const SizedBox(height: 12),
                      _buildPayoutCard('M-Pesa Buy Goods', 'buy_goods', Icons.shopping_cart_rounded, 'Till numbers'),
                      const SizedBox(height: 12),
                      _buildPayoutCard('Pochi la Biashara', 'pochi', Icons.storefront_rounded, 'Personal wallets'),
                    ],
                  ),
                
                const SizedBox(height: 64),

                Text(
                  'METHOD DETAILS',
                  style: GoogleFonts.inter(
                    fontSize: 12, 
                    fontWeight: FontWeight.w800, 
                    color: theme.colorScheme.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Form Fields
                AnimatedSwitcher(
                  duration: 400.ms,
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation), child: child)),
                  child: _buildFormFields(theme),
                ),

                const SizedBox(height: 64),
                
                ElevatedButton(
                  onPressed: _loading ? null : _savePreferences,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 70),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                      : const Text('SAVE SETTINGS'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.isInScaffold) return Scaffold(backgroundColor: Colors.transparent, body: body);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Payout Preferences', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: body,
    );
  }

  Widget _buildFormFields(ThemeData theme) {
    if (_payoutType == 'paybill') {
      return Column(
        key: const ValueKey('paybill-fields'),
        children: [
          _buildTextField(
            controller: _shortcodeCtrl,
            label: 'Paybill Shortcode',
            hint: 'e.g. 123456',
            icon: Icons.numbers_rounded,
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _accountRefCtrl,
            label: 'Account Reference',
            hint: 'e.g. Your Name or Account #',
            icon: Icons.account_circle_rounded,
          ),
        ],
      );
    } else if (_payoutType == 'buy_goods') {
      return _buildTextField(
        key: const ValueKey('buygoods-fields'),
        controller: _tillCtrl,
        label: 'Buy Goods Till Number',
        hint: 'e.g. 192837',
        icon: Icons.store_rounded,
      );
    } else {
      return Column(
        key: const ValueKey('phone-fields'),
        children: [
          _buildTextField(
            controller: _phoneCtrl,
            label: (_payoutType == 'pochi') ? 'Pochi la Biashara Number' : 'M-Pesa Number',
            hint: '254712345678',
            icon: Icons.phone_iphone_rounded,
            onChanged: (v) => setState(() {}),
          ),
          if (_phoneCtrl.text.isNotEmpty && _signupPhone.isNotEmpty && _phoneCtrl.text.trim() != _signupPhone.trim()) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Attention: This number is different from your signup phone (${_signupPhone}). All payouts for your deals will be sent to the new number.',
                      style: TextStyle(color: Colors.amber.shade200, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }
  }

  Widget _buildTextField({
    Key? key,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Function(String)? onChanged,
  }) {
    final theme = Theme.of(context);
    return TextField(
      key: key,
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 22),
        contentPadding: const EdgeInsets.all(24),
        filled: true,
        fillColor: theme.cardColor,
      ),
    );
  }

  Widget _buildPayoutCard(String label, String type, IconData icon, String subtitle) {
    final selected = _payoutType == type;
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _payoutType = type),
        child: AnimatedContainer(
          duration: 300.ms,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : Colors.white.withOpacity(0.05),
              width: 2,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: selected ? theme.colorScheme.primary : Colors.grey, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 16,
                        color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
