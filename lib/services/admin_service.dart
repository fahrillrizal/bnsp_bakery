import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  static const String _isLoggedInKey = 'admin_is_logged_in';
  static const String _loginTimeKey = 'admin_login_time';
  static const String _usernameKey = 'admin_username';
  
  // Session timeout dalam menit (default 2 jam)
  static const int SESSION_TIMEOUT_MINUTES = 120;
  
  // Kredensial admin (dalam aplikasi production, gunakan authentication yang lebih aman)
  static const String ADMIN_USERNAME = 'admin';
  static const String ADMIN_PASSWORD = 'admin123';
  
  static AdminService? _instance;
  static AdminService get instance => _instance ??= AdminService._();
  
  AdminService._();
  
  /// Login admin dengan username dan password
  Future<bool> login(String username, String password) async {
    if (username == ADMIN_USERNAME && password == ADMIN_PASSWORD) {
      final prefs = await SharedPreferences.getInstance();
      final loginTime = DateTime.now().millisecondsSinceEpoch;
      
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setInt(_loginTimeKey, loginTime);
      await prefs.setString(_usernameKey, username);
      
      return true;
    }
    return false;
  }
  
  /// Logout admin
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_loginTimeKey);
    await prefs.remove(_usernameKey);
  }
  
  /// Cek apakah admin sudah login dan session masih valid
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    
    if (!isLoggedIn) {
      return false;
    }
    
    // Cek apakah session sudah expired
    final loginTime = prefs.getInt(_loginTimeKey) ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final sessionDuration = currentTime - loginTime;
    final sessionDurationMinutes = sessionDuration / (1000 * 60);
    
    if (sessionDurationMinutes > SESSION_TIMEOUT_MINUTES) {
      // Session expired, logout otomatis
      await logout();
      return false;
    }
    
    return true;
  }
}