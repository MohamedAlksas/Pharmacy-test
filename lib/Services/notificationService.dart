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
  static const String supervisorEmail = 'supervisor@chemistore.com';
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
    String to = supervisorEmail,
  }) async {
    try {
      await http
          .post(
            Uri.parse('$_baseUrl/Notifications/send-email'),
            headers: AuthService.authHeaders,
            body: jsonEncode({
              'to': to,
              'subject': 'Edit Request: $productName',
              'body':
                  '$managerName has requested an expiry date change for $productName (SKU: $productSku). New expiry: $newExpiry. Please review in the Orders page.',
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Edit request email failed: $e');
    }
  }
}
