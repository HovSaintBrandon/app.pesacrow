import 'dart:developer' as dev;
import 'dart:convert';

class LoggerService {
  static const String _tag = 'PesaCrow';

  static void logScreen(String name) {
    print('📱 SCREEN: $name');
  }

  static void logEvent(String name, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? '\n  Data: ${_prettyJson(data)}' : '';
    print('⚡ EVENT: $name$dataStr');
  }

  static void logApiRequest(String method, String url, dynamic body) {
    print('\n╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('┃ 🚀 API REQ [$method]');
    print('┃ 🔗 $url');
    if (body != null && body.toString().isNotEmpty) {
      print('┃ 📦 Payload:\n${_indentHtml(_prettyJson(body))}');
    }
    print('╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  static void logApiResponse(String method, String url, int statusCode, dynamic body) {
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final icon = isSuccess ? '✅' : '❌';
    print('\n╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('┃ $icon API RES [$method] ($statusCode)');
    print('┃ 🔗 $url');
    if (body != null && body.toString().isNotEmpty) {
      print('┃ ⬅️ Response:\n${_indentHtml(_prettyJson(body))}');
    }
    print('╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  static void logError(String message, [dynamic error, StackTrace? stack]) {
    print('\n🔴 ERROR: $message\n  Error: $error\n  Stack: $stack\n');
  }

  static String _prettyJson(dynamic data) {
    try {
      if (data is String) data = jsonDecode(data);
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  static String _indentHtml(String text) {
    return text.split('\n').map((line) => '┃    $line').join('\n');
  }
}
