import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── Enums & Models ────────────────────────────────────────────────────────────

enum UserRole {
  warehouseManager, // maps to "Admin" from the API
  supervisor,       // maps to "User"  from the API
}

class UserModel {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final UserRole role;
  final String token; // JWT returned by the API

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    required this.token,
  });

  /// Parse the login/register response JSON into a UserModel.
  /// Adjust field names here if the real API returns different keys.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Role mapping: "Admin" → warehouseManager, everything else → supervisor
    final rawRole = (json['role'] ?? json['userRole'] ?? '').toString().toLowerCase();
    final role = rawRole == 'admin'
        ? UserRole.warehouseManager
        : UserRole.supervisor;

    return UserModel(
      id: (json['id'] ?? json['userId'] ?? '').toString(),
      username: (json['userName'] ?? json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? json['userName'] ?? '').toString(),
      role: role,
      token: (json['token'] ?? json['accessToken'] ?? '').toString(),
    );
  }
}

// ─── AuthService ────────────────────────────────────────────────────────────────

class AuthService {
  static const String _baseUrl = 'https://chemistore.runasp.net/api/Auth';

  static UserModel? _currentUser;

  // ── Public getters ──────────────────────────────────────────────────────────

  static UserModel? get currentUser => _currentUser;

  static bool get isWarehouseManager =>
      _currentUser?.role == UserRole.warehouseManager;

  static bool get isSupervisor =>
      _currentUser?.role == UserRole.supervisor;

  static String get token => _currentUser?.token ?? '';

  // ── Login ───────────────────────────────────────────────────────────────────

  /// Returns null on success (sets [_currentUser]).
  /// Returns an error message string on failure.
  static Future<String?> login(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userName': username,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _currentUser = UserModel.fromJson(body);
        return null; // success
      }

      // Try to extract a meaningful error message from the response
      final msg = body['message'] ??
          body['error'] ??
          body['title'] ??
          'Login failed (${response.statusCode})';
      return msg.toString();
    } catch (e) {
      return 'Network error: ${e.toString()}';
    }
  }

  // ── Register Admin (Warehouse Manager) ─────────────────────────────────────

  /// Returns null on success, error message string on failure.
  static Future<String?> registerAdmin({
    required String username,
    required String email,
    required String password,
    String fullName = '',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/register/admin'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userName': username,
              'email': email,
              'password': password,
              'fullName': fullName,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // success
      }

      final body = jsonDecode(response.body);
      final msg = body['message'] ??
          body['error'] ??
          body['title'] ??
          'Registration failed (${response.statusCode})';
      return msg.toString();
    } catch (e) {
      return 'Network error: ${e.toString()}';
    }
  }

  // ── Register User (Supervisor) ──────────────────────────────────────────────

  /// Returns null on success, error message string on failure.
  static Future<String?> registerUser({
    required String username,
    required String email,
    required String password,
    String fullName = '',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/register/user'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userName': username,
              'email': email,
              'password': password,
              'fullName': fullName,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // success
      }

      final body = jsonDecode(response.body);
      final msg = body['message'] ??
          body['error'] ??
          body['title'] ??
          'Registration failed (${response.statusCode})';
      return msg.toString();
    } catch (e) {
      return 'Network error: ${e.toString()}';
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────────────

  static void logout() {
    _currentUser = null;
  }
}