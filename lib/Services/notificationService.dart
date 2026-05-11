import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:http/http.dart' as http;

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? materialName;
  final String? productSku;
  final String? proposedExpiry;
  final String? managerName;
  bool isRead;

  AppNotification({
    String? id,
    required this.title,
    required this.body,
    DateTime? createdAt,
    this.materialName,
    this.productSku,
    this.proposedExpiry,
    this.managerName,
    this.isRead = false,
  }) : id = id ?? 'NOT-${DateTime.now().millisecondsSinceEpoch}',
       createdAt = createdAt ?? DateTime.now();
}

class NotificationService {
  static const String _baseUrl = 'http://chemistore.runasp.net/api';
  static const String fallbackSupervisorEmail = 'supervisor@chemistore.com';
  static final List<AppNotification> _notifications = [];
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    changes.value++;
  }

  static List<AppNotification> getAll() => List.unmodifiable(_notifications);

  static List<AppNotification> getUnread() =>
      _notifications.where((notification) => !notification.isRead).toList();

  static void markAllRead() {
    for (final notification in _notifications) {
      notification.isRead = true;
    }
    changes.value++;
  }

  static void markRead(String id) {
    for (final notification in _notifications) {
      if (notification.id == id) {
        notification.isRead = true;
        break;
      }
    }
    changes.value++;
  }

  static Future<void> sendEditRequestEmail({
    required String productName,
    required String productSku,
    required String managerName,
    required String newExpiry,
  }) async {
    try {
      final emails = await _getSupervisorEmails();
      for (final email in emails) {
        try {
          await _sendEditRequestEmail(
            to: email,
            productName: productName,
            productSku: productSku,
            managerName: managerName,
            newExpiry: newExpiry,
          );
        } catch (e) {
          debugPrint('Edit request email to $email failed: $e');
        }
      }
    } catch (e) {
      debugPrint('Edit request email failed: $e');
    }
  }

  static Future<List<String>> _getSupervisorEmails() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/Auth/supervisors'),
            headers: AuthService.authHeaders,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'Supervisor lookup failed (${response.statusCode}); using fallback email.',
        );
        return const [fallbackSupervisorEmail];
      }

      final decoded = _decodeBody(response.body);
      final emails = _extractEmails(decoded).toSet().toList();
      if (emails.isEmpty) {
        debugPrint('Supervisor lookup returned no emails; using fallback.');
        return const [fallbackSupervisorEmail];
      }

      return emails;
    } catch (e) {
      debugPrint('Supervisor lookup failed: $e; using fallback email.');
      return const [fallbackSupervisorEmail];
    }
  }

  static Future<void> _sendEditRequestEmail({
    required String to,
    required String productName,
    required String productSku,
    required String managerName,
    required String newExpiry,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/Notifications/send-email'),
          headers: AuthService.authHeaders,
          body: jsonEncode({
            'to': to,
            'subject': 'Edit Request: $productName',
            'body':
                '$managerName has requested an expiry date change for $productName (SKU: $productSku). Proposed new expiry: $newExpiry. Please review and approve or reject this request in the Orders page.',
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        'Edit request email to $to failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  static dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  static List<String> _extractEmails(dynamic decoded) {
    final emails = <String>[];

    void visit(dynamic value) {
      if (value is List) {
        for (final item in value) {
          visit(item);
        }
        return;
      }

      if (value is Map) {
        for (final key in const [
          'email',
          'emailAddress',
          'userEmail',
          'mail',
        ]) {
          final email = value[key]?.toString().trim();
          if (email != null && _looksLikeEmail(email)) {
            emails.add(email);
          }
        }

        for (final key in const [
          'data',
          'items',
          'result',
          'users',
          'supervisors',
        ]) {
          if (value.containsKey(key)) {
            visit(value[key]);
          }
        }
      }
    }

    visit(decoded);
    return emails;
  }

  static bool _looksLikeEmail(String value) {
    return value.contains('@') && value.contains('.');
  }
}
