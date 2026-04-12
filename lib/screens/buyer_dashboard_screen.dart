import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/deal.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../core/notifications.dart';
import '../widgets/status_badge.dart';
import '../widgets/hakikisha_modal.dart';
import '../utils/phone_formatter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/transaction_hub.dart';

import '../widgets/finance_hub_overlay.dart';
import 'faq_screen.dart';
import 'terms_screen.dart';

class BuyerDashboardScreen extends StatefulWidget {
  final bool isInScaffold;
  const BuyerDashboardScreen({super.key, this.isInScaffold = false});

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  List<Deal> _deals = [];
  bool _loading = false;
  bool _balanceHidden = false;

  static const _green = Color(0xFF2E9D5B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDeals());
  }

  Future<void> _loadDeals() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    setState(() => _loading = true);
    try {
      final deals = await ApiService.listMyDeals(role: 'buyer');
      if (mounted) setState(() => _deals = deals);
    } catch (e) {
      AppNotifications.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _activeCount => _deals.where((d) => d.status != 'released' && d.status != 'disputed' && d.status != 'cancelled').length;
  int get _totalLocked => _deals.where((d) => d.status == 'held' || d.status == 'delivered').fold(0, (s, d) => s + d.amount);
  List<Deal> get _recentDeals => _deals.where((d) => d.status != 'cancelled').toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    final fmt = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadDeals,
        displacement: 40,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        floating: true,
                        pinned: true,
                        elevation: 0,
                        title: Text('Buyer Hub', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: isDesktop ? 24 : 18, letterSpacing: -0.5)),
                        centerTitle: !isDesktop,
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.account_balance_wallet_rounded, color: _green),
                            onPressed: () => _showFinanceHub(),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),

                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            TransactionHub(
                              totalLocked: 'KSh ${fmt.format(_totalLocked)}',
                              availableBalance: 'KSh 0',
                              accentColor: _green,
                              isBalanceHidden: _balanceHidden,
                              onToggleBalance: () => setState(() => _balanceHidden = !_balanceHidden),
                            ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.98, 0.98)),

                            const SizedBox(height: 48),

                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Active Purchases', style: GoogleFonts.inter(fontSize: isDesktop ? 22 : 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                                  if (_recentDeals.isNotEmpty)
                                    TextButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.list_alt_rounded, size: 16),
                                      label: Text('All Purchases', style: TextStyle(color: _green, fontWeight: FontWeight.w800, fontSize: 13)),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            if (_recentDeals.isEmpty)
                              _buildEmptyState()
                            else if (isDesktop)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 20,
                                    mainAxisSpacing: 20,
                                    mainAxisExtent: 220,
                                  ),
                                  itemCount: _recentDeals.length,
                                  itemBuilder: (ctx, i) => _DealCard(deal: _recentDeals[i], onRefresh: _loadDeals),
                                ),
                              )
                            else
                              SizedBox(
                                height: 220,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  itemCount: _recentDeals.length,
                                  itemBuilder: (ctx, i) {
                                    return SizedBox(
                                      width: screenWidth * 0.85,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 16),
                                        child: _DealCard(deal: _recentDeals[i], onRefresh: _loadDeals),
                                      ),
                                    ).animate(delay: (i * 100).ms).fadeIn().slideX(begin: 0.05);
                                  },
                                ),
                              ),

                            const SizedBox(height: 60),
                            _buildQuickActions(isDesktop),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/join'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                minimumSize: const Size(double.infinity, 70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 20,
                shadowColor: _green.withOpacity(0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text('JOIN SECURE ESCROW', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                ],
              ).animate().shimmer(duration: 2.seconds, color: Colors.white24),
            ),
          ),
        ),
      ).animate(delay: 1.seconds).slideY(begin: 1.0, end: 0.0),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showFinanceHub() {
    final fmt = NumberFormat('#,###');
    FinanceHubOverlay.show(
      context,
      pendingDeals: _activeCount.toString(),
      escrowHeld: 'KSh ${fmt.format(_totalLocked)}',
      accentColor: _green,
      recentDeals: _deals,
    );
  }

  Widget _buildQuickActions(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal Hub', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: isDesktop ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 1.4 : 1.1,
            children: [
              _QuickActionCard(
                title: 'Help Center',
                subtitle: 'Tutorials & FAQs',
                icon: Icons.help_center_rounded,
                color: Colors.orange.shade400,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen())),
              ),
              _QuickActionCard(
                title: 'Terms Hub',
                subtitle: 'Safety & Privacy',
                icon: Icons.admin_panel_settings_rounded,
                color: Colors.blue.shade400,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
              ),
              if (isDesktop) ...[
                _QuickActionCard(
                  title: 'Secure Wallet',
                  subtitle: 'Deposit History',
                  icon: Icons.account_balance_rounded,
                  color: Colors.teal.shade400,
                  onTap: () {},
                ),
                _QuickActionCard(
                  title: 'Notifications',
                  subtitle: 'Alert Settings',
                  icon: Icons.notifications_active_rounded,
                  color: Colors.pink.shade400,
                  onTap: () {},
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate(delay: 500.ms).fadeIn();
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), shape: BoxShape.circle),
            child: Icon(Icons.shopping_basket_rounded, size: 80, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 32),
          Text('No active purchases', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          Text('Your buyer profile is clear. Enter a Transaction ID from a seller to begin shopping with full escrow protection.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.6)),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionCard({required this.title, required this.subtitle, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final Deal deal;
  final VoidCallback? onRefresh;
  const _DealCard({required this.deal, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final theme = Theme.of(context);
    
    final statusMap = {
      'pending_payment': 'ACTION REQUIRED',
      'held': 'SECURED IN ESCROW',
      'delivered': 'DELIVERY NOTIFIED',
      'released': 'COMPLETED',
      'approved': 'COMPLETED',
    };
    final actionText = statusMap[deal.status] ?? 'VIEW DETAILS';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.pushNamed(context, '/deal/${deal.transactionId}');
          onRefresh?.call();
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(status: deal.status),
                  Text(deal.transactionId.substring(0, 10).toUpperCase(), style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 20),
              Text(deal.description, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PAYMENT', style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text('KSh ${fmt.format(deal.amount)}', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, color: theme.colorScheme.primary)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
