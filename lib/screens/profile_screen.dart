import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import 'role_selection_screen.dart';
import 'payout_preferences_screen.dart';
import '../widgets/mode_shift_overlay.dart';
import 'package:flutter/services.dart';
import 'faq_screen.dart';
import 'terms_screen.dart';
import '../utils/phone_formatter.dart';
import 'package:package_info_plus/package_info_plus.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _green = Color(0xFF2E9D5B);
  static const _blue = Color(0xFF3182CE);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isBuyer = auth.activeRole == 'buyer';
    final roleColor = isBuyer ? _green : _blue;
    final phone = auth.phone ?? '—';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        // Avatar + name
        Center(
          child: Column(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: roleColor.withOpacity(0.3), width: 2),
                ),
                child: Icon(Icons.person_outline, color: roleColor, size: 40),
              ),
              const SizedBox(height: 14),
              Text(PhoneFormatter.formatForDisplay(phone), style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A1A))),

              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isBuyer ? Icons.shield_outlined : Icons.lock_outline, color: roleColor, size: 14),
                  const SizedBox(width: 6),
                  Text(isBuyer ? 'Buyer Mode' : 'Seller Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: roleColor)),
                ]),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: -0.1),

        const SizedBox(height: 36),
        Text('Account', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade400, letterSpacing: 0.5)),
        const SizedBox(height: 12),

        _card([
          _tile(Icons.phone_outlined, 'Phone Number', PhoneFormatter.formatForDisplay(phone), roleColor),

          _divider(),
          _tile(isBuyer ? Icons.shield_outlined : Icons.lock_outline, 'Account Security', 'Biometric & OTP Protected', roleColor),
        ]),

        if (!isBuyer) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Merchant Settings', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade400, letterSpacing: 0.5)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: const Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _blue)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _card([
            _actionTile(
              Icons.account_balance_wallet_outlined, 
              'Payout Preferences', 
              'Configure where to receive funds', 
              roleColor, 
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PayoutPreferencesScreen()));
              },
            ),
            _divider(),
            _actionTile(Icons.storefront_outlined, 'Business Profile', 'Manage your public seller info', roleColor, onTap: () {}),
          ]),
        ] else ...[
          const SizedBox(height: 24),
          Text('Buyer Safety', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade400, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          _card([
            _actionTile(Icons.verified_user_outlined, 'Protection Level', 'You are covered by PesaCrow Escrow', roleColor, onTap: () {}),
            _divider(),
            _actionTile(Icons.history_outlined, 'Purchase History', 'View your past escrow transactions', roleColor, onTap: () {}),
          ]),
        ],

        const SizedBox(height: 24),
        Text('Settings', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade400, letterSpacing: 0.5)),
        const SizedBox(height: 12),

        _card([
          _actionTile(
            Icons.swap_horiz_outlined,
            isBuyer ? 'Switch to Seller Mode' : 'Switch to Buyer Mode',
            isBuyer ? 'Start selling securely' : 'Back to safe buying',
            isBuyer ? _blue : _green,
            onTap: () async {
              HapticFeedback.mediumImpact();
              ModeShiftOverlay.show(context, toBuyer: !isBuyer);
              await Future.delayed(const Duration(milliseconds: 400));
              await auth.setActiveRole(isBuyer ? 'seller' : 'buyer');
            },
          ),
        ]),

        const SizedBox(height: 24),
        Text('Support', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade400, letterSpacing: 0.5)),
        const SizedBox(height: 12),

        _card([
          _actionTile(
            Icons.help_outline,
            'Help & FAQ',
            'How PesaCrow works',
            Colors.grey.shade500,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen())),
          ),
          _divider(),
          _actionTile(
            Icons.policy_outlined,
            'Terms & Privacy',
            'Read our policies',
            Colors.grey.shade500,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
          ),
        ]),

        const SizedBox(height: 24),

        // Logout
        OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Log Out', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                content: const Text('Are you sure you want to log out?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Log Out', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  (_) => false,
                );
              }
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red, width: 1),
          ),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Log Out'),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 28),

        Center(
          child: Column(children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.verified_user_outlined, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 5),
              Text('Escrow Protected by PesaCrow', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ]),
            const SizedBox(height: 4),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.hasData ? '${snapshot.data!.version}+${snapshot.data!.buildNumber}' : '...';
                return Text('v$version', style: TextStyle(fontSize: 10, color: Colors.grey.shade300));
              },
            ),
          ]),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(children: children),
    );
  }

  Widget _tile(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
        ])),
      ]),
    );
  }

  Widget _actionTile(IconData icon, String label, String sub, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
            Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ])),
          Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade300),
        ]),
      ),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 56, color: Colors.grey.withOpacity(0.08));
}
