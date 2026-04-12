import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ModeShiftOverlay {
  static void show(BuildContext context, {required bool toBuyer}) {
    final color = toBuyer ? const Color(0xFF2E9D5B) : const Color(0xFF3182CE);
    final role = toBuyer ? 'Buying' : 'Selling';
    final icon = toBuyer ? Icons.shield_outlined : Icons.lock_outline;

    HapticFeedback.vibrate(); // Heavy impact or vibration

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ModeShiftWidget(
        color: color,
        role: role,
        icon: icon,
        onComplete: () => entry.remove(),
      ),
    );

    Overlay.of(context).insert(entry);
  }
}

class _ModeShiftWidget extends StatelessWidget {
  final Color color;
  final String role;
  final IconData icon;
  final VoidCallback onComplete;

  const _ModeShiftWidget({
    required this.color,
    required this.role,
    required this.icon,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: FutureBuilder(
        future: Future.delayed(const Duration(milliseconds: 1500)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onComplete());
          }
          return Stack(
            children: [
              // 1. Frosted Glass Background
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: color.withOpacity(0.05)),
              ).animate().fadeIn(duration: 400.ms),

              // 2. Center Content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Morphing pulsing icon
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withOpacity(0.3), width: 2),
                      ),
                      child: Icon(icon, color: color, size: 64),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 600.ms, curve: Curves.easeInOut)
                     .shimmer(delay: 200.ms, duration: 1000.ms, color: Colors.white.withOpacity(0.3)),

                    const SizedBox(height: 32),

                    // Shimmering Text
                    Text(
                      'SHIFTING TO ${role.toUpperCase()} MODE',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 2,
                      ),
                    ).animate()
                     .fadeIn(delay: 300.ms)
                     .shimmer(duration: 1200.ms, color: Colors.white)
                     .moveY(begin: 10, end: 0, curve: Curves.easeOutBack),
                  ],
                ),
              ),

              // 3. Scan line animation
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        color.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.4, 0.5, 0.6],
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat())
                 .moveY(begin: -800, end: 800, duration: 1500.ms),
              ),
            ],
          );
        },
      ),
    );
  }
}
