import 'package:flutter/foundation.dart';
import 'package:bakery_app/models/product_models.dart';
import 'package:bakery_app/services/database_helper.dart';
import 'package:bakery_app/services/storage_helper.dart';

class ProductService extends ChangeNotifier {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  List<Product> _products = [];
  List<String> _favoriteProductIds = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = false;
  bool _isInitialized = false;

  List<Product> get products => List.unmodifiable(_products);
  List<String> get favoriteProductIds => List.unmodifiable(_favoriteProductIds);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Initialize products from database
  Future<void> initializeProducts() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Load products from database
      _products = await _dbHelper.getAllProducts();
      
      // Load favorite products from SharedPreferences
      _favoriteProductIds = await SharedPreferencesHelper.getFavoriteProducts();
      
      _isInitialized = true;
      
    } catch (e) {
      print('Error initializing products: $e');
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get all products
  Future<List<Product>> getAllProducts() async {
    if (!_isInitialized) {
      await initializeProducts();
    }
    return List.unmodifiable(_products);
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    if (!_isInitialized) {
      await initializeProducts();
    }

    if (category.toLowerCase() == 'semua') {
      return List.unmodifiable(_products);
    }

    try {
      // Get from database for real-time filtering
      final filteredProducts = await _dbHelper.getProductsByCategory(category);
      return filteredProducts;
    } catch (e) {
      print('Error getting products by category: $e');
      // Fallback to local filtering
      return _products.where((product) => 
          product.category.toLowerCase() == category.toLowerCase()).toList();
    }
  }

  // Get product by ID
  Future<Product?> getProductById(String id) async {
    if (!_isInitialized) {
      await initializeProducts();
    }

    try {
      // Try to get from database first
      final product = await _dbHelper.getProductById(id);
      return product;
    } catch (e) {
      print('Error getting product by ID: $e');
      // Fallback to local search
      try {
        return _products.firstWhere((product) => product.id == id);
      } catch (e) {
        return null;
      }
    }
  }

  // Get categories
  Future<List<String>> getCategories() async {
    if (!_isInitialized) {
      await initializeProducts();
    }

    final categories = _products.map((product) => product.category).toSet().toList();
    categories.insert(0, 'Semua');
    
    // Save last selected category
    final lastCategory = await SharedPreferencesHelper.getLastSelectedCategory();
    if (!categories.contains(lastCategory)) {
      await SharedPreferencesHelper.setLastSelectedCategory('Semua');
    }
    
    return categories;
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    if (!_isInitialized) {
      await initializeProducts();
    }

    if (query.isEmpty) return await getAllProducts();

    try {
      // Add to recent searches
      await SharedPreferencesHelper.addRecentSearch(query);
      
      // Search in database
      final searchResults = await _dbHelper.searchProducts(query);
      return searchResults;
    } catch (e) {
      print('Error searching products: $e');
      // Fallback to local search
      final lowercaseQuery = query.toLowerCase();
      return _products.where((product) =>
          product.name.toLowerCase().contains(lowercaseQuery) ||
          product.description.toLowerCase().contains(lowercaseQuery) ||
          product.category.toLowerCase().contains(lowercaseQuery)
      ).toList();
    }
  }

  // Add product (admin function)
  Future<bool> addProduct(Product product) async {
    try {
      await _dbHelper.insertProduct(product);
      _products.add(product);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding product: $e');
      return false;
    }
  }

  // Update product (admin function)
  Future<bool> updateProduct(Product product) async {
    try {
      await _dbHelper.updateProduct(product);
      
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        _products[index] = product;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  // Remove product (admin function)
  Future<bool> removeProduct(String productId) async {
    try {
      await _dbHelper.deleteProduct(productId);
      _products.removeWhere((product) => product.id == productId);
      
      // Also remove from favorites
      await removeFavoriteProduct(productId);
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error removing product: $e');
      return false;
    }
  }

  // Favorite products management
  Future<void> addFavoriteProduct(String productId) async {
    try {
      await SharedPreferencesHelper.addFavoriteProduct(productId);
      if (!_favoriteProductIds.contains(productId)) {
        _favoriteProductIds.add(productId);
        notifyListeners();
      }
    } catch (e) {
      print('Error adding favorite product: $e');
    }
  }

  Future<void> removeFavoriteProduct(String productId) async {
    try {
      await SharedPreferencesHelper.removeFavoriteProduct(productId);
      _favoriteProductIds.remove(productId);
      notifyListeners();
    } catch (e) {
      print('Error removing favorite product: $e');
    }
  }

  Future<bool> isFavoriteProduct(String productId) async {
    return await SharedPreferencesHelper.isFavoriteProduct(productId);
  }

  Future<List<Product>> getFavoriteProducts() async {
    if (!_isInitialized) {
      await initializeProducts();
    }

    return _products.where((product) => 
        _favoriteProductIds.contains(product.id)).toList();
  }

  // Get recent searches
  Future<List<String>> getRecentSearches() async {
    return await SharedPreferencesHelper.getRecentSearches();
  }

  Future<void> clearRecentSearches() async {
    await SharedPreferencesHelper.clearRecentSearches();
  }

  // Product sorting
  List<Product> sortProducts(List<Product> products, String sortBy) {
    List<Product> sortedProducts = List.from(products);
    
    switch (sortBy.toLowerCase()) {
      case 'name':
        sortedProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price_low':
        sortedProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        sortedProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'category':
        sortedProducts.sort((a, b) => a.category.compareTo(b.category));
        break;
      case 'newest':
        sortedProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        sortedProducts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      default:
        // Default sort by name
        sortedProducts.sort((a, b) => a.name.compareTo(b.name));
    }
    
    return sortedProducts;
  }

  // Save sort preference
  Future<void> setSortPreference(String sortBy) async {
    await SharedPreferencesHelper.setSortPreference(sortBy);
  }

  Future<String> getSortPreference() async {
    return await SharedPreferencesHelper.getSortPreference();
  }

  // Get products with filters
  Future<List<Product>> getFilteredProducts({
    String? category,
    double? minPrice,
    double? maxPrice,
    bool? isAvailable,
    String? sortBy,
  }) async {
    if (!_isInitialized) {
      await initializeProducts();
    }

    List<Product> filteredProducts = List.from(_products);

    // Filter by category
    if (category != null && category.toLowerCase() != 'semua') {
      filteredProducts = filteredProducts.where((product) => 
          product.category.toLowerCase() == category.toLowerCase()).toList();
    }

    // Filter by price range
    if (minPrice != null) {
      filteredProducts = filteredProducts.where((product) => 
          product.price >= minPrice).toList();
    }
    
    if (maxPrice != null) {
      filteredProducts = filteredProducts.where((product) => 
          product.price <= maxPrice).toList();
    }

    // Filter by availability
    if (isAvailable != null) {
      filteredProducts = filteredProducts.where((product) => 
          product.isAvailable == isAvailable).toList();
    }

    // Sort products
    if (sortBy != null) {
      filteredProducts = sortProducts(filteredProducts, sortBy);
    }

    return filteredProducts;
  }

  Future<List<Product>> getPopularProducts({int limit = 5}) async {
    if (!_isInitialized) {
      await initializeProducts();
    }

    List<Product> popularProducts = List<Product>.from(_products);
    popularProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return popularProducts.take(limit).cast<Product>().toList();
  }

  // Refresh products from database
  Future<void> refreshProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _dbHelper.getAllProducts();
      _favoriteProductIds = await SharedPreferencesHelper.getFavoriteProducts();
    } catch (e) {
      print('Error refreshing products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get product statistics
  Map<String, dynamic> getProductStatistics() {
    final categoryCount = <String, int>{};
    double totalValue = 0;
    int availableCount = 0;

    for (var product in _products) {
      // Count by category
      categoryCount[product.category] = (categoryCount[product.category] ?? 0) + 1;
      
      // Total value
      totalValue += product.price;
      
      // Available products count
      if (product.isAvailable) {
        availableCount++;
      }
    }

    return {
      'totalProducts': _products.length,
      'availableProducts': availableCount,
      'unavailableProducts': _products.length - availableCount,
      'totalValue': totalValue,
      'averagePrice': _products.isNotEmpty ? totalValue / _products.length : 0,
      'categoryCounts': categoryCount,
      'favoriteCount': _favoriteProductIds.length,
    };
  }
}