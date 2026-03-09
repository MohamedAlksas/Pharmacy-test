import 'package:graduation_project/Models/materialModel.dart';

class MaterialService {
  static final List<MaterialModel> _materials = [
    MaterialModel(
      id: '1',
      name: 'Paracetamol 500mg',
      sku: 'SKU-PARA500',
      lot: 'LOT-0001',
      location: 'Shelf A-1',
      quantity: 620,
      expiryDate: '2026-01-20',
      category: 'Analgesic',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    MaterialModel(
      id: '2',
      name: 'Ibuprofen 400mg',
      sku: 'SKU-IBU400',
      lot: 'LOT-0002',
      location: 'Shelf A-2',
      quantity: 185,
      expiryDate: '2025-05-11',
      category: 'Analgesic',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    MaterialModel(
      id: '3',
      name: 'Amoxicillin 250mg',
      sku: 'SKU-AMX250',
      lot: 'LOT-0003',
      location: 'Shelf A-3',
      quantity: 90,
      expiryDate: '2025-10-01',
      category: 'Antibiotic',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    MaterialModel(
      id: '4',
      name: 'Saline Solution 0.9%',
      sku: 'SKU-SAL090',
      lot: 'LOT-0004',
      location: 'Shelf B-1',
      quantity: 52,
      expiryDate: '2027-02-15',
      category: 'IV Fluids',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    MaterialModel(
      id: '5',
      name: 'Vitamin C 500mg',
      sku: 'SKU-VIT500',
      lot: 'LOT-0005',
      location: 'Shelf B-2',
      quantity: 330,
      expiryDate: '2026-09-10',
      category: 'Supplements',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  // Get all materials
  static List<MaterialModel> getAllMaterials() {
    return List.unmodifiable(_materials);
  }

  // Get material by ID
  static MaterialModel? getMaterialById(String id) {
    try {
      return _materials.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  // Add material
  static void addMaterial(MaterialModel material) {
    _materials.add(material);
  }

  // Update material
  static void updateMaterial(String id, MaterialModel updatedMaterial) {
    final index = _materials.indexWhere((m) => m.id == id);
    if (index != -1) {
      _materials[index] = updatedMaterial;
    }
  }

  // Delete material
  static void deleteMaterial(String id) {
    _materials.removeWhere((m) => m.id == id);
  }

  // Get material status
  static String getMaterialStatus(MaterialModel material) {
    // Check if expired
    try {
      final expiry = DateTime.parse(material.expiryDate);
      final now = DateTime.now();

      if (expiry.isBefore(now)) {
        return 'Expired';
      }

      final daysUntilExpiry = expiry.difference(now).inDays;
      if (daysUntilExpiry <= 30) {
        return 'Expiring Soon';
      }

      if (material.quantity < 100) {
        return 'Low Stock';
      }

      return 'Good';
    } catch (e) {
      return 'Unknown';
    }
  }

  // Get materials by category
  static List<MaterialModel> getMaterialsByCategory(String category) {
    return _materials.where((m) => m.category == category).toList();
  }

  // Get low stock materials
  static List<MaterialModel> getLowStockMaterials() {
    return _materials.where((m) => m.quantity < 100).toList();
  }

  // Get expired materials
  static List<MaterialModel> getExpiredMaterials() {
    return _materials.where((m) {
      try {
        final expiry = DateTime.parse(m.expiryDate);
        return expiry.isBefore(DateTime.now());
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Get expiring soon materials
  static List<MaterialModel> getExpiringSoonMaterials() {
    return _materials.where((m) {
      try {
        final expiry = DateTime.parse(m.expiryDate);
        final now = DateTime.now();
        final daysUntilExpiry = expiry.difference(now).inDays;
        return daysUntilExpiry > 0 && daysUntilExpiry <= 30;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Convert to old format for compatibility with InventoryView
  static List<Map<String, dynamic>> getMaterialsAsMap() {
    return _materials.map((m) => m.toJson()).toList();
  }
}