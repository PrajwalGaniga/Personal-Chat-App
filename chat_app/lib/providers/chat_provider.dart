// lib/providers/chat_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';

enum AppState { loading, login, chat }

class ChatProvider extends ChangeNotifier {
  final _authService = AuthService();
  final _apiService  = ApiService();
  final _wsService   = WebSocketService();

  // ── State ────────────────────────────────────────────────────────────
  AppState   appState     = AppState.loading;
  User?      currentUser;
  List<Message> messages = [];
  bool       wsConnected = false;
  bool       otherOnline = false;
  bool       isSending   = false;
  String?    errorMessage;

  // Track which phones are online
  final Set<String> _onlinePhones = {};

  // ── Init ──────────────────────────────────────────────────────────────
  Future<void> init() async {
    final saved = await _authService.getSavedUser();
    if (saved != null) {
      currentUser = saved;
      await _afterLogin();
    } else {
      appState = AppState.login;
      notifyListeners();
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────
  Future<void> login(String phone) async {
    try {
      errorMessage = null;
      currentUser = await _authService.login(phone);
      await _afterLogin();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> _afterLogin() async {
    appState = AppState.chat;
    notifyListeners();
    await _loadHistory();
    await _connectWs();
  }

  // ── History ───────────────────────────────────────────────────────────
  Future<void> _loadHistory() async {
    try {
      final hist = await _apiService.fetchHistory(limit: 100);
      messages = hist;
      notifyListeners();
    } catch (_) { /* silent on history fail */ }
  }

  // ── WebSocket ─────────────────────────────────────────────────────────
  Future<void> _connectWs() async {
    final user = currentUser;
    if (user == null) return;
    try {
      await _wsService.connect(user.phone, user.token);
      wsConnected = true;
      notifyListeners();
      _wsService.onMessage.listen(_handleWsEvent);
      _wsService.onStatus.listen((connected) {
        wsConnected = connected;
        if (!connected) _scheduleReconnect();
        notifyListeners();
      });
    } catch (_) {
      wsConnected = false;
      _scheduleReconnect();
      notifyListeners();
    }
  }

  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (currentUser != null && !wsConnected) _connectWs();
    });
  }

  void _handleWsEvent(Map<String, dynamic> data) {
    final event = data['event'] as String?;
    switch (event) {
      case 'new_message':
        final msg = Message.fromJson({
          'id':           data['id'],
          'sender_phone': data['sender_phone'],
          'sender_name':  data['sender_name'],
          'content':      data['content'],
          'message_type': data['message_type'] ?? 'text',
          'timestamp':    data['timestamp'],
          'date_label':   data['date_label'] ?? '',
        });
        // Avoid duplicates (e.g. REST send vs WS broadcast)
        if (!messages.any((m) => m.id == msg.id)) {
          messages = [...messages, msg];
          notifyListeners();
        }
      case 'user_online':
        final phone = data['phone'] as String?;
        if (phone != null) _onlinePhones.add(phone);
        _updateOtherOnline();
      case 'user_offline':
        final phone = data['phone'] as String?;
        if (phone != null) _onlinePhones.remove(phone);
        _updateOtherOnline();
    }
  }

  void _updateOtherOnline() {
    final mine = currentUser?.phone;
    otherOnline = _onlinePhones.any((p) => p != mine);
    notifyListeners();
  }

  // ── Send text ─────────────────────────────────────────────────────────
  void sendTextMessage(String text) {
    if (text.trim().isEmpty) return;
    if (wsConnected) {
      _wsService.sendText(text.trim());
    }
  }

  // ── Send image ────────────────────────────────────────────────────────
  Future<void> sendImage(File imageFile) async {
    final user = currentUser;
    if (user == null) return;
    isSending = true;
    notifyListeners();
    try {
      await _apiService.uploadImage(imageFile, user.phone);
      // Reload history to show the uploaded image message
      await _loadHistory();
    } catch (e) {
      errorMessage = 'Image upload failed: $e';
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  // ── Delete message ─────────────────────────────────────────────────────
  Future<void> deleteMessage(String messageId) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await _apiService.deleteMessage(messageId, user.phone);
      messages = messages.where((m) => m.id != messageId).toList();
      notifyListeners();
    } catch (e) {
      errorMessage = 'Delete failed: $e';
      notifyListeners();
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _wsService.disconnect();
    await _authService.logout();
    currentUser = null;
    messages    = [];
    wsConnected = false;
    otherOnline = false;
    appState    = AppState.login;
    notifyListeners();
  }

  // ── Other user info ───────────────────────────────────────────────────
  String get otherUserName {
    final phones = AppConstants.users.keys.toList();
    final other = phones.firstWhere(
      (p) => p != currentUser?.phone,
      orElse: () => '',
    );
    return AppConstants.users[other] ?? 'Chat';
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }
}
