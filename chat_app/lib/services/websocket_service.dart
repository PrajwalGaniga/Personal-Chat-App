// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final _messageController  = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController   = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<bool>                 get onStatus  => _statusController.stream;

  bool _connected = false;
  bool get isConnected => _connected;

  // ── Connect ──────────────────────────────────────────────────────────
  Future<void> connect(String phone, String token) async {
    await disconnect();

    final uri = Uri.parse(AppConstants.wsUrl(phone, token));
    _channel = WebSocketChannel.connect(uri);

    await _channel!.ready.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('WebSocket connection timed out'),
    );

    _connected = true;
    _statusController.add(true);

    _subscription = _channel!.stream.listen(
      (raw) {
        try {
          final data = jsonDecode(raw as String) as Map<String, dynamic>;
          _messageController.add(data);
        } catch (_) {/* ignore malformed frames */}
      },
      onDone: _onDisconnected,
      onError: (_) => _onDisconnected(),
      cancelOnError: false,
    );
  }

  // ── Send text message ─────────────────────────────────────────────────
  void sendText(String content) {
    _channel?.sink.add(jsonEncode({
      'content':      content,
      'message_type': 'text',
    }));
  }

  // ── Disconnect ────────────────────────────────────────────────────────
  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel      = null;
    if (_connected) {
      _connected = false;
      _statusController.add(false);
    }
  }

  void _onDisconnected() {
    _connected = false;
    if (!_statusController.isClosed) {
      _statusController.add(false);
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
  }
}
