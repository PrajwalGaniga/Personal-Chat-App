// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user.dart';

class AuthService {
  static const _keyPhone = 'phone';
  static const _keyToken = 'token';
  static const _keyName  = 'name';

  // ── Login ────────────────────────────────────────────────────────────
  Future<User> login(String phone) async {
    final response = await http.post(
      Uri.parse(AppConstants.loginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone.trim()}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = User.fromJson(data, token);
      await _save(user);
      return user;
    } else if (response.statusCode == 403) {
      throw Exception('Access denied. Only Prajwal and Ishwarya can use this app.');
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  // ── Persist & restore ────────────────────────────────────────────────
  Future<void> _save(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhone, user.phone);
    await prefs.setString(_keyToken, user.token);
    await prefs.setString(_keyName,  user.name);
  }

  Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(_keyPhone);
    final token = prefs.getString(_keyToken);
    final name  = prefs.getString(_keyName);
    if (phone == null || token == null || name == null) return null;
    return User(phone: phone, name: name, token: token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
