import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deal.dart';
import '../config/api_config.dart';
import '../services/logger_service.dart';

class ApiService {
  // Use the baseUrl from ApiConfig
  static const String baseUrl = ApiConfig.baseUrl;

  // Global callback for unauthorized (401) events
  static Function()? onUnauthorized;

  static void _checkStatus(int statusCode, dynamic data, {bool ignoreUnauthorized = false}) {
    if (statusCode == 401 && !ignoreUnauthorized) {
      LoggerService.logError('UNAUTHORIZED', 'Session expired (401)');
      onUnauthorized?.call();
      throw Exception('Unauthorized');
    }
    if (statusCode >= 400) {
      throw Exception(data['message'] ?? 'Request failed');
    }
  }

  static Future<Map<String, String>> _headers({bool isJson = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('mpescrow_token');
    return {
      if (isJson) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body, {bool ignoreUnauthorized = false}) async {
    LoggerService.logApiRequest('POST', '$baseUrl$path', body);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      LoggerService.logApiResponse('POST', '$baseUrl$path', res.statusCode, data);
      _checkStatus(res.statusCode, data, ignoreUnauthorized: ignoreUnauthorized);
      return data;
    } catch (e) {
      LoggerService.logError('POST $path failed', e);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _get(String path, {bool ignoreUnauthorized = false}) async {
    LoggerService.logApiRequest('GET', '$baseUrl$path', null);
    try {
      final res = await http.get(Uri.parse('$baseUrl$path'), headers: await _headers());
      final data = jsonDecode(res.body);
      LoggerService.logApiResponse('GET', '$baseUrl$path', res.statusCode, data);
      _checkStatus(res.statusCode, data, ignoreUnauthorized: ignoreUnauthorized);
      return data;
    } catch (e) {
      LoggerService.logError('GET $path failed', e);
      rethrow;
    }
  }

  static Future<List<dynamic>> _getList(String path, {bool ignoreUnauthorized = false}) async {
    LoggerService.logApiRequest('GET', '$baseUrl$path', null);
    try {
      final res = await http.get(Uri.parse('$baseUrl$path'), headers: await _headers());
      final data = jsonDecode(res.body);
      LoggerService.logApiResponse('GET', '$baseUrl$path', res.statusCode, data);
      _checkStatus(res.statusCode, data, ignoreUnauthorized: ignoreUnauthorized);
      
      if (data is List) return data;
      if (data is Map && data['data'] is List) return data['data'] as List<dynamic>;
      return [];
    } catch (e) {
      LoggerService.logError('GET (List) $path failed', e);
      rethrow;
    }
  }

  // === Auth ===
  static Future<void> logout() async {
    try {
      await _post('/auth/logout', {}, ignoreUnauthorized: true);
    } catch (_) {
      // Swallow — local session is cleared regardless of server response
    }
  }

  static Future<Map<String, dynamic>> sendOtp({
    required String transactionId,
    required String phone,
    required String role,
    String? action,
  }) => _post('/auth/send-otp', {
        'transactionId': transactionId,
        'phone': phone,
        'role': role,
        if (action != null) 'action': action,
      });

  static Future<Map<String, dynamic>> verifyOtp({
    required String transactionId,
    required String phone,
    required String otp,
    required String role,
  }) => _post('/auth/verify-otp', {
        'transactionId': transactionId,
        'phone': phone,
        'otp': otp,
        'role': role,
      });

  // === Deals ===
  static Future<Map<String, dynamic>> createDeal({
    required String sellerPhone,
    required int amount,
    required String description,
    String? buyerPhone,
  }) async {
    final data = await _post('/deals/create', {
      'sellerPhone': sellerPhone,
      'amount': amount,
      'description': description,
      if (buyerPhone != null) 'buyerPhone': buyerPhone,
    });
    return data;
  }

  static Future<Deal> getDealDetails(String transactionId) async {
    final data = await _get('/deals/$transactionId');
    return Deal.fromJson(data['data'] ?? data);
  }

  static Future<String> getDealStatus(String transactionId) async {
    final data = await _get('/deals/$transactionId/status');
    final returnData = data['data'] ?? data;
    return returnData['status'] ?? '';
  }

  static Future<List<Deal>> listMyDeals({String? role}) async {
    final path = role != null ? '/deals?role=$role' : '/deals';
    final data = await _getList(path);
    return data.map((e) => Deal.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> markDelivered(String transactionId) async =>
      _post('/deals/$transactionId/deliver', {});

  static Future<void> requestChanges(String transactionId, String note) async =>
      _post('/deals/$transactionId/changes', {'note': note});

  static Future<void> approveDeal(String transactionId) async =>
      _post('/deals/$transactionId/approve', {});

  static Future<void> disputeDeal(String transactionId, String reason) async =>
      _post('/deals/$transactionId/dispute', {'reason': reason});

  static Future<void> cancelDeal(String transactionId) async =>
      _post('/deals/$transactionId/cancel', {});

  static Future<void> uploadProof(String transactionId, File file) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/deals/$transactionId/proof'));
    final headers = await _headers(isJson: false);
    req.headers.addAll(headers);
    req.files.add(await http.MultipartFile.fromPath('proofFile', file.path));
    final streamedRes = await req.send();
    if (streamedRes.statusCode >= 400) throw Exception('Upload failed');
  }

  static Future<void> retryPayoutSeller(String transactionId, String payoutPhone) async =>
      _post('/deals/$transactionId/retry-payout-seller', {'payoutPhone': payoutPhone});

  // === User Preferences ===
  static Future<Map<String, dynamic>> getPayoutPreference() async {
    final data = await _get('/user/payout-preference');
    return data['data'] ?? data;
  }

  static Future<void> setPayoutPreference(Map<String, dynamic> prefData) async {
    await _post('/user/payout-preference', prefData);
  }

  // === Payments ===
  static Future<Map<String, dynamic>> initiateStk({
    required String transactionId,
    required String buyerPhone,
  }) => _post('/payments/initiate-stk', {
        'transactionId': transactionId,
        'buyerPhone': buyerPhone,
      });
}
