import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../auth/auth_service.dart';

class JobResult {
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? job;

  JobResult({required this.success, this.errorMessage, this.job});
}

/// Talks to POST /api/jobs and GET /api/jobs on your Express backend.
/// Requires the user to be logged in (JWT attached automatically).
class JobService {
  Future<JobResult> createJob({
    required String title,
    required String description,
    required List<String> skillsRequired,
    required String priority,
    required String deadline, // ISO date string e.g. 2026-08-15
    List<String>? milestones,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) {
      return JobResult(success: false, errorMessage: 'You must be logged in.');
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/jobs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'description': description,
          'skillsRequired': skillsRequired,
          'priority': priority,
          'deadline': deadline,
          if (milestones != null) 'milestones': milestones,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return JobResult(success: true, job: data['job']);
      } else {
        return JobResult(success: false, errorMessage: data['message'] ?? 'Failed to post job');
      }
    } catch (e) {
      return JobResult(success: false, errorMessage: 'Could not reach server: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchJobs() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/jobs'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final jobs = (data['jobs'] as List?) ?? [];
        return jobs.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<JobResult> assignApplicant(String jobId, String applicantId) async {
    final token = await AuthService().getToken();
    if (token == null) {
      return JobResult(success: false, errorMessage: 'You must be logged in.');
    }

    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/jobs/$jobId/assign'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'applicantId': applicantId}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return JobResult(success: true, job: data['job']);
      } else {
        return JobResult(success: false, errorMessage: data['message'] ?? 'Failed to assign');
      }
    } catch (e) {
      return JobResult(success: false, errorMessage: 'Could not reach server: $e');
    }
  }

  Future<JobResult> applyToJob(String jobId) async {
    final token = await AuthService().getToken();
    if (token == null) {
      return JobResult(success: false, errorMessage: 'You must be logged in.');
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/jobs/$jobId/apply'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return JobResult(success: true, job: data['job']);
      } else {
        return JobResult(success: false, errorMessage: data['message'] ?? 'Failed to apply');
      }
    } catch (e) {
      return JobResult(success: false, errorMessage: 'Could not reach server: $e');
    }
  }

  Future<JobResult> aiBreakdown(String idea) async {
    final token = await AuthService().getToken();
    if (token == null) {
      return JobResult(success: false, errorMessage: 'You must be logged in.');
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/ai/breakdown'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'idea': idea}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return JobResult(success: true, job: data);
      } else {
        return JobResult(success: false, errorMessage: data['message'] ?? 'AI breakdown failed');
      }
    } catch (e) {
      return JobResult(success: false, errorMessage: 'Could not reach server: $e');
    }
  }

  Future<JobResult> completeReview(String jobId, int rating, String reviewText) async {
    final token = await AuthService().getToken();
    if (token == null) {
      return JobResult(success: false, errorMessage: 'You must be logged in.');
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/jobs/$jobId/complete-review'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'rating': rating, 'reviewText': reviewText}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return JobResult(success: true, job: data['job']);
      } else {
        return JobResult(success: false, errorMessage: data['message'] ?? 'Failed to complete');
      }
    } catch (e) {
      return JobResult(success: false, errorMessage: 'Could not reach server: $e');
    }
  }

  Future<JobResult> reviewFeedback(String jobId, String action, String feedback) async {
    final token = await AuthService().getToken();
    if (token == null) {
      return JobResult(success: false, errorMessage: 'You must be logged in.');
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/jobs/$jobId/review-feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'action': action, 'feedback': feedback}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return JobResult(success: true, job: data['job']);
      } else {
        return JobResult(success: false, errorMessage: data['message'] ?? 'Failed to process review');
      }
    } catch (e) {
      return JobResult(success: false, errorMessage: 'Could not reach server: $e');
    }
  }

  Future<Map<String, dynamic>> fetchReputation(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/$userId/reputation'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }
}