import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../auth/auth_service.dart';

class TrackingResult {
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? job;

  TrackingResult({required this.success, this.errorMessage, this.job});
}

class TrackingService {
  Future<TrackingResult> updateStatus(String jobId, String status) async {
    final token = await AuthService().getToken();
    if (token == null) {
      return TrackingResult(success: false, errorMessage: 'You must be logged in.');
    }

    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/jobs/$jobId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return TrackingResult(success: true, job: data['job']);
      }
      return TrackingResult(success: false, errorMessage: data['message'] ?? 'Failed to update status');
    } catch (e) {
      return TrackingResult(success: false, errorMessage: 'Could not reach server: $e');
    }
  }

  Future<TrackingResult> addMilestone(String jobId, String title) async {
    final token = await AuthService().getToken();
    if (token == null) {
      return TrackingResult(success: false, errorMessage: 'You must be logged in.');
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/jobs/$jobId/milestones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'title': title}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) {
        return TrackingResult(success: true, job: data['job']);
      }
      return TrackingResult(success: false, errorMessage: data['message'] ?? 'Failed to add milestone');
    } catch (e) {
      return TrackingResult(success: false, errorMessage: 'Could not reach server: $e');
    }
  }

  Future<TrackingResult> toggleMilestone(String jobId, String milestoneId) async {
    final token = await AuthService().getToken();
    if (token == null) {
      return TrackingResult(success: false, errorMessage: 'You must be logged in.');
    }
    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/jobs/$jobId/milestones/$milestoneId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return TrackingResult(success: true, job: data['job']);
      }
      return TrackingResult(success: false, errorMessage: data['message'] ?? 'Failed to update milestone');
    } catch (e) {
      return TrackingResult(success: false, errorMessage: 'Could not reach server: $e');
    }
  }
}