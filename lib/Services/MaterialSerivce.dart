import 'dart:collection';

// MaterialService is a read-only compatibility shim.
// ProductProvider owns mutations and passes the same live list reference here
// so older status/filter helpers do not keep a separate product copy.

import 'package:graduation_project/Models/materialModel.dart';

class MaterialService {
  // The provider sets this after every load/mutation.
  static List<MaterialModel> _cache = [];

  /// Called by ProductProvider every time _products changes.
  static void updateCache(List<MaterialModel> products) {
    _cache = products;
  }

  // ── Read-only helpers (UI compatibility) ──────────────────────────────────

  static List<MaterialModel> getAllMaterials() => UnmodifiableListView(_cache);

  static MaterialModel? getMaterialById(String id) {
    try {
      return _cache.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  static String getMaterialStatus(MaterialModel material) {
    try {
      final expiry = DateTime.parse(material.expiryDate);
      final now = DateTime.now();
      if (expiry.isBefore(now)) return 'Expired';
      if (expiry.difference(now).inDays <= 30) return 'Expiring Soon';
      if (material.quantity < 100) return 'Low Stock';
      return 'Good';
    } catch (_) {
      return 'Unknown';
    }
  }

  static List<MaterialModel> getMaterialsByCategory(String category) =>
      _cache.where((m) => m.category == category).toList();

  static List<MaterialModel> getLowStockMaterials() =>
      _cache.where((m) => m.quantity < 100).toList();

  static List<MaterialModel> getExpiredMaterials() => _cache.where((m) {
    try {
      return DateTime.parse(m.expiryDate).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }).toList();

  static List<MaterialModel> getExpiringSoonMaterials() => _cache.where((m) {
    try {
      final diff = DateTime.parse(
        m.expiryDate,
      ).difference(DateTime.now()).inDays;
      return diff > 0 && diff <= 30;
    } catch (_) {
      return false;
    }
  }).toList();

  static List<Map<String, dynamic>> getMaterialsAsMap() =>
      _cache.map((m) => m.toJson()).toList();
}
