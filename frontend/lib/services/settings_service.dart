import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SettingsService {
  static const String _sessionTimeoutKey = 'session_timeout_minutes';
  static const String _autoCopyPasswordsKey = 'auto_copy_passwords';

  /// Gets the session timeout duration in minutes
  Future<int> getSessionTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_sessionTimeoutKey) ?? AppConstants.defaultSessionTimeout;
  }

  /// Sets the session timeout duration in minutes
  Future<void> setSessionTimeout(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionTimeoutKey, minutes);
  }

  /// Gets the auto-copy passwords setting
  Future<bool> getAutoCopyPasswords() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoCopyPasswordsKey) ?? false;
  }

  /// Sets the auto-copy passwords setting
  Future<void> setAutoCopyPasswords(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoCopyPasswordsKey, enabled);
  }

  /// Gets the default session timeout
  int getDefaultSessionTimeout() {
    return AppConstants.defaultSessionTimeout;
  }
}