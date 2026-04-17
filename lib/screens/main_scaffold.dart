import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/deal.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';
import '../widgets/status_badge.dart';
import 'buyer_dashboard_screen.dart';
import 'seller_dashboard_screen.dart';
import 'join_deal_screen.dart';
import 'create_deal_screen.dart';
import 'payout_preferences_screen.dart';
import 'profile_screen.dart';
import 'role_selection_screen.dart';
import '../widgets/mode_shift_overlay.dart';
import '../services/sse_service.dart';
import 'dart:async';

// ── Breakpoints ────────────────────────────────────────────────────────────────
const double _kWebBreakpoint = 800.0;

bool get _isWebPlatform => kIsWeb;

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  static const _green = Color(0xFF2E9D5B);
  static const _blue = Color(0xFF3182CE);

  void _showRoleSwitcher(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withOpacity(0.3),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) {
        final isBuyer = auth.activeRole == 'buyer';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: SizedBox(width: 40, height: 4, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFE5E7EB), borderRadius: BorderRadius.all(Radius.circular(2)))))),
              const SizedBox(height: 24),
              Text('Switch Experience', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Tailor the app for your current needs', style: TextStyle(color: Colors.grey.shade500, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              _SwitcherCard(title: 'Buying Mode', subtitle: 'Pay with Escrow Protection', icon: Icons.shield_outlined, color: _green, selected: isBuyer,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(ctx);
                  ModeShiftOverlay.show(context, toBuyer: true);
                  Future.delayed(const Duration(milliseconds: 400), () {
                    auth.setActiveRole('buyer');
                    setState(() => _currentIndex = 0);
                  });
                }),
              const SizedBox(height: 12),
              _SwitcherCard(title: 'Selling Mode', subtitle: 'Get paid with PesaCrow Secure', icon: Icons.lock_outline, color: _blue, selected: !isBuyer,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(ctx);
                  ModeShiftOverlay.show(context, toBuyer: false);
                  Future.delayed(const Duration(milliseconds: 400), () {
                    auth.setActiveRole('seller');
                    setState(() => _currentIndex = 0);
                  });
                }),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isBuyer = auth.activeRole == 'buyer';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Breakpoints for true responsiveness
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    if (auth.activeRole == null) return const RoleSelectionScreen();

    final buyerScreens = [
      const BuyerDashboardScreen(isInScaffold: true),
      const _AllDealsTab(role: 'buyer'),
      const JoinDealScreen(isInScaffold: true),
      const ProfileScreen(),
    ];
    final sellerScreens = [
      const SellerDashboardScreen(isInScaffold: true),
      const _AllDealsTab(role: 'seller'),
      const CreateDealScreen(isInScaffold: true),
      const ProfileScreen(),
    ];

    final currentScreens = isBuyer ? buyerScreens : sellerScreens;
    final activeColor = isBuyer ? _green : _blue;

    if (!isMobile) {
      return _buildDesktopLayout(context, auth, isBuyer, activeColor, currentScreens, theme, isTablet);
    }

    return _buildMobileLayout(context, auth, isBuyer, activeColor, currentScreens, theme);
  }

  // ── DESKTOP/TABLET LAYOUT ──────────────────────────────────────────────────

  Widget _buildDesktopLayout(
    BuildContext context,
    AuthProvider auth,
    bool isBuyer,
    Color activeColor,
    List<Widget> screens,
    ThemeData theme,
    bool isTablet,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final sidebarWidth = isTablet ? 80.0 : 280.0;
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);

    final buyerNavItems = [
      _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'Dashboard'),
      _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'My Deals'),
      _NavItem(icon: Icons.qr_code_scanner_rounded, activeIcon: Icons.qr_code_scanner_rounded, label: 'Join Deal'),
      _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Account'),
    ];
    final sellerNavItems = [
      _NavItem(icon: Icons.analytics_outlined, activeIcon: Icons.analytics_rounded, label: 'Earnings'),
      _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'My Deals'),
      _NavItem(icon: Icons.add_circle_outline_rounded, activeIcon: Icons.add_circle_rounded, label: 'New Deal'),
      _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Account'),
    ];
    final navItems = isBuyer ? buyerNavItems : sellerNavItems;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // ── Sidebar ───────────────────────────────────────────────────────
          _buildSidebar(context, auth, isBuyer, activeColor, navItems, isDark, borderColor, sidebarWidth, isTablet),

          // ── Main Workspace ────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top header
                _buildTopBar(context, auth, isBuyer, activeColor, navItems, theme, borderColor),

                // Content area with max-width centering
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                        child: AnimatedSwitcher(
                          duration: 300.ms,
                          child: IndexedStack(
                            key: ValueKey('${auth.activeRole}-$_currentIndex'),
                            index: _currentIndex.clamp(0, screens.length - 1),
                            children: screens,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    AuthProvider auth,
    bool isBuyer,
    Color activeColor,
    List<_NavItem> navItems,
    bool isDark,
    Color borderColor,
    double width,
    bool isCollapsed,
  ) {
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          // Branding
          Padding(
            padding: EdgeInsets.symmetric(vertical: 32, horizontal: isCollapsed ? 0 : 28),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Image.asset('assets/launcher_foreground.png', width: 24, height: 24, fit: BoxFit.contain),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 14),
                  Text(
                    'PesaCrow',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Experience Switcher
          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: InkWell(
                onTap: () => _showRoleSwitcher(context, auth),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: activeColor.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.swap_horizontal_circle_outlined, color: activeColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isBuyer ? 'Switch to Selling' : 'Switch to Buying',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: activeColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Navigation Links
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: navItems.length,
              itemBuilder: (_, i) {
                final item = navItems[i];
                final isActive = _currentIndex == i;
                return _SideNavItem(
                  item: item,
                  isActive: isActive,
                  activeColor: activeColor,
                  isDark: isDark,
                  isCollapsed: isCollapsed,
                  onTap: () => setState(() => _currentIndex = i),
                );
              },
            ),
          ),

          // Footer info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (!isCollapsed)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 14, backgroundColor: activeColor.withOpacity(0.2), child: Text(auth.phone?.substring(auth.phone!.length - 1) ?? '?', style: TextStyle(color: activeColor, fontSize: 10, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 10),
                        Expanded(child: Text(auth.phone ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20, color: Colors.grey.shade500),
                  onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AuthProvider auth,
    bool isBuyer,
    Color activeColor,
    List<_NavItem> navItems,
    ThemeData theme,
    Color borderColor,
  ) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Text(
            _pageTitle(navItems).toUpperCase(),
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.grey.shade500),
          ),
          const Spacer(),
          // Quick actions
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
            child: Row(
              children: [
                _topBarIcon(Icons.search_rounded),
                const SizedBox(width: 8),
                _topBarIcon(Icons.notifications_none_rounded),
                const SizedBox(width: 8),
                _topBarIcon(Icons.logout_rounded, color: Colors.red.withOpacity(0.7), onTap: () => auth.logout()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBarIcon(IconData icon, {Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 20, color: color ?? Colors.grey.shade400),
      ),
    );
  }

  String _pageTitle(List<_NavItem> items) {
    if (_currentIndex < items.length) return items[_currentIndex].label;
    return 'PesaCrow';
  }

  // ── MOBILE LAYOUT ──────────────────────────────────────────────────────────

  Widget _buildMobileLayout(
    BuildContext context,
    AuthProvider auth,
    bool isBuyer,
    Color activeColor,
    List<Widget> screens,
    ThemeData theme,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => _showRoleSwitcher(context, auth),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle),
                ),
                Text(
                  isBuyer ? 'Buying Mode' : 'Selling Mode',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 18, color: activeColor),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(theme.brightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          IconButton(icon: const Icon(Icons.notifications_none_outlined), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: 200.ms,
        child: IndexedStack(
          key: ValueKey(auth.activeRole),
          index: _currentIndex.clamp(0, screens.length - 1),
          children: screens,
        ),
      ),
      bottomNavigationBar: _buildMobileNavBar(context, isBuyer: isBuyer, activeColor: activeColor),
    );
  }

  Widget _buildMobileNavBar(BuildContext context, {required bool isBuyer, required Color activeColor}) {
    final items = isBuyer
        ? [
            _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'Home'),
            _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'My Deals'),
            _NavItem(icon: Icons.qr_code_scanner, activeIcon: Icons.qr_code_scanner, label: 'Join'),
            _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
          ]
        : [
            _NavItem(icon: Icons.analytics_outlined, activeIcon: Icons.analytics_rounded, label: 'Home'),
            _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'My Deals'),
            _NavItem(icon: Icons.add_circle_outline_rounded, activeIcon: Icons.add_circle_rounded, label: 'Create'),
            _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
          ];

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 75,
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isActive = _currentIndex == i;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _currentIndex = i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive ? activeColor : const Color(0xFF9CA3AF),
                        size: 26,
                      ),
                    ).animate(target: isActive ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15)),
                    if (isActive)
                      Container(
                        width: 4, height: 4,
                        decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle),
                      ).animate().fadeIn().scale(),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Side Nav Item (Web) ────────────────────────────────────────────────────────

class _SideNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final Color activeColor;
  final bool isDark;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.item,
    required this.isActive,
    required this.activeColor,
    required this.isDark,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 16, vertical: 14),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(
            isActive ? item.activeIcon : item.icon,
            size: 22,
            color: isActive ? activeColor : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 14),
            Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive ? activeColor : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Tooltip(
        message: isCollapsed ? item.label : '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: content,
        ),
      ),
    );
  }
}

// ── All Deals Tab ──────────────────────────────────────────────────────────────

class _AllDealsTab extends StatefulWidget {
  final String role;
  const _AllDealsTab({required this.role});

  @override
  State<_AllDealsTab> createState() => _AllDealsTabState();
}

class _AllDealsTabState extends State<_AllDealsTab> {
  List<Deal> _deals = [];
  bool _loading = false;
  StreamSubscription<SseEvent>? _sseSub;

  @override
  void initState() {
    super.initState();
    _load();
    _sseSub = SseService.stream.listen((_) => _load());
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final deals = await ApiService.listMyDeals(role: widget.role);
      if (mounted) setState(() => _deals = deals);
    } catch (e) {
      LoggerService.logError('Load all deals failed', e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBuyer = widget.role == 'buyer';
    final color = isBuyer ? const Color(0xFF2E9D5B) : const Color(0xFF3182CE);
    final fmt = NumberFormat('#,###');
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = kIsWeb && screenWidth >= _kWebBreakpoint;

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_deals.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isBuyer ? Icons.shopping_basket_outlined : Icons.storefront_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No deals yet', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
        ]),
      );
    }

    // On wide web: 2-column grid; on mobile: single column list
    Widget list = isWide
        ? GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 420,
              mainAxisExtent: 88,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _deals.length,
            itemBuilder: (_, i) => _dealTile(_deals[i], color, fmt, context),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _deals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _dealTile(_deals[i], color, fmt, context),
            ).animate(delay: 50.ms).fadeIn(),
          );

    return list;
  }

  Widget _dealTile(Deal d, Color color, NumberFormat fmt, BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/deal/${d.transactionId}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(widget.role == 'buyer' ? Icons.shield_outlined : Icons.lock_outline, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.description, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text('KSh ${fmt.format(d.amount)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            ])),
            const SizedBox(width: 12),
            StatusBadge(status: d.status),
          ],
        ),
      ),
    );
  }
}

// ── Role Switcher Card ─────────────────────────────────────────────────────────

class _SwitcherCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SwitcherCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.1), width: 1.5),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? color : Theme.of(context).colorScheme.onSurface)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ])),
          if (selected) Icon(Icons.check_circle, color: color, size: 20),
        ]),
      ),
    );
  }
}

// ── Nav Item Model ─────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
