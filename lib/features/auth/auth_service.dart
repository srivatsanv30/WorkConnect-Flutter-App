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
  static const _userIdKey = 'wc_user_id';
  static const _userDataKey = 'wc_user_data';

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<AppUser?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userDataKey);
      if (userJson != null) {
        return AppUser.fromJson(jsonDecode(userJson));
      }
    } catch (_) {}
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

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent',
          'devOtp': data['devOtp'],
        };
      }
      return {
        'success': false,
        'errorMessage': data['message'] ?? 'Failed to generate code',
      };
    } catch (e) {
      return {'success': false, 'errorMessage': 'Could not reach server: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset successful',
        };
      }
      return {
        'success': false,
        'errorMessage': data['message'] ?? 'Failed to reset password',
      };
    } catch (e) {
      return {'success': false, 'errorMessage': 'Could not reach server: $e'};
    }
  }

  Future<AuthResult> updateProfile({
    String? name,
    List<String>? skills,
    String? bio,
    String? title,
    String? phone,
    String? location,
  }) async {
    final token = await getToken();
    if (token == null) return AuthResult(success: false, errorMessage: 'Not logged in');

    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (skills != null) body['skills'] = skills;
      if (bio != null) body['bio'] = bio;
      if (title != null) body['title'] = title;
      if (phone != null) body['phone'] = phone;
      if (location != null) body['location'] = location;

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final user = AppUser.fromJson(data['user']);
        await _saveAuthData(token: token, user: user, userJson: jsonEncode(data['user']));
        return AuthResult(success: true, user: user);
      } else {
        return AuthResult(success: false, errorMessage: data['message'] ?? 'Update failed');
      }
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Could not reach server: $e');
    }
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
        final user = AppUser.fromJson(data['user']);
        await _saveAuthData(token: token, user: user, userJson: jsonEncode(data['user']));
        return AuthResult(success: true, user: user);
      } else {
        return AuthResult(success: false, errorMessage: data['message'] ?? 'Request failed');
      }
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Could not reach server: $e');
    }
  }

  Future<List<AppUser>> searchUsers(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users?query=$query'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final usersData = data['users'] as List;
        return usersData.map((e) => AppUser.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveAuthData({
    required String token,
    required AppUser user,
    required String userJson,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_userDataKey, userJson);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userDataKey);
  }
}
