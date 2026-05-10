import 'package:flutter/foundation.dart';
import 'package:graduation_project/Models/orderModel.dart';

class OrderService {
  static final List<OrderModel> _orders = [];
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void addOrder(OrderModel order) {
    _orders.insert(0, order);
    changes.value++;
  }

  static List<OrderModel> getAllOrders() => List.unmodifiable(_orders);

  static List<OrderModel> getPendingOrders() => _orders
      .where((order) => order.status == OrderStatus.pending)
      .toList(growable: false);

  static void updateOrderStatus(String id, OrderStatus status) {
    final index = _orders.indexWhere((order) => order.id == id);
    if (index == -1) return;
    _orders[index] = _orders[index].copyWith(status: status);
    changes.value++;
  }

  static void clearOrders() {
    _orders.clear();
    changes.value++;
  }
}
