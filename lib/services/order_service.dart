import 'package:flutter/foundation.dart';
import 'package:bakery_app/models/order_models.dart';
import 'package:bakery_app/models/customer_models.dart';

class OrderService extends ChangeNotifier {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders);

  List<Order> get pendingOrders => _orders.where((order) => 
      order.status == OrderStatus.pending).toList();

  List<Order> get confirmedOrders => _orders.where((order) => 
      order.status == OrderStatus.confirmed || 
      order.status == OrderStatus.preparing).toList();

  List<Order> get completedOrders => _orders.where((order) => 
      order.status == OrderStatus.delivered).toList();

  void addOrder(Order order) {
    _orders.insert(0, order); // Add to beginning for recent orders first
    notifyListeners();
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(status: status);
      notifyListeners();
    }
  }

  void updateOrder(Order order) {
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index >= 0) {
      _orders[index] = order;
      notifyListeners();
    }
  }

  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  List<Order> getOrdersByCustomer(String customerId) {
    return _orders.where((order) => order.customer.id == customerId).toList();
  }

  List<Order> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  List<Order> getOrdersByDateRange(DateTime startDate, DateTime endDate) {
    return _orders.where((order) =>
        order.orderDate.isAfter(startDate) && 
        order.orderDate.isBefore(endDate)).toList();
  }

  double getTotalRevenue() {
    return _orders
        .where((order) => order.status == OrderStatus.delivered)
        .fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  double getTotalRevenueByDate(DateTime date) {
    return _orders
        .where((order) => 
            order.status == OrderStatus.delivered &&
            order.orderDate.year == date.year &&
            order.orderDate.month == date.month &&
            order.orderDate.day == date.day)
        .fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  int getTotalOrdersCount() {
    return _orders.length;
  }

  int getTotalOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).length;
  }

  void removeOrder(String orderId) {
    _orders.removeWhere((order) => order.id == orderId);
    notifyListeners();
  }

  void clearAllOrders() {
    _orders.clear();
    notifyListeners();
  }

  String generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'ORD-$timestamp';
  }
}