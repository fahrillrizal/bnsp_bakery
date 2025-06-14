import 'package:flutter/foundation.dart';
import 'package:bakery_app/models/product_models.dart';
import 'package:bakery_app/models/order_models.dart';
import 'package:bakery_app/services/database_helper.dart';
import 'package:bakery_app/services/storage_helper.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  List<OrderItem> _items = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = false;

  List<OrderItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get itemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  // Initialize cart from database
  Future<void> initializeCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _dbHelper.getCartItems();
      
      // Also save backup to SharedPreferences
      await _saveCartBackup();
      
    } catch (e) {
      print('Error initializing cart: $e');
      // Try to load from SharedPreferences backup
      await _loadCartBackup();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(Product product, {int quantity = 1, String? notes}) async {
    try {
      // Add to database
      await _dbHelper.insertCartItem(product.id, quantity, notes);
      
      // Update local state
      final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
      
      if (existingIndex >= 0) {
        _items[existingIndex] = OrderItem(
          product: product,
          quantity: _items[existingIndex].quantity + quantity,
          notes: notes ?? _items[existingIndex].notes,
        );
      } else {
        _items.add(OrderItem(
          product: product,
          quantity: quantity,
          notes: notes,
        ));
      }

      // Save backup
      await _saveCartBackup();
      
      notifyListeners();
      
    } catch (e) {
      print('Error adding item to cart: $e');
      // Fallback to local storage only
      _addItemLocally(product, quantity: quantity, notes: notes);
    }
  }

  void _addItemLocally(Product product, {int quantity = 1, String? notes}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex] = OrderItem(
        product: product,
        quantity: _items[existingIndex].quantity + quantity,
        notes: notes ?? _items[existingIndex].notes,
      );
    } else {
      _items.add(OrderItem(
        product: product,
        quantity: quantity,
        notes: notes,
      ));
    }
    
    _saveCartBackup();
    notifyListeners();
  }

  Future<void> removeItem(String productId) async {
    try {
      // Remove from database
      await _dbHelper.removeCartItem(productId);
      
      // Update local state
      _items.removeWhere((item) => item.product.id == productId);
      
      // Save backup
      await _saveCartBackup();
      
      notifyListeners();
      
    } catch (e) {
      print('Error removing item from cart: $e');
      // Fallback to local storage only
      _items.removeWhere((item) => item.product.id == productId);
      _saveCartBackup();
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    try {
      // Update in database
      await _dbHelper.updateCartItemQuantity(productId, quantity);
      
      // Update local state
      final index = _items.indexWhere((item) => item.product.id == productId);
      if (index >= 0) {
        if (quantity <= 0) {
          _items.removeAt(index);
        } else {
          _items[index] = OrderItem(
            product: _items[index].product,
            quantity: quantity,
            notes: _items[index].notes,
          );
        }
      }
      
      // Save backup
      await _saveCartBackup();
      
      notifyListeners();
      
    } catch (e) {
      print('Error updating cart item quantity: $e');
      // Fallback to local storage only
      _updateQuantityLocally(productId, quantity);
    }
  }

  void _updateQuantityLocally(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = OrderItem(
          product: _items[index].product,
          quantity: quantity,
          notes: _items[index].notes,
        );
      }
      _saveCartBackup();
      notifyListeners();
    }
  }

  Future<void> updateNotes(String productId, String notes) async {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index] = OrderItem(
        product: _items[index].product,
        quantity: _items[index].quantity,
        notes: notes,
      );
      
      // This is a local-only update for notes
      // You can extend database schema to support notes updates if needed
      await _saveCartBackup();
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    try {
      // Clear from database
      await _dbHelper.clearCart();
      
      // Clear local state
      _items.clear();
      
      // Clear backup
      await SharedPreferencesHelper.clearCartBackup();
      
      notifyListeners();
      
    } catch (e) {
      print('Error clearing cart: $e');
      // Fallback to local storage only
      _items.clear();
      SharedPreferencesHelper.clearCartBackup();
      notifyListeners();
    }
  }

  OrderItem? getItem(String productId) {
    try {
      return _items.firstWhere((item) => item.product.id == productId);
    } catch (e) {
      return null;
    }
  }

  bool containsProduct(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getProductQuantity(String productId) {
    final item = getItem(productId);
    return item?.quantity ?? 0;
  }

  // Backup and restore functionality
  Future<void> _saveCartBackup() async {
    try {
      final cartData = _items.map((item) => {
        'productId': item.product.id,
        'productName': item.product.name,
        'productDescription': item.product.description,
        'productPrice': item.product.price,
        'productImageUrl': item.product.imageUrl,
        'productCategory': item.product.category,
        'productIsAvailable': item.product.isAvailable,
        'productCreatedAt': item.product.createdAt.toIso8601String(),
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'notes': item.notes,
      }).toList();
      
      await SharedPreferencesHelper.saveCartBackup(cartData);
    } catch (e) {
      print('Error saving cart backup: $e');
    }
  }

  Future<void> _loadCartBackup() async {
    try {
      final cartData = await SharedPreferencesHelper.getCartBackup();
      
      _items = cartData.map((data) {
        final product = Product(
          id: data['productId'],
          name: data['productName'],
          description: data['productDescription'],
          price: data['productPrice'],
          imageUrl: data['productImageUrl'],
          category: data['productCategory'],
          isAvailable: data['productIsAvailable'] ?? true,
          createdAt: DateTime.parse(data['productCreatedAt']),
        );
        
        return OrderItem(
          product: product,
          quantity: data['quantity'],
          unitPrice: data['unitPrice'],
          notes: data['notes'],
        );
      }).toList();
      
    } catch (e) {
      print('Error loading cart backup: $e');
      _items = [];
    }
  }

  // Sync cart with database (useful for offline/online sync)
  Future<void> syncCart() async {
    try {
      // Clear database cart
      await _dbHelper.clearCart();
      
      // Re-add all items from local state
      for (var item in _items) {
        await _dbHelper.insertCartItem(
          item.product.id,
          item.quantity,
          item.notes,
        );
      }
      
      // Update backup
      await _saveCartBackup();
      
    } catch (e) {
      print('Error syncing cart: $e');
    }
  }

  // Get cart summary for order placement
  Map<String, dynamic> getCartSummary() {
    return {
      'totalItems': itemCount,
      'totalAmount': totalAmount,
      'items': _items.map((item) => {
        'productId': item.product.id,
        'productName': item.product.name,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'totalPrice': item.totalPrice,
        'notes': item.notes,
      }).toList(),
    };
  }

  // Validate cart before checkout
  bool validateCart() {
    if (_items.isEmpty) return false;
    
    // Check if all products are still available
    return _items.every((item) => item.product.isAvailable);
  }

  // Get cart items by category
  List<OrderItem> getItemsByCategory(String category) {
    return _items.where((item) => 
        item.product.category.toLowerCase() == category.toLowerCase()
    ).toList();
  }

  // Apply discount or coupon (can be extended)
  double calculateDiscountedTotal(double discountPercentage) {
    return totalAmount * (1 - discountPercentage / 100);
  }
}