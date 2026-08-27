import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../auth/auth_service.dart';

/// Talks to the backend to register this device's FCM token and
/// fetch the user's in-app notification list.
class NotificationService {
  Future<void> registerDeviceToken(String token) async {
    final authToken = await AuthService().getToken();
    if (authToken == null) return;

    try {
      await http.post(
        Uri.parse('${AppConstants.baseUrl}/notifications/register-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcmToken': token}),
      );
    } catch (_) {
      // silently ignore — not critical to app function
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final authToken = await AuthService().getToken();
    if (authToken == null) return [];

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/notifications'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['notifications'] as List?) ?? [];
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> markAsRead(String id) async {
    final authToken = await AuthService().getToken();
    if (authToken == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/notifications/$id/read'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}