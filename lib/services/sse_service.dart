import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'logger_service.dart';

/// Maintains a persistent Server-Sent Events connection to [GET /user/events].
///
/// Broadcasts [SseEvent] objects to all active listeners in real time.
/// Handles authentication, automatic reconnect on stream loss, and graceful
/// disconnection on logout.
///
/// Usage:
/// ```dart
/// SseService.stream
///   .where((e) => e.transactionId == myTxId)
///   .listen((e) { /* live update */ });
/// ```
class SseService {
  SseService._();

  // Single broadcast controller — lives for the entire app session.
  static final _controller = StreamController<SseEvent>.broadcast();

  static http.Client? _client;
  static StreamSubscription<String>? _lineSubscription;
  static Timer? _reconnectTimer;
  static bool _connected = false;
  static bool _shouldReconnect = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// All SSE events from the server, broadcast to every active subscriber.
  static Stream<SseEvent> get stream => _controller.stream;

  /// Whether the SSE connection is currently live.
  static bool get isConnected => _connected;

  /// Opens the SSE connection. Safe to call multiple times — idempotent when
  /// already connected.
  static Future<void> connect() async {
    if (_connected) return;
    _shouldReconnect = true;
    await _openConnection();
  }

  /// Permanently closes the connection and cancels scheduled reconnects.
  /// Call this on logout.
  static void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _lineSubscription?.cancel();
    _lineSubscription = null;
    _client?.close();
    _client = null;
    _connected = false;
    if (kDebugMode) LoggerService.logEvent('SSE_DISCONNECTED', {});
  }

  // ---------------------------------------------------------------------------
  // Internal connection logic
  // ---------------------------------------------------------------------------

  static Future<void> _openConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('mpescrow_token');
    if (token == null) {
      // No session — nothing to connect.
      return;
    }

    // Tear down any previous connection.
    _lineSubscription?.cancel();
    _lineSubscription = null;
    _client?.close();
    _client = http.Client();

    try {
      final request = http.Request(
        'GET',
        Uri.parse('${ApiConfig.baseUrl}/user/events'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Connection'] = 'keep-alive';

      if (kDebugMode) {
        LoggerService.logEvent('SSE_CONNECTING', {
          'url': '${ApiConfig.baseUrl}/user/events',
        });
      }

      final streamed = await _client!.send(request);

      if (streamed.statusCode == 401) {
        if (kDebugMode) LoggerService.logEvent('SSE_UNAUTHORIZED', {});
        // Token is invalid — do not attempt reconnect.
        _shouldReconnect = false;
        _client?.close();
        _client = null;
        return;
      }

      if (streamed.statusCode != 200) {
        if (kDebugMode) {
          LoggerService.logError('SSE_CONNECT_FAILED', 'HTTP ${streamed.statusCode}');
        }
        _client?.close();
        _client = null;
        if (_shouldReconnect) _scheduleReconnect();
        return;
      }

      _connected = true;
      if (kDebugMode) LoggerService.logEvent('SSE_CONNECTED', {});

      // --- SSE line parser ---
      // SSE frame:
      //   event: <type>        (optional)
      //   data: <json payload>
      //   <blank line>         → dispatch

      String dataBuffer = '';
      String eventTypeBuffer = '';

      _lineSubscription = streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.startsWith('event:')) {
            eventTypeBuffer = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            dataBuffer = line.substring(5).trim();
          } else if (line.isEmpty && dataBuffer.isNotEmpty) {
            // Blank line ⟹ dispatch the buffered event.
            _dispatch(eventTypeBuffer, dataBuffer);
            dataBuffer = '';
            eventTypeBuffer = '';
          }
          // Lines starting with ':' are SSE comments / heartbeats — ignore.
        },
        onDone: () {
          _connected = false;
          if (kDebugMode) LoggerService.logEvent('SSE_STREAM_ENDED', {});
          if (_shouldReconnect) _scheduleReconnect();
        },
        onError: (Object e, StackTrace st) {
          _connected = false;
          if (kDebugMode) LoggerService.logError('SSE_STREAM_ERROR', e, st);
          if (_shouldReconnect) _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e, st) {
      _connected = false;
      if (kDebugMode) LoggerService.logError('SSE_OPEN_FAILED', e, st);
      _client?.close();
      _client = null;
      if (_shouldReconnect) _scheduleReconnect();
    }
  }

  static void _dispatch(String rawType, String rawData) {
    try {
      final payload = jsonDecode(rawData) as Map<String, dynamic>;

      // Resolve the event type: prefer the SSE `event:` field, then look
      // inside the JSON body, and finally fall back to 'message'.
      final type = rawType.isNotEmpty
          ? rawType
          : (payload['type'] as String? ?? 'message');

      final event = SseEvent(type: type, data: payload);

      if (kDebugMode) {
        LoggerService.logEvent('SSE_EVENT', {
          'type': event.type,
          'transactionId': event.transactionId,
          'status': event.status,
        });
      }

      _controller.add(event);
    } catch (e) {
      if (kDebugMode) LoggerService.logError('SSE_PARSE_ERROR', e);
    }
  }

  static void _scheduleReconnect({
    Duration delay = const Duration(seconds: 5),
  }) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_shouldReconnect && !_connected) {
        if (kDebugMode) LoggerService.logEvent('SSE_RECONNECTING', {});
        _openConnection();
      }
    });
  }
}

// ---------------------------------------------------------------------------
// SseEvent model
// ---------------------------------------------------------------------------

/// A single parsed event received over the SSE connection.
class SseEvent {
  const SseEvent({required this.type, required this.data});

  /// The SSE event type (from `event:` field or `data.type`).
  final String type;

  /// The full JSON payload.
  final Map<String, dynamic> data;

  /// Transaction ID, resolved from common backend payload shapes:
  ///   `{ transactionId: "..." }` or `{ data: { transactionId: "..." } }`.
  String? get transactionId =>
      data['transactionId'] as String? ??
      (data['data'] as Map<String, dynamic>?)?['transactionId'] as String?;

  /// Deal status, resolved from common payload shapes.
  String? get status =>
      data['status'] as String? ??
      (data['data'] as Map<String, dynamic>?)?['status'] as String?;

  @override
  String toString() => 'SseEvent(type: $type, txId: $transactionId, status: $status)';
}
