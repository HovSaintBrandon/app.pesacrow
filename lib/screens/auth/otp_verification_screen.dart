import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/logger_service.dart';
import '../../core/notifications.dart';
import '../../utils/phone_formatter.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  final String role;
  final String? transactionId;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    required this.role,
    this.transactionId,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  int _timerCount = 60;
  Timer? _timer;
  bool _autoVerifying = false;

  bool get _isBuyer => widget.role == 'buyer';
  Color get _roleColor => _isBuyer ? const Color(0xFF2E9D5B) : const Color(0xFF3182CE);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timerCount = 60;
    setState(() {});
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_timerCount == 0) {
        timer.cancel();
        setState(() {});
      } else {
        setState(() => _timerCount--);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_timerCount > 0 || _loading) return;
    LoggerService.logEvent('OTP_RESEND', {'phone': widget.phone});
    setState(() => _loading = true);
    try {
      await ApiService.sendOtp(
        transactionId: widget.transactionId ?? '',
        phone: widget.phone,
        role: widget.role,
      );
      _startTimer();
      if (mounted) {
        AppNotifications.showSuccess(context, 'Verification code resent');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp(String otp) async {
    if (otp.length < 6 || _loading || _autoVerifying) return;
    
    // Drop focus to prevent HighlightModeManager exceptions on unmount
    FocusScope.of(context).unfocus();
    
    LoggerService.logEvent('OTP_VERIFY_ATTEMPT', {'phone': widget.phone});
    setState(() { _loading = true; _error = null; _autoVerifying = true; });

    try {
      final res = await ApiService.verifyOtp(
        transactionId: widget.transactionId ?? '',
        phone: widget.phone,
        otp: otp,
        role: widget.role,
      );
      if (!mounted) return;
      LoggerService.logEvent('OTP_VERIFY_SUCCESS', {'phone': widget.phone});

      final auth = context.read<AuthProvider>();
      final token = (res['data']?['token'] ?? res['token']) as String;
      await auth.login(token, widget.phone, widget.role);
      await auth.setActiveRole(widget.role);

      if (!mounted) return; // Add check after awaits

      if (widget.transactionId != null && widget.transactionId!.isNotEmpty) {
        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.pushReplacementNamed(context, '/deal/${widget.transactionId}');
      } else {
        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.pushReplacementNamed(context, '/my-deals');
      }
    } catch (e) {
      LoggerService.logError('OTP verify failed', e);
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _autoVerifying = false; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  // Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _roleColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.sms_rounded, color: _roleColor, size: 48),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 32),

                  Text(
                    'Enter Code',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, letterSpacing: -1),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 12),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'Verification code sent to ',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500),
                      children: [
                        TextSpan(
                          text: PhoneFormatter.formatForDisplay(widget.phone),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface, fontSize: 15),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 54),

                  // PIN fields
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.scale,
                    autoFocus: true,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(16),
                      fieldHeight: 64,
                      fieldWidth: 52,
                      activeFillColor: theme.cardColor,
                      inactiveFillColor: theme.cardColor,
                      selectedFillColor: theme.cardColor,
                      activeColor: _roleColor,
                      inactiveColor: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
                      selectedColor: _roleColor,
                      borderWidth: 2,
                    ),
                    textStyle: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
                    cursorColor: _roleColor,
                    backgroundColor: Colors.transparent,
                    enableActiveFill: true,
                    onChanged: (val) => setState(() => _error = null),
                    onCompleted: _verifyOtp,
                  ).animate().fadeIn(delay: 300.ms),

                  // Error state
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
                    ).animate().shakeX(hz: 4, amount: 4),
                  ],

                  const SizedBox(height: 32),

                  // Countdown + resend
                  Center(
                    child: _timerCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 8),
                                Text(
                                  'Resend code in ${_timerCount}s',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Text("Didn't receive the code?", style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                              TextButton(
                                onPressed: _loading ? null : _resendOtp,
                                child: Text('RESEND NOW', style: TextStyle(color: _roleColor, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 54),

                  ElevatedButton(
                    onPressed: (_loading || _otpCtrl.text.length < 6) ? null : () => _verifyOtp(_otpCtrl.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _roleColor,
                      minimumSize: const Size(double.infinity, 70),
                    ),
                    child: _loading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                        : const Text('VERIFY & CONTINUE'),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 24),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('CHANGE PHONE NUMBER', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
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
