import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'database_service.dart';

class StorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _passphraseKey = 'secure_passphrase_hash';
  static const String _securityQuestionsKey = 'security_questions';
  static const String _tokenKey = 'jwt_token';
  static const String _isFirstTimeKey = 'is_first_time';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _setupCompletedKey = 'setup_completed';

  // Secure storage methods
  Future<void> storePassphraseHash(String hash) async {
    await _secureStorage.write(key: _passphraseKey, value: hash);
  }

  Future<String?> getPassphraseHash() async {
    return await _secureStorage.read(key: _passphraseKey);
  }

  Future<void> deletePassphraseHash() async {
    await _secureStorage.delete(key: _passphraseKey);
  }

  Future<void> storeSecurityQuestions(List<Map<String, String>> questions) async {
    print('Storing security questions in encrypted database: $questions');
    // Use encrypted database instead of SharedPreferences for security
    await DatabaseService.instance.storeSecurityQuestions(questions);

    // Also migrate any existing questions from SharedPreferences to database
    await _migrateSecurityQuestionsFromPrefs();
  }

  Future<List<Map<String, String>>?> getSecurityQuestions() async {
    // First try to get from encrypted database
    final dbQuestions = await DatabaseService.instance.getSecurityQuestions();
    if (dbQuestions != null && dbQuestions.isNotEmpty) {
      print('Retrieved ${dbQuestions.length} security questions from encrypted database');
      return dbQuestions;
    }

    // Fallback: check SharedPreferences for migration
    final prefs = await SharedPreferences.getInstance();
    final questionsJson = prefs.getString(_securityQuestionsKey);
    if (questionsJson != null) {
      print('Found security questions in SharedPreferences, migrating to database');
      final List<dynamic> decoded = jsonDecode(questionsJson) as List<dynamic>;
      final questions = decoded.map<Map<String, String>>((dynamic q) {
        final Map<String, dynamic> questionMap = q as Map<String, dynamic>;
        return {
          'question': questionMap['question'] as String,
          'answerHash': questionMap['answerHash'] as String,
          'isCustom': questionMap['isCustom'] as String? ?? 'false',
        };
      }).toList();

      // Migrate to database and remove from SharedPreferences
      await DatabaseService.instance.storeSecurityQuestions(questions);
      await prefs.remove(_securityQuestionsKey);
      print('Successfully migrated security questions to encrypted database');

      return questions;
    }

    return null;
  }

  Future<void> storeToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // Local storage for flags
  Future<void> setFirstTime(bool isFirstTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstTimeKey, isFirstTime);
  }

  Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstTimeKey) ?? true;
  }

  Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Setup completion flag methods
  Future<void> setSetupCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupCompletedKey, completed);
    print('Setup completion flag set to: $completed');
  }

  Future<bool> getSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_setupCompletedKey) ?? false;
    print('Setup completion flag retrieved: $completed');
    return completed;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _secureStorage.deleteAll();
    print('All storage cleared including setup completion flag');
  }

  // Reset setup for testing/debugging purposes
  Future<void> resetSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupCompletedKey, false);
    await prefs.setBool(_isFirstTimeKey, true);
    await _secureStorage.delete(key: _passphraseKey);
    await _secureStorage.delete(key: _tokenKey);
    print('Setup reset - app will show setup screen on next launch');
  }
  
  /// Checks if a stored token is expired
  Future<bool> isTokenExpired() async {
    final token = await getToken();
    if (token == null) return true;
    
    try {
      final payload = Jwt.parseJwt(token);
      if (payload['exp'] != null) {
        final expiration = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
        return DateTime.now().isAfter(expiration);
      }
      return false;
    } catch (e) {
      return true;
    }
  }
  
  /// Cleans up expired tokens
  Future<void> cleanupExpiredTokens() async {
    final isExpired = await isTokenExpired();
    if (isExpired) {
      await deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);
    }
  }

  /// Migrates security questions from SharedPreferences to encrypted database
  Future<void> _migrateSecurityQuestionsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final questionsJson = prefs.getString(_securityQuestionsKey);

      if (questionsJson != null) {
        print('Migrating existing security questions from SharedPreferences to database');
        final List<dynamic> decoded = jsonDecode(questionsJson) as List<dynamic>;
        final questions = decoded.map<Map<String, String>>((dynamic q) {
          final Map<String, dynamic> questionMap = q as Map<String, dynamic>;
          return {
            'question': questionMap['question'] as String,
            'answerHash': questionMap['answerHash'] as String,
            'isCustom': questionMap['isCustom'] as String? ?? 'false',
          };
        }).toList();

        // Store in database and remove from SharedPreferences
        await DatabaseService.instance.storeSecurityQuestions(questions);
        await prefs.remove(_securityQuestionsKey);
        print('Successfully migrated ${questions.length} security questions to encrypted database');
      }
    } catch (e) {
      print('Error during security questions migration: $e');
      // Don't throw - migration failure shouldn't break the app
    }
  }
}