import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'database_service.dart';
import 'encryption_service.dart';

class StorageService {
  // Legacy key for migration purposes only
  static const String _securityQuestionsKey = 'security_questions';
  
  final EncryptionService _encryptionService = EncryptionService();

  // Encrypted database storage methods for authentication data
  Future<void> storePassphraseHash(String hash) async {
    // Encrypt the passphrase hash before storing in database
    final encryptedHash = await _encryptionService.encryptData(hash);
    await DatabaseService.instance.storeEncryptedPassphraseHash(encryptedHash);
    print('Stored encrypted passphrase hash in database');
  }

  Future<String?> getPassphraseHash() async {
    final encryptedHash = await DatabaseService.instance.getEncryptedPassphraseHash();
    if (encryptedHash == null) return null;
    
    try {
      // Decrypt the passphrase hash from database
      return await _encryptionService.decryptData(encryptedHash);
    } catch (e) {
      print('Error decrypting passphrase hash: $e');
      return null;
    }
  }

  Future<void> deletePassphraseHash() async {
    await DatabaseService.instance.deleteEncryptedPassphraseHash();
    print('Deleted passphrase hash from database');
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

  // Encrypted database storage for JWT tokens
  Future<void> storeToken(String token) async {
    // Encrypt the JWT token before storing in database
    final encryptedToken = await _encryptionService.encryptData(token);
    await DatabaseService.instance.storeEncryptedToken(encryptedToken);
    print('Stored encrypted JWT token in database');
  }

  // Database storage for JWT secret key (comma-separated bytes, not encrypted for simplicity)
  Future<void> storeJwtSecret(List<int> secretKey) async {
    // Store the JWT secret key as comma-separated bytes (not encrypted for now)
    final encodedSecret = secretKey.join(',');
    await DatabaseService.instance.storeEncryptedJwtSecret(encodedSecret);
    print('Stored JWT secret key in database');
  }

  Future<List<int>?> getJwtSecret() async {
    final encodedSecret = await DatabaseService.instance.getEncryptedJwtSecret();
    if (encodedSecret == null) return null;

    try {
      // Decode the JWT secret key from database
      return encodedSecret.split(',').map(int.parse).toList();
    } catch (e) {
      print('Error decoding JWT secret key: $e');
      return null;
    }
  }

  Future<void> deleteJwtSecret() async {
    await DatabaseService.instance.deleteEncryptedJwtSecret();
    print('Deleted JWT secret key from database');
  }

  Future<String?> getToken() async {
    final encryptedToken = await DatabaseService.instance.getEncryptedToken();
    if (encryptedToken == null) return null;
    
    try {
      // Decrypt the JWT token from database
      return await _encryptionService.decryptData(encryptedToken);
    } catch (e) {
      print('Error decrypting JWT token: $e');
      return null;
    }
  }

  Future<void> deleteToken() async {
    await DatabaseService.instance.deleteEncryptedToken();
    print('Deleted JWT token from database');
  }

  // Encrypted database storage for application flags
  Future<void> setFirstTime(bool isFirstTime) async {
    await DatabaseService.instance.setFirstTimeFlag(isFirstTime);
  }

  Future<bool> isFirstTime() async {
    return await DatabaseService.instance.getFirstTimeFlag();
  }

  Future<void> setLoggedIn(bool isLoggedIn) async {
    await DatabaseService.instance.setLoggedInFlag(isLoggedIn);
  }

  Future<bool> isLoggedIn() async {
    return await DatabaseService.instance.getLoggedInFlag();
  }

  // Setup completion flag methods using encrypted database
  Future<void> setSetupCompleted(bool completed) async {
    await DatabaseService.instance.setSetupCompletedFlag(completed);
  }

  Future<bool> getSetupCompleted() async {
    return await DatabaseService.instance.getSetupCompletedFlag();
  }

  Future<void> clearAll() async {
    // Clear all authentication data from encrypted database
    await DatabaseService.instance.clearAllAuthData();
    
    // Also clear any remaining SharedPreferences data for migration compatibility
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('Cleared legacy SharedPreferences data');
    } catch (e) {
      print('Error clearing SharedPreferences: $e');
    }
    
    print('All authentication storage cleared');
  }

  // Reset setup for testing/debugging purposes
  Future<void> resetSetup() async {
    await DatabaseService.instance.setSetupCompletedFlag(false);
    await DatabaseService.instance.setFirstTimeFlag(true);
    await DatabaseService.instance.deleteEncryptedPassphraseHash();
    await DatabaseService.instance.deleteEncryptedToken();
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
      await DatabaseService.instance.setLoggedInFlag(false);
      print('Cleaned up expired token and set logged in flag to false');
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

  /// Sets biometric authentication enabled flag
  Future<void> setBiometricEnabled(bool enabled) async {
    await DatabaseService.instance.updateMetadata('biometric_enabled', enabled ? '1' : '0');
    print('Set biometric enabled flag to: $enabled');
  }

  /// Gets biometric authentication enabled flag
  Future<bool> getBiometricEnabled() async {
    final value = await DatabaseService.instance.getMetadata('biometric_enabled');
    return value == '1';
  }

  /// Sets migration completed flag
  Future<void> setMigrationCompleted(bool completed) async {
    await DatabaseService.instance.updateMetadata('migration_completed', completed ? '1' : '0');
    print('Set migration completed flag to: $completed');
  }

  /// Gets migration completed flag
  Future<bool> getMigrationCompleted() async {
    final value = await DatabaseService.instance.getMetadata('migration_completed');
    return value == '1';
  }
}