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
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}