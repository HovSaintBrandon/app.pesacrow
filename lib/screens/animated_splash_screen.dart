import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'role_selection_screen.dart';
import 'main_scaffold.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // The animation takes about 4.5 seconds + 1.5 seconds hold = 6.0 seconds total.
    await Future.delayed(6.seconds);
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && auth.activeRole != null) {
      Navigator.pushReplacement(context, _fade(const MainScaffold()));
    } else {
      Navigator.pushReplacement(context, _fade(const RoleSelectionScreen()));
    }
  }

  PageRoute _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 800),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37); // Gold/bronze tone
    const darkCharcoal = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7), // Minimalist off-white
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Phase 1: The Arrival of the Guardian
            // Icon scales up and slides in from the left
            Image.asset(
              'assets/launcher_foreground.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.security, size: 80, color: Color(0xFF2E9D5B)),
            )
            .animate()
            .slideX(begin: -0.5, end: 0, duration: 800.ms, curve: Curves.easeOutCubic)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 800.ms, curve: Curves.easeOutBack)
            .then(delay: 200.ms)
            // The "gentle flap/settling" motion
            .shimmer(duration: 800.ms, color: Colors.white.withOpacity(0.6))
            .shake(hz: 2, curve: Curves.easeInOut, duration: 400.ms),

            const SizedBox(height: 24),

            // Phase 2 & 3: Wordmark Reveal & Escrow Emphasis
            Stack(
              alignment: Alignment.center,
              children: [
                // The glowing 'ESCROW' underlay (Phase 3 glow pulse)
                Text(
                  ' ESCROW ',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                    color: darkCharcoal.withOpacity(0.0),
                    shadows: [
                      Shadow(
                        color: Colors.white.withOpacity(0.0),
                        blurRadius: 20,
                      )
                    ],
                  ),
                )
                .animate(delay: 2.seconds) // Phase 3 starts at 2.0s
                .tint(color: const Color(0xFFFEFCBF), duration: 600.ms)
                .then(delay: 400.ms)
                .tint(color: Colors.transparent, duration: 400.ms),

                // Main Text (PESACROW)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('P', style: GoogleFonts.inter(fontSize: 32, letterSpacing: 4, fontWeight: FontWeight.w900, color: gold)),
                    Text('ES', style: GoogleFonts.inter(fontSize: 32, letterSpacing: 4, fontWeight: FontWeight.w900, color: darkCharcoal))
                        .animate(delay: 1400.ms) // Shakes slightly after appearing
                        .shake(hz: 4, curve: Curves.easeOut, duration: 400.ms),
                    Text('A', style: GoogleFonts.inter(fontSize: 32, letterSpacing: 4, fontWeight: FontWeight.w900, color: gold)),
                    Text('CROW', style: GoogleFonts.inter(fontSize: 32, letterSpacing: 4, fontWeight: FontWeight.w900, color: darkCharcoal))
                        .animate(delay: 1400.ms) // Shakes slightly after appearing
                        .shake(hz: 4, curve: Curves.easeOut, duration: 400.ms),
                  ],
                )
                // Phase 2 Reveal: Wipe from left to right at 1.0s
                .animate(delay: 1.seconds)
                .fadeIn(duration: 400.ms)
                .shimmer(duration: 600.ms, color: Colors.white)
                // Phase 3: Text dims slightly as ESCROW glows
                .then(delay: 400.ms)
                .tint(color: Colors.black12, duration: 600.ms)
                .then(delay: 400.ms)
                .tint(color: Colors.transparent, duration: 400.ms)
                // Phase 4: Final Glint across the wordmark at 3.0s
                .then(delay: 200.ms)
                .shimmer(
                  duration: 800.ms,
                  color: Colors.white.withOpacity(0.8),
                  angle: 0.5,
                  size: 2,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Phase 4: The Tagline
            Text(
              "TRUSTING THEM SO YOU DON'T HAVE TO",
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 3, // Wide letter-spacing
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
              ),
            )
            .animate(delay: 3.seconds)
            .slideY(begin: 1.0, end: 0.0, duration: 800.ms, curve: Curves.easeOutQuart)
            .fadeIn(duration: 800.ms)
            // Final Hold till 6.0s
            .then(delay: 1500.ms),
          ],
        ),
      ),
    );
  }
}
