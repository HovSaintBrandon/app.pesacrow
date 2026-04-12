import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionHub extends StatelessWidget {
  final String totalLocked;
  final String availableBalance;
  final Color accentColor;
  final VoidCallback? onToggleBalance;
  final bool isBalanceHidden;
  final double progress;

  const TransactionHub({
    super.key,
    required this.totalLocked,
    required this.availableBalance,
    required this.accentColor,
    this.onToggleBalance,
    this.isBalanceHidden = false,
    this.progress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          // Central Vault / Progress Ring
          Stack(
            alignment: Alignment.center,
            children: [
              // Pulse Background
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(isDark ? 0.08 : 0.05),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.04, 1.04), duration: 3.seconds, curve: Curves.easeInOut),

              // Inner Ring
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor.withOpacity(0.15), width: 2),
                ),
              ),

              // The Secure Hub Icon
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(isDark ? 0.2 : 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Icon(Icons.security_rounded, size: 64, color: accentColor)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 4.seconds, color: Colors.white24),
              ),

              // Animated "Locked" Ring Segment
              SizedBox(
                width: 215,
                height: 215,
                child: CircularProgressIndicator(
                  value: progress, 
                  strokeWidth: 5,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor.withOpacity(0.4)),
                  strokeCap: StrokeCap.round,
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Balance Display
          GestureDetector(
            onTap: onToggleBalance,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ACTIVE IN ESCROW',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade500,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(isBalanceHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 14, color: Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isBalanceHidden ? '••••••••' : totalLocked,
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -1.5,
                  ),
                ).animate(key: ValueKey(isBalanceHidden)).fadeIn(duration: 300.ms).scale(begin: const Offset(0.97, 0.97)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
