import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPreferencesHelper {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // App Settings
  static Future<void> setFirstTime(bool isFirstTime) async {
    final prefs = await _instance;
    await prefs.setBool('isFirstTime', isFirstTime);
  }

  static Future<bool> isFirstTime() async {
    final prefs = await _instance;
    return prefs.getBool('isFirstTime') ?? true;
  }

  static Future<void> setThemeMode(String themeMode) async {
    final prefs = await _instance;
    await prefs.setString('themeMode', themeMode);
  }

  static Future<String> getThemeMode() async {
    final prefs = await _instance;
    return prefs.getString('themeMode') ?? 'system';
  }

  static Future<void> setLanguage(String languageCode) async {
    final prefs = await _instance;
    await prefs.setString('language', languageCode);
  }

  static Future<String> getLanguage() async {
    final prefs = await _instance;
    return prefs.getString('language') ?? 'id';
  }

  // User Settings
  static Future<void> setUserName(String name) async {
    final prefs = await _instance;
    await prefs.setString('userName', name);
  }

  static Future<String> getUserName() async {
    final prefs = await _instance;
    return prefs.getString('userName') ?? '';
  }

  static Future<void> setUserPhone(String phone) async {
    final prefs = await _instance;
    await prefs.setString('userPhone', phone);
  }

  static Future<String> getUserPhone() async {
    final prefs = await _instance;
    return prefs.getString('userPhone') ?? '';
  }

  static Future<void> setUserAddress(String address) async {
    final prefs = await _instance;
    await prefs.setString('userAddress', address);
  }

  static Future<String> getUserAddress() async {
    final prefs = await _instance;
    return prefs.getString('userAddress') ?? '';
  }

  static Future<void> setUserLocation(double latitude, double longitude) async {
    final prefs = await _instance;
    await prefs.setDouble('userLatitude', latitude);
    await prefs.setDouble('userLongitude', longitude);
  }

  static Future<Map<String, double>> getUserLocation() async {
    final prefs = await _instance;
    return {
      'latitude': prefs.getDouble('userLatitude') ?? 0.0,
      'longitude': prefs.getDouble('userLongitude') ?? 0.0,
    };
  }

  // Cart backup (JSON format)
  static Future<void> saveCartBackup(List<Map<String, dynamic>> cartItems) async {
    final prefs = await _instance;
    final jsonString = jsonEncode(cartItems);
    await prefs.setString('cartBackup', jsonString);
  }

  static Future<List<Map<String, dynamic>>> getCartBackup() async {
    final prefs = await _instance;
    final jsonString = prefs.getString('cartBackup') ?? '[]';
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.cast<Map<String, dynamic>>();
  }

  static Future<void> clearCartBackup() async {
    final prefs = await _instance;
    await prefs.remove('cartBackup');
  }

  // Recent searches
  static Future<void> addRecentSearch(String query) async {
    final prefs = await _instance;
    final recentSearches = await getRecentSearches();
    
    // Remove if already exists
    recentSearches.removeWhere((search) => search.toLowerCase() == query.toLowerCase());
    
    // Add to beginning
    recentSearches.insert(0, query);
    
    // Keep only last 10 searches
    if (recentSearches.length > 10) {
      recentSearches.removeRange(10, recentSearches.length);
    }
    
    await prefs.setStringList('recentSearches', recentSearches);
  }

  static Future<List<String>> getRecentSearches() async {
    final prefs = await _instance;
    return prefs.getStringList('recentSearches') ?? [];
  }

  static Future<void> clearRecentSearches() async {
    final prefs = await _instance;
    await prefs.remove('recentSearches');
  }

  // Favorite products
  static Future<void> addFavoriteProduct(String productId) async {
    final prefs = await _instance;
    final favorites = await getFavoriteProducts();
    
    if (!favorites.contains(productId)) {
      favorites.add(productId);
      await prefs.setStringList('favoriteProducts', favorites);
    }
  }

  static Future<void> removeFavoriteProduct(String productId) async {
    final prefs = await _instance;
    final favorites = await getFavoriteProducts();
    
    favorites.remove(productId);
    await prefs.setStringList('favoriteProducts', favorites);
  }

  static Future<List<String>> getFavoriteProducts() async {
    final prefs = await _instance;
    return prefs.getStringList('favoriteProducts') ?? [];
  }

  static Future<bool> isFavoriteProduct(String productId) async {
    final favorites = await getFavoriteProducts();
    return favorites.contains(productId);
  }

  // Order history backup (for offline access)
  static Future<void> saveRecentOrders(List<Map<String, dynamic>> orders) async {
    final prefs = await _instance;
    final jsonString = jsonEncode(orders);
    await prefs.setString('recentOrders', jsonString);
  }

  static Future<List<Map<String, dynamic>>> getRecentOrders() async {
    final prefs = await _instance;
    final jsonString = prefs.getString('recentOrders') ?? '[]';
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.cast<Map<String, dynamic>>();
  }

  // App statistics
  static Future<void> incrementAppOpenCount() async {
    final prefs = await _instance;
    final count = prefs.getInt('appOpenCount') ?? 0;
    await prefs.setInt('appOpenCount', count + 1);
  }

  static Future<int> getAppOpenCount() async {
    final prefs = await _instance;
    return prefs.getInt('appOpenCount') ?? 0;
  }

  static Future<void> setLastAppOpenDate() async {
    final prefs = await _instance;
    await prefs.setString('lastAppOpenDate', DateTime.now().toIso8601String());
  }

  static Future<DateTime?> getLastAppOpenDate() async {
    final prefs = await _instance;
    final dateString = prefs.getString('lastAppOpenDate');
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  // Notification settings
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await _instance;
    await prefs.setBool('notificationsEnabled', enabled);
  }

  static Future<bool> areNotificationsEnabled() async {
    final prefs = await _instance;
    return prefs.getBool('notificationsEnabled') ?? true;
  }

  static Future<void> setOrderNotificationsEnabled(bool enabled) async {
    final prefs = await _instance;
    await prefs.setBool('orderNotificationsEnabled', enabled);
  }

  static Future<bool> areOrderNotificationsEnabled() async {
    final prefs = await _instance;
    return prefs.getBool('orderNotificationsEnabled') ?? true;
  }

  static Future<void> setPromotionNotificationsEnabled(bool enabled) async {
    final prefs = await _instance;
    await prefs.setBool('promotionNotificationsEnabled', enabled);
  }

  static Future<bool> arePromotionNotificationsEnabled() async {
    final prefs = await _instance;
    return prefs.getBool('promotionNotificationsEnabled') ?? true;
  }

  // Cache settings
  static Future<void> setCacheExpiration(String key, DateTime expiration) async {
    final prefs = await _instance;
    await prefs.setString('cache_${key}_expiration', expiration.toIso8601String());
  }

  static Future<bool> isCacheExpired(String key) async {
    final prefs = await _instance;
    final expirationString = prefs.getString('cache_${key}_expiration');
    
    if (expirationString == null) return true;
    
    final expiration = DateTime.parse(expirationString);
    return DateTime.now().isAfter(expiration);
  }

  static Future<void> setCacheData(String key, String data) async {
    final prefs = await _instance;
    await prefs.setString('cache_$key', data);
  }

  static Future<String?> getCacheData(String key) async {
    final prefs = await _instance;
    return prefs.getString('cache_$key');
  }

  static Future<void> clearCache() async {
    final prefs = await _instance;
    final keys = prefs.getKeys();
    
    for (String key in keys) {
      if (key.startsWith('cache_')) {
        await prefs.remove(key);
      }
    }
  }

  // Filter preferences
  static Future<void> setLastSelectedCategory(String category) async {
    final prefs = await _instance;
    await prefs.setString('lastSelectedCategory', category);
  }

  static Future<String> getLastSelectedCategory() async {
    final prefs = await _instance;
    return prefs.getString('lastSelectedCategory') ?? 'Semua';
  }

  static Future<void> setSortPreference(String sortBy) async {
    final prefs = await _instance;
    await prefs.setString('sortPreference', sortBy);
  }

  static Future<String> getSortPreference() async {
    final prefs = await _instance;
    return prefs.getString('sortPreference') ?? 'name';
  }

  // App performance settings
  static Future<void> setImageCacheEnabled(bool enabled) async {
    final prefs = await _instance;
    await prefs.setBool('imageCacheEnabled', enabled);
  }

  static Future<bool> isImageCacheEnabled() async {
    final prefs = await _instance;
    return prefs.getBool('imageCacheEnabled') ?? true;
  }

  static Future<void> setAutoSyncEnabled(bool enabled) async {
    final prefs = await _instance;
    await prefs.setBool('autoSyncEnabled', enabled);
  }

  static Future<bool> isAutoSyncEnabled() async {
    final prefs = await _instance;
    return prefs.getBool('autoSyncEnabled') ?? true;
  }

  // Delivery preferences
  static Future<void> setDefaultDeliveryAddress(String address) async {
    final prefs = await _instance;
    await prefs.setString('defaultDeliveryAddress', address);
  }

  static Future<String> getDefaultDeliveryAddress() async {
    final prefs = await _instance;
    return prefs.getString('defaultDeliveryAddress') ?? '';
  }

  static Future<void> setDeliveryInstructions(String instructions) async {
    final prefs = await _instance;
    await prefs.setString('deliveryInstructions', instructions);
  }

  static Future<String> getDeliveryInstructions() async {
    final prefs = await _instance;
    return prefs.getString('deliveryInstructions') ?? '';
  }

  // Clear all data
  static Future<void> clearAllData() async {
    final prefs = await _instance;
    await prefs.clear();
  }

  // Backup and restore all preferences
  static Future<Map<String, dynamic>> exportPreferences() async {
    final prefs = await _instance;
    final keys = prefs.getKeys();
    Map<String, dynamic> data = {};
    
    for (String key in keys) {
      final value = prefs.get(key);
      data[key] = value;
    }
    
    return data;
  }

  static Future<void> importPreferences(Map<String, dynamic> data) async {
    final prefs = await _instance;
    
    for (String key in data.keys) {
      final value = data[key];
      
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      }
    }
  }
}