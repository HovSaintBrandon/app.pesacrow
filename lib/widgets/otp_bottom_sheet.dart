import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class OtpBottomSheet extends StatefulWidget {
  final String transactionId;
  final String defaultRole;
  final VoidCallback? onSuccess;

  const OtpBottomSheet({
    super.key,
    required this.transactionId,
    this.defaultRole = 'buyer',
    this.onSuccess,
  });

  static Future<void> show(BuildContext context, {
    required String transactionId,
    String defaultRole = 'buyer',
    VoidCallback? onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => OtpBottomSheet(
        transactionId: transactionId,
        defaultRole: defaultRole,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<OtpBottomSheet> {
  bool _isOtpStep = false;
  bool _loading = false;
  String _phone = '';
  String _otp = '';
  late String _role;
  String? _error;

  @override
  void initState() {
    super.initState();
    _role = widget.defaultRole;
  }

  Future<void> _sendOtp() async {
    if (_phone.length < 10) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.sendOtp(
        transactionId: widget.transactionId,
        phone: _phone,
        role: _role,
      );
      setState(() { _isOtpStep = true; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length < 6) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.verifyOtp(
        transactionId: widget.transactionId,
        phone: _phone,
        otp: _otp,
        role: _role,
      );
      if (!mounted) return;
      await context.read<AuthProvider>().login(res['token'], _phone, _role);
      Navigator.of(context).pop();
      widget.onSuccess?.call();
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Icon(Icons.phone_android, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              _isOtpStep ? 'Enter OTP' : 'Verify Your Identity',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            _isOtpStep
                ? 'A 6-digit code was sent to your phone via SMS.'
                : 'Enter your phone number and select your role.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 20),

          if (!_isOtpStep) ...[
            TextField(
              keyboardType: TextInputType.phone,
              maxLength: 12,
              decoration: const InputDecoration(
                hintText: '254712345678',
                counterText: '',
              ),
              onChanged: (v) => _phone = v.replaceAll(RegExp(r'\D'), ''),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _RoleButton(
                  label: 'Buyer',
                  selected: _role == 'buyer',
                  onTap: () => setState(() => _role = 'buyer'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RoleButton(
                  label: 'Seller',
                  selected: _role == 'seller',
                  onTap: () => setState(() => _role = 'seller'),
                ),
              ),
            ]),
          ] else ...[
            PinCodeTextField(
              appContext: context,
              length: 6,
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(10),
                fieldHeight: 50,
                fieldWidth: 44,
                activeFillColor: Colors.white,
                inactiveFillColor: Colors.grey.shade50,
                selectedFillColor: Colors.white,
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Colors.grey.shade300,
                selectedColor: Theme.of(context).colorScheme.primary,
              ),
              enableActiveFill: true,
              onChanged: (v) => _otp = v,
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _loading ? null : (_isOtpStep ? _verifyOtp : _sendOtp),
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_isOtpStep ? 'Verify & Continue' : 'Send OTP'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
