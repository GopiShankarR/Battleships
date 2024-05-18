import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _sessionKey = 'sessionToken';
  static const String _expiryKey = 'sessionExpiry';
  static const String _usernameKey = 'loggedInUsername';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionToken = prefs.getString(_sessionKey);
    final expiryTime = prefs.getInt(_expiryKey);
    return sessionToken != null && expiryTime != null && DateTime.now().millisecondsSinceEpoch < expiryTime;
  }

  static Future<String> getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return 'Bearer ${prefs.getString(_sessionKey) ?? ''}';
  }

  static Future<void> setSessionToken(String token, int expiryTime, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, token);
    await prefs.setInt(_expiryKey, expiryTime);
    await prefs.setString(_usernameKey, username);
  }

  static Future<String> getLoggedInUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey) ?? '';
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_expiryKey);
  }
}
