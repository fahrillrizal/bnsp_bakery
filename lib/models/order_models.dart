import 'product_models.dart';
import 'customer_models.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivered,
  cancelled,
}

class OrderItem {
  final Product product;
  final int quantity;
  final double unitPrice;
  final String? notes;

  OrderItem({
    required this.product,
    required this.quantity,
    double? unitPrice,
    this.notes,
  }) : unitPrice = unitPrice ?? product.price;

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'unitPrice': unitPrice,
      'notes': notes,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
      unitPrice: json['unitPrice'].toDouble(),
      notes: json['notes'],
    );
  }
}

class Order {
  final String id;
  final Customer customer;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final OrderStatus status;
  final String? notes;
  final DateTime? estimatedDelivery;

  Order({
    required this.id,
    required this.customer,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    this.status = OrderStatus.pending,
    this.notes,
    this.estimatedDelivery,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Menunggu Konfirmasi';
      case OrderStatus.confirmed:
        return 'Dikonfirmasi';
      case OrderStatus.preparing:
        return 'Sedang Diproses';
      case OrderStatus.ready:
        return 'Siap Antar';
      case OrderStatus.delivered:
        return 'Terkirim';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer': customer.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'orderDate': orderDate.toIso8601String(),
      'status': status.toString(),
      'notes': notes,
      'estimatedDelivery': estimatedDelivery?.toIso8601String(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      customer: Customer.fromJson(json['customer']),
      items: (json['items'] as List).map((item) => OrderItem.fromJson(item)).toList(),
      totalAmount: json['totalAmount'].toDouble(),
      orderDate: DateTime.parse(json['orderDate']),
      status: OrderStatus.values.firstWhere((e) => e.toString() == json['status']),
      notes: json['notes'],
      estimatedDelivery: json['estimatedDelivery'] != null 
          ? DateTime.parse(json['estimatedDelivery'])
          : null,
    );
  }

  Order copyWith({
    String? id,
    Customer? customer,
    List<OrderItem>? items,
    double? totalAmount,
    DateTime? orderDate,
    OrderStatus? status,
    String? notes,
    DateTime? estimatedDelivery,
  }) {
    return Order(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
    );
  }
}