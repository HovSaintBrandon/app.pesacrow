import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // Add this
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/create_deal_screen.dart';
import 'screens/share_deal_screen.dart';
import 'screens/deal_dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/buyer_dashboard_screen.dart';
import 'screens/seller_dashboard_screen.dart';
import 'screens/join_deal_screen.dart';
import 'screens/payout_preferences_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/profile_screen.dart';
import 'screens/animated_splash_screen.dart';
import 'utils/nav_observer.dart';
import 'services/api_service.dart';
import 'widgets/web_frame.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  usePathUrlStrategy(); // Add this
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider();

  ApiService.onUnauthorized = () {
    auth.logout();
    navigatorKey.currentState?.pushNamedAndRemoveUntil('role-selection', (route) => false);
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MpeSaCrowApp(),
    ),
  );
}

class MpeSaCrowApp extends StatelessWidget {
  const MpeSaCrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isBuyer = auth.activeRole == 'buyer';
    final primaryColor = isBuyer ? const Color(0xFF2E9D5B) : const Color(0xFF3182CE);

    return MaterialApp(
      title: 'PesaCrow',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      navigatorObservers: [AppNavObserver()],
      themeMode: themeProvider.themeMode,
      theme: _buildLightTheme(context, primaryColor, isBuyer),
      darkTheme: _buildDarkTheme(context, primaryColor, isBuyer),
      builder: (context, child) => child ?? const SizedBox.shrink(),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        final args = settings.arguments as Map<String, dynamic>?;

        switch (uri.pathSegments.isEmpty ? '' : uri.pathSegments[0]) {
          case '':
            return _fade(const AnimatedSplashScreen(), settings);
          case 'login':
            return _fade(LoginScreen(
              transactionId: args?['transactionId'],
              role: args?['role'],
            ), settings);
          case 'create':
            return _fade(const CreateDealScreen(), settings);
          case 'share':
            final txId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : '';
            return _fade(ShareDealScreen(transactionId: txId), settings);
          case 'deal':
          case 'd':
            final txId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : '';
            return _fade(DealDashboardScreen(transactionId: txId), settings);
          case 'my-deals':
          case 'home':
            return _fade(const MainScaffold(), settings);
          case 'buyer-dashboard':
            return _fade(const BuyerDashboardScreen(), settings);
          case 'seller-dashboard':
            return _fade(const SellerDashboardScreen(), settings);
          case 'join':
            return _fade(const JoinDealScreen(), settings);
          case 'payout-preferences':
            return _fade(const PayoutPreferencesScreen(), settings);
          case 'role-selection':
            return _fade(const LoginScreen(), settings);
          default:
            return _fade(const LoginScreen(), settings);
        }
      },
    );
  }

  PageRoute _fade(Widget page, RouteSettings settings) => PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 250),
      );

  ThemeData _buildLightTheme(BuildContext context, Color primaryColor, bool isBuyer) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: isBuyer ? const Color(0xFFE8F5EE) : const Color(0xFFE3F2FD),
        surface: Colors.white,
        error: const Color(0xFFE53E3E),
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F9F7),
      cardColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF7F9F7), // Match scaffold
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A1A), letterSpacing: -0.5),
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryColor, size: 24),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.withOpacity(0.08))),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: BorderSide(color: Colors.grey.withOpacity(0.15)),
          foregroundColor: const Color(0xFF1A1A1A),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
        prefixIconColor: const Color(0xFF9CA3AF),
      ),
      dividerTheme: DividerThemeData(color: Colors.grey.withOpacity(0.1), thickness: 1),
    );
  }

  ThemeData _buildDarkTheme(BuildContext context, Color primaryColor, bool isBuyer) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: isBuyer ? const Color(0xFF1B4332) : const Color(0xFF1A365D),
        surface: const Color(0xFF121212), // Higher layer
        onSurface: Colors.white,
        error: const Color(0xFFFC8181),
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0A0A), // Deepest layer
      cardColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryColor, size: 24),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF121212),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 64),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: 0.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF181818),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.06))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.06))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
        prefixIconColor: const Color(0xFF6B7280),
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withOpacity(0.06), thickness: 1),
    );
  }
}
