import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/sse_service.dart';
class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _phone;
  String? _role;
  String? _activeRole;

  String? get token => _token;
  String? get phone => _phone;
  String? get role => _role;
  String? get activeRole => _activeRole;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('mpescrow_token');
    _phone = prefs.getString('mpescrow_phone');
    _role = prefs.getString('mpescrow_role');
    _activeRole = prefs.getString('mpescrow_active_role');
    // Re-open SSE connection if a session is already stored (app restart).
    if (_token != null) SseService.connect();
    notifyListeners();
  }

  Future<void> setActiveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mpescrow_active_role', role);
    _activeRole = role;
    notifyListeners();
  }

  Future<void> login(String token, String phone, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mpescrow_token', token);
    await prefs.setString('mpescrow_phone', phone);
    await prefs.setString('mpescrow_role', role);
    _token = token;
    _phone = phone;
    _role = role;
    // Open the SSE channel as soon as the session is established.
    SseService.connect();
    notifyListeners();
  }

  Future<void> logout() async {
    // Close the SSE channel before clearing the token so the disconnect
    // call can still read the token if needed during teardown.
    SseService.disconnect();
    await ApiService.logout(); // Invalidate server-side session
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mpescrow_token');
    await prefs.remove('mpescrow_phone');
    await prefs.remove('mpescrow_role');
    await prefs.remove('mpescrow_active_role');
    _token = null;
    _phone = null;
    _role = null;
    _activeRole = null;
    notifyListeners();
  }
}
