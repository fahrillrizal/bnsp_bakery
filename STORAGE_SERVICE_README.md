# StorageService Documentation

StorageService adalah layanan penyimpanan yang menggabungkan SQLite Database dan SharedPreferences untuk aplikasi Bakery. File ini menyediakan dua kelas utama:

1. **DatabaseService** - Untuk menyimpan data kompleks seperti users, orders, cart items
2. **StorageService** - Untuk menyimpan preferensi pengguna, session, dan data ringan

## Fitur StorageService

### 1. User Session Management
- `saveCurrentUser(Customer user)` - Simpan session user yang sedang login
- `getCurrentUser()` - Ambil data user yang sedang login
- `isLoggedIn()` - Cek status login
- `logout()` - Hapus session user
- `getLoginTime()` - Ambil waktu login

### 2. User Preferences
- `saveThemeMode(String theme)` / `getThemeMode()` - Mode tema aplikasi
- `saveLanguage(String lang)` / `getLanguage()` - Bahasa aplikasi
- `saveNotificationsEnabled(bool)` / `getNotificationsEnabled()` - Setting notifikasi
- `saveLocationEnabled(bool)` / `getLocationEnabled()` - Setting lokasi

### 3. Cart Management
- `saveCartItems(List<Map<String, dynamic>>)` - Simpan item cart
- `getCartItems()` - Ambil semua item cart
- `getCartCount()` - Ambil jumlah item di cart
- `clearCart()` - Kosongkan cart

### 4. Favorites Management
- `addToFavorites(String productId)` - Tambah ke favorites
- `removeFromFavorites(String productId)` - Hapus dari favorites
- `isFavorite(String productId)` - Cek apakah produk favorite
- `getFavorites()` - Ambil semua favorites

### 5. Search History
- `addSearchHistory(String query)` - Tambah riwayat pencarian
- `getSearchHistory()` - Ambil riwayat pencarian
- `clearSearchHistory()` - Hapus riwayat pencarian

### 6. App Settings
- `setFirstLaunch(bool)` / `isFirstLaunch()` - Status first launch
- `setOnboardingCompleted(bool)` / `isOnboardingCompleted()` - Status onboarding
- `setAppVersion(String)` / `getAppVersion()` - Versi aplikasi

### 7. Generic Operations
- `saveString(key, value)` / `getString(key)` - String operations
- `saveInt(key, value)` / `getInt(key)` - Integer operations
- `saveBool(key, value)` / `getBool(key)` - Boolean operations
- `saveDouble(key, value)` / `getDouble(key)` - Double operations
- `saveObject(key, object)` / `getObject(key)` - Object operations (JSON)
- `saveObjectList(key, list)` / `getObjectList(key)` - Object list operations
- `remove(key)` - Hapus key tertentu
- `clear()` - Hapus semua data
- `containsKey(key)` - Cek apakah key exists
- `getAllKeys()` - Ambil semua keys

## Cara Penggunaan

### Inisialisasi
```dart
import 'package:bakery_app/services/storage_service.dart';

// StorageService akan otomatis init saat pertama kali digunakan
// Atau bisa manual init:
await StorageService.init();
```

### Contoh Penggunaan Session
```dart
// Login user
Customer user = Customer(...);
bool success = await StorageService.saveCurrentUser(user);

// Cek status login
if (StorageService.isLoggedIn()) {
  Customer? currentUser = StorageService.getCurrentUser();
  print('Welcome ${currentUser?.name}');
}

// Logout
await StorageService.logout();
```

### Contoh Penggunaan Cart
```dart
// Simpan cart
List<Map<String, dynamic>> cartItems = [
  {
    'productId': 'prod1',
    'productName': 'Roti Bakar',
    'price': 15000.0,
    'quantity': 2
  }
];
await StorageService.saveCartItems(cartItems);

// Load cart
List<Map<String, dynamic>> items = StorageService.getCartItems();
int count = StorageService.getCartCount();
```

### Contoh Penggunaan Preferences
```dart
// Save preferences
await StorageService.saveThemeMode('dark');
await StorageService.saveLanguage('id');
await StorageService.saveNotificationsEnabled(true);

// Load preferences
String theme = StorageService.getThemeMode(); // default: 'system'
String lang = StorageService.getLanguage(); // default: 'id'
bool notifications = StorageService.getNotificationsEnabled(); // default: true
```

### Contoh Penggunaan Favorites
```dart
// Add to favorites
await StorageService.addToFavorites('product123');

// Check if favorite
bool isFav = StorageService.isFavorite('product123');

// Get all favorites
List<String> favorites = StorageService.getFavorites();

// Remove from favorites
await StorageService.removeFromFavorites('product123');
```

## Integrasi dengan Aplikasi Bakery

### Di main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage
  await StorageService.init();
  
  runApp(MyApp());
}
```

### Di AuthService
```dart
class AuthService {
  static Future<bool> login(String username, String password) async {
    // Authenticate user dengan DatabaseService
    Customer? user = await DatabaseService.getUserByUsernameOrEmail(username);
    
    if (user != null && user.password == password) {
      // Save session dengan StorageService
      await StorageService.saveCurrentUser(user);
      return true;
    }
    return false;
  }
  
  static Future<void> logout() async {
    await StorageService.logout();
  }
  
  static Customer? getCurrentUser() {
    return StorageService.getCurrentUser();
  }
  
  static bool isLoggedIn() {
    return StorageService.isLoggedIn();
  }
}
```

### Di CartService
```dart
class CartService {
  static Future<void> addToCart(Product product, int quantity) async {
    List<Map<String, dynamic>> cartItems = StorageService.getCartItems();
    
    // Add logic to handle cart items
    cartItems.add({
      'productId': product.id,
      'productName': product.name,
      'price': product.price,
      'quantity': quantity,
      'addedAt': DateTime.now().toIso8601String()
    });
    
    await StorageService.saveCartItems(cartItems);
  }
  
  static List<Map<String, dynamic>> getCartItems() {
    return StorageService.getCartItems();
  }
  
  static int getCartCount() {
    return StorageService.getCartCount();
  }
  
  static Future<void> clearCart() async {
    await StorageService.clearCart();
  }
}
```

## Database vs SharedPreferences

### Gunakan DatabaseService untuk:
- Data user (register, profile)
- Data order dan order items
- Data cart yang kompleks
- Data yang memerlukan query kompleks
- Data yang perlu relasi antar tabel

### Gunakan StorageService untuk:
- Session management
- User preferences (theme, language)
- Cart items sementara
- Favorites list
- Search history
- App settings
- Data yang sering diakses dan berukuran kecil

## Keamanan

- Password tidak disimpan di SharedPreferences
- Session otomatis expired saat logout
- Data sensitif tetap menggunakan Database
- SharedPreferences hanya untuk data non-sensitif

## Performance

- SharedPreferences lebih cepat untuk akses data sederhana
- Database lebih efisien untuk data kompleks dan besar
- Kombinasi keduanya memberikan performa optimal

## Error Handling

Semua method StorageService sudah include error handling dan akan return default value jika terjadi error:
- String: null
- int: null  
- bool: null atau default value yang sesuai
- Object: null
- List: empty list

Pastikan selalu cek null safety saat menggunakan nilai yang dikembalikan.
