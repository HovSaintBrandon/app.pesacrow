import 'package:flutter/material.dart';
import '../services/logger_service.dart';
import '../services/seo_service.dart';

class AppNavObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateMetadata(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _updateMetadata(newRoute);
    }
  }

  void _updateMetadata(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null) return;

    LoggerService.logScreen(name);

    String title = "PesaCrow";
    String description = "Kenya's most trusted digital escrow platform. Secure your transactions with M-Pesa.";

    final uri = Uri.parse(name);
    final segments = uri.pathSegments;
    final primaryPath = segments.isEmpty ? '' : segments[0];

    switch (primaryPath) {
      case '':
        title = "PesaCrow | Secure Digital Escrow in Kenya";
        break;
      case 'create':
        title = "Create Secure Deal | PesaCrow Escrow";
        description = "Start a safe online transaction. Send M-Pesa to escrow and protect your purchase.";
        break;
      case 'join':
        title = "Join Secure Deal | PesaCrow Escrow";
        description = "Join an existing escrow deal using a transaction ID. Trade with confidence.";
        break;
      case 'share':
      case 'deal':
      case 'd':
        title = "View Transaction | PesaCrow Escrow";
        description = "Check the status of your secure PesaCrow transaction. Safe and transparent.";
        break;
      case 'my-deals':
      case 'home':
      case 'buyer-dashboard':
      case 'seller-dashboard':
        title = "Dashboard | PesaCrow Escrow";
        break;
      case 'login':
        title = "Login | PesaCrow";
        break;
    }

    SeoService.updateSEO(
      title: title,
      description: description,
    );
  }
}
