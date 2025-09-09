import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SettingsService {
  static const String _sessionTimeoutKey = 'session_timeout_minutes';
  
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
  
  /// Gets the default session timeout
  int getDefaultSessionTimeout() {
    return AppConstants.defaultSessionTimeout;
  }
}