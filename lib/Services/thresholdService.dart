import 'package:shared_preferences/shared_preferences.dart';

class ThresholdService {
  static const _kLowStock = 'threshold_low_stock';
  static const _kExpiringSoonDays = 'threshold_expiring_soon_days';

  static Future<int> getLowStockThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kLowStock) ?? 100;
  }

  static Future<int> getExpiringSoonDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kExpiringSoonDays) ?? 30;
  }

  static Future<void> setLowStockThreshold(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLowStock, value);
  }

  static Future<void> setExpiringSoonDays(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kExpiringSoonDays, value);
  }
}
