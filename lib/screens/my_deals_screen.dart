import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'buyer_dashboard_screen.dart';
import 'seller_dashboard_screen.dart';
import 'role_selection_screen.dart';

class MyDealsScreen extends StatelessWidget {
  const MyDealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Deals')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Please login to view your deals'),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Login / Verify'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (auth.activeRole == null) {
      return const RoleSelectionScreen();
    }

    if (auth.activeRole == 'buyer') {
      return const BuyerDashboardScreen();
    }

    return const SellerDashboardScreen();
  }
}
