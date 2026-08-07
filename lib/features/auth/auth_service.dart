import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import 'user_model.dart';


class AuthResult {
  final bool success;
  final String? errorMessage;
  final AppUser? user;

  AuthResult({required this.success, this.errorMessage, this.user});
}

/// Handles signup/login calls to the Express backend and persists the
/// JWT locally so the user stays logged in between app launches.
class AuthService {
  static const _tokenKey = 'wc_auth_token';
  Future<String?> getCurrentUserId() async {
  // We don't store the user object, only the token — decode isn't needed
  // since job_detail_screen already has creator/assignedTo IDs to compare.
  // This is a placeholder for now; wire it from MainShell's user object instead.
  return null;
}

  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
    List<String> skills = const [],
  }) async {
    return _authRequest(
      endpoint: '/auth/signup',
      body: {'name': name, 'email': email, 'password': password, 'skills': skills},
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    return _authRequest(
      endpoint: '/auth/login',
      body: {'email': email, 'password': password},
    );
  }

  Future<AuthResult> _authRequest({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['token'] as String;
        await _saveToken(token);
        final user = AppUser.fromJson(data['user']);
        return AuthResult(success: true, user: user);
      } else {
        return AuthResult(success: false, errorMessage: data['message'] ?? 'Request failed');
      }
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Could not reach server: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
