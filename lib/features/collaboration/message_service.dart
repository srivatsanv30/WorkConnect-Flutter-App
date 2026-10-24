import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../auth/auth_service.dart';

class MessageService {
  Future<List<Map<String, dynamic>>> fetchMessages(String jobId) async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/jobs/$jobId/messages'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['messages'] as List?) ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> sendMessage(
    String jobId, {
    String? text,
    String? imageUrl,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/jobs/$jobId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text ?? '',
          if (imageUrl != null) 'imageUrl': imageUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['message'] != null) {
          return Map<String, dynamic>.from(data['message'] as Map);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteMessage({
    required String jobId,
    required String messageId,
    required bool forEveryone,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse(
          '${AppConstants.baseUrl}/jobs/$jobId/messages/$messageId?forEveryone=$forEveryone',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}