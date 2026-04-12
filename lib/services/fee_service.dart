import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fee_breakdown.dart';
import '../config/api_config.dart';
import '../services/logger_service.dart';
import '../services/api_service.dart';

class FeeService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<FeeBreakdown> calculateFees(double amount) async {
    final url = Uri.parse('$baseUrl/fees/calculate?amount=$amount');
    LoggerService.logApiRequest('GET', url.toString(), null);

    try {
      final res = await http.get(url);
      final data = jsonDecode(res.body);
      LoggerService.logApiResponse('GET', url.toString(), res.statusCode, data);

      if (res.statusCode == 200 && data['success'] == true) {
        return FeeBreakdown.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to calculate fees');
      }
    } catch (e) {
      LoggerService.logError('Fee calculation failed', e);
      rethrow;
    }
  }
}
