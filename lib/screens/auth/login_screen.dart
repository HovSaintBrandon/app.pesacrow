import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/logger_service.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? transactionId;
  final String? role;

  const LoginScreen({super.key, this.transactionId, this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role ?? context.read<AuthProvider>().activeRole ?? 'buyer';
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _isBuyer => _selectedRole == 'buyer';

  Future<void> _sendOtp() async {
    final raw = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    // Accept 9 digits (7XXXXXXXX), 10 digits (07XXXXXXXX), or 12 digits (254XXXXXXXX)
    if (raw.length < 9) {
      setState(() => _error = 'Enter a valid Kenyan phone number');
      return;
    }
    setState(() { _loading = true; _error = null; });
    LoggerService.logEvent('LOGIN_SEND_OTP', {'role': _selectedRole});
    try {
      await ApiService.sendOtp(
        transactionId: widget.transactionId ?? '',
        phone: raw,
        role: _selectedRole,
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          phone: raw,
          role: _selectedRole,
          transactionId: widget.transactionId,
        ),
      ));
    } catch (e) {
      LoggerService.logError('Send OTP failed', e);
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = _isBuyer ? const Color(0xFF2E9D5B) : const Color(0xFF3182CE);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset('assets/launcher_foreground.png', width: 48, height: 48, fit: BoxFit.contain),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 32),

                  // Role context banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: roleColor.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        Icon(_isBuyer ? Icons.shield_outlined : Icons.lock_outline, color: roleColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isBuyer ? 'Joining as Buyer' : 'Joining as Seller',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: roleColor),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 48),

                  Text(
                    'Verify your number',
                    style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, letterSpacing: -1),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 12),

                  Text(
                    'We\'ll send a 6-digit code via SMS. Standard rates apply.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 48),

                  // Phone field with +254 prefix
                  AnimatedBuilder(
                    animation: _phoneCtrl,
                    builder: (_, __) => TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 12,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 1.5),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '712 345 678',
                        counterText: '',
                        prefixIcon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Text('+254', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: roleColor)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: roleColor, width: 2),
                        ),
                      ),
                      onSubmitted: (_) => _sendOtp(),
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.12)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  ElevatedButton(
                    onPressed: _loading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: roleColor,
                      minimumSize: const Size(double.infinity, 70),
                    ),
                    child: _loading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                        : const Text('SEND VERIFICATION CODE'),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 40),

                  // Role toggle
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _selectedRole = _isBuyer ? 'seller' : 'buyer'),
                      child: Text(
                        _isBuyer ? 'Switch to Seller Account' : 'Switch to Buyer Account',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
