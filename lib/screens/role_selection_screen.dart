import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'main_scaffold.dart';
import '../services/logger_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:flutter_animate/flutter_animate.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo hero
                  Center(
                    child: Image.asset(
                      'assets/launcher_foreground.png',
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.9, 0.9)),
                  
                  const SizedBox(height: 60),

                  // Responsive Role Cards
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildBuyerCard(context, auth)),
                        const SizedBox(width: 32),
                        Expanded(child: _buildSellerCard(context, auth)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildBuyerCard(context, auth),
                        const SizedBox(height: 24),
                        _buildSellerCard(context, auth),
                      ],
                    ),

                  const SizedBox(height: 80),

                  // Slogan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/launcher_foreground.png',
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SEND . HOLD . TRUST',
                        style: GoogleFonts.inter(
                          fontSize: 14, 
                          letterSpacing: 4,
                          fontWeight: FontWeight.w900, 
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 60),

                  // Footer
                  Column(
                    children: [
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final version = snapshot.hasData ? '${snapshot.data!.version}' : '...';
                          return Text(
                            'PESACROW PLATFORM v$version',
                            style: TextStyle(color: Colors.grey.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'absolute anonymity advanced services (A3S)',
                        style: TextStyle(color: Colors.grey.withOpacity(0.25), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                      ),
                    ],
                  ).animate().fadeIn(delay: 1.seconds),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBuyerCard(BuildContext context, AuthProvider auth) {
    return _RoleCard(
      title: 'Buy Securely',
      desc: 'Pay for goods or services. Your funds are protected in our vault until you confirm delivery.',
      icon: Icons.verified_user_rounded,
      accentColor: const Color(0xFF2E9D5B),
      buttonText: 'CONTINUE AS BUYER',
      onTap: () async {
        LoggerService.logEvent('ROLE_SELECTED', {'role': 'buyer'});
        if (!auth.isAuthenticated) {
          Navigator.pushNamed(context, '/login', arguments: {'role': 'buyer'});
          return;
        }
        await auth.setActiveRole('buyer');
        if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScaffold()));
      },
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildSellerCard(BuildContext context, AuthProvider auth) {
    return _RoleCard(
      title: 'Sell with Confidence',
      desc: 'Generate secure links. Funds are locked before you ship. Get paid instantly upon approval.',
      icon: Icons.account_balance_rounded,
      accentColor: const Color(0xFF3182CE),
      buttonText: 'CONTINUE AS SELLER',
      onTap: () async {
        LoggerService.logEvent('ROLE_SELECTED', {'role': 'seller'});
        if (!auth.isAuthenticated) {
          Navigator.pushNamed(context, '/login', arguments: {'role': 'seller'});
          return;
        }
        await auth.setActiveRole('seller');
        if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScaffold()));
      },
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }
}

class _RoleCard extends StatefulWidget {
  final String title, desc, buttonText;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.desc,
    required this.buttonText,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 300.ms,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: _isHovered ? widget.accentColor.withOpacity(0.5) : Colors.white.withOpacity(0.05),
              width: 2,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with Glow
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (_isHovered)
                      BoxShadow(
                        color: widget.accentColor.withOpacity(0.2),
                        blurRadius: 20,
                      ),
                  ],
                ),
                child: Icon(widget.icon, color: widget.accentColor, size: 40),
              ),
              const SizedBox(height: 32),
              
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 24, 
                  fontWeight: FontWeight.w900, 
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                widget.desc,
                style: TextStyle(
                  fontSize: 15, 
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, 
                  height: 1.6, 
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),

              // Button
              AnimatedContainer(
                duration: 200.ms,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: _isHovered ? widget.accentColor : widget.accentColor.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (_isHovered)
                      BoxShadow(
                        color: widget.accentColor.withOpacity(0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.buttonText,
                    style: GoogleFonts.inter(
                      color: Colors.white, 
                      fontWeight: FontWeight.w900, 
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
