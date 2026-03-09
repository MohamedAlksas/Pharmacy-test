import 'package:graduation_project/Models/alertModel.dart';
import 'package:graduation_project/Models/materialModel.dart';
import 'package:graduation_project/Services/MaterialSerivce.dart';


class AlertService {
  static final List<AlertModel> _alerts = [];

  // Initialize alerts based on materials
  static void initializeAlerts() {
    _alerts.clear();
    final materials = MaterialService.getAllMaterials();

    for (final material in materials) {
      _checkAndCreateAlerts(material);
    }
  }

  static void _checkAndCreateAlerts(MaterialModel material) {
    // Check for expired materials
    if (_isExpired(material.expiryDate)) {
      _alerts.add(
        AlertModel(
          id: 'alert_expired_${material.id}',
          alertType: 'expired',
          message:
              '${material.name} has expired on ${material.expiryDate}. Remove from inventory immediately.',
          material: material,
          createdAt: DateTime.now(),
        ),
      );
    }
    // Check for materials expiring soon (within 30 days)
    else if (_isExpiringSoon(material.expiryDate)) {
      final daysLeft = _daysUntilExpiry(material.expiryDate);
      _alerts.add(
        AlertModel(
          id: 'alert_expiring_${material.id}',
          alertType: 'expiring_soon',
          message:
              '${material.name} will expire in $daysLeft days on ${material.expiryDate}.',
          material: material,
          createdAt: DateTime.now(),
        ),
      );
    }

    // Check for low stock (less than 100 units)
    if (material.quantity < 100) {
      _alerts.add(
        AlertModel(
          id: 'alert_lowstock_${material.id}',
          alertType: 'low_stock',
          message:
              '${material.name} is running low. Current stock: ${material.quantity} units.',
          material: material,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  static bool _isExpired(String expiryDate) {
    try {
      final expiry = DateTime.parse(expiryDate);
      return expiry.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  static bool _isExpiringSoon(String expiryDate) {
    try {
      final expiry = DateTime.parse(expiryDate);
      final now = DateTime.now();
      final difference = expiry.difference(now).inDays;
      return difference > 0 && difference <= 30;
    } catch (e) {
      return false;
    }
  }

  static int _daysUntilExpiry(String expiryDate) {
    try {
      final expiry = DateTime.parse(expiryDate);
      final now = DateTime.now();
      return expiry.difference(now).inDays;
    } catch (e) {
      return 0;
    }
  }

  // Get all alerts
  static List<AlertModel> getAllAlerts() {
    return List.unmodifiable(_alerts);
  }

  // Get alerts by type
  static List<AlertModel> getAlertsByType(String type) {
    return _alerts.where((alert) => alert.alertType == type).toList();
  }

  // Get critical alerts (expired + expiring soon)
  static List<AlertModel> getCriticalAlerts() {
    return _alerts
        .where((alert) =>
            alert.alertType == 'expired' || alert.alertType == 'expiring_soon')
        .toList();
  }

  // Get alert counts
  static int getExpiredMaterialsCount() {
    return _alerts.where((alert) => alert.alertType == 'expired').length;
  }

  static int getExpiringSoonCount() {
    return _alerts.where((alert) => alert.alertType == 'expiring_soon').length;
  }

  static int getLowStockCount() {
    return _alerts.where((alert) => alert.alertType == 'low_stock').length;
  }

  // Add custom alert
  static void addAlert(AlertModel alert) {
    _alerts.add(alert);
  }

  // Remove alert
  static void removeAlert(String alertId) {
    _alerts.removeWhere((alert) => alert.id == alertId);
  }

  // Clear all alerts
  static void clearAllAlerts() {
    _alerts.clear();
  }

  // Refresh alerts
  static void refreshAlerts() {
    initializeAlerts();
  }
}