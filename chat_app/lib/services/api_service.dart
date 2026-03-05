// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/message.dart';

class ApiService {
  // ── Message History ──────────────────────────────────────────────────
  Future<List<Message>> fetchHistory({int limit = 50, int skip = 0}) async {
    final uri = Uri.parse(AppConstants.historyUrl)
        .replace(queryParameters: {'limit': '$limit', 'skip': '$skip'});

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load history: ${response.statusCode}');
  }

  // ── Delete Message ────────────────────────────────────────────────────
  Future<void> deleteMessage(String messageId, String senderPhone) async {
    final uri = Uri.parse(AppConstants.deleteUrl(messageId))
        .replace(queryParameters: {'sender_phone': senderPhone});
    final response = await http.delete(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete message: ${response.body}');
    }
  }

  // ── Upload Image ──────────────────────────────────────────────────────
  /// Uploads an image file and returns the resulting Message map from the server.
  Future<Map<String, dynamic>> uploadImage(
      File imageFile, String senderPhone) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppConstants.uploadUrl),
    );
    request.fields['sender_phone'] = senderPhone;
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Upload failed: ${response.body}');
  }
}
