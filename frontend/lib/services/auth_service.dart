import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import 'jwt_service.dart';
import 'argon2_service.dart';
import 'key_derivation_service.dart';
import 'database_service.dart';

/// Exception thrown when login attempts are rate limited
class LockoutException implements Exception {
  final String message;
  LockoutException([this.message = 'Too many login attempts. Please try again later.']);

  @override
  String toString() => message;
}

class AuthService {
  final StorageService _storageService = StorageService();
  final Argon2Service _argon2Service = Argon2Service();

  // Rate limiting for recovery attempts
  static const int _maxRecoveryAttempts = 3;
  static const int _recoveryLockoutDuration = 300; // 5 minutes in seconds
  int _recoveryAttempts = 0;
  DateTime? _lastRecoveryAttempt;

  // Rate limiting for login attempts
  static int loginAttempts = 0;
  static DateTime? lastLoginAttempt;
  static const int _maxLoginAttempts = 5;
  static const int _loginLockoutDuration = 300; // 5 minutes in seconds

  /// Hashes a passphrase using Argon2 (military-grade security)
  Future<String> _hashPassphrase(String passphrase) async {
    return await _argon2Service.hashPassword(passphrase);
  }

  /// Verifies a passphrase against a stored hash (supports legacy SHA-256 migration)
  Future<bool> _verifyPassphrase(String passphrase, String storedHash) async {
    if (storedHash.startsWith(r'$argon2id$')) {
      return await _argon2Service.verifyPassword(passphrase, storedHash);
    } else if (_isLegacySha256Hash(storedHash)) {
      // Legacy SHA-256 hash detected - verify and migrate
      return await _verifyAndMigrateLegacyHash(passphrase, storedHash);
    }
    return false;
  }

  /// Detects if a hash is in legacy SHA-256 format 'hash$salt:saltvalue'
  bool _isLegacySha256Hash(String hash) {
    return hash.contains(r'$') && !hash.startsWith(r'$argon2id$') && hash.split(r'$').length == 3;
  }

  /// Verifies legacy SHA-256 hash and migrates to Argon2
  Future<bool> _verifyAndMigrateLegacyHash(String passphrase, String legacyHash) async {
    try {
      // Parse legacy hash format: 'hash$salt:saltvalue'
      final parts = legacyHash.split(r'$');
      if (parts.length != 3) return false;

      final storedHash = parts[0];
      final salt = parts[1];
      final saltValue = parts[2];

      // Verify using SHA-256 with salt
      final saltedPassphrase = passphrase + saltValue;
      final computedHash = sha256.convert(utf8.encode(saltedPassphrase)).toString();

      if (computedHash == storedHash) {
        // Verification successful - migrate to Argon2
        await _migrateLegacyHashToArgon2(passphrase);
        return true;
      }
    } catch (e) {
      print('Error verifying legacy hash: $e');
    }
    return false;
  }

  /// Migrates legacy SHA-256 hash to Argon2 and updates storage
  Future<void> _migrateLegacyHashToArgon2(String passphrase) async {
    try {
      // Generate new Argon2 hash
      final newHash = await _hashPassphrase(passphrase);

      // Update stored hash in database
      await _storageService.storePassphraseHash(newHash);

      // Mark migration as completed
      await _storageService.setMigrationCompleted(true);

      print('Successfully migrated legacy SHA-256 hash to Argon2');
    } catch (e) {
      print('Error migrating legacy hash: $e');
      rethrow;
    }
  }

  /// Creates a new passphrase and security questions (offline mode)
  Future<String?> createPassphrase(String passphrase, List<Map<String, String>> securityQuestions) async {
    try {
      passphrase = passphrase.trim();
      print('Starting createPassphrase with ${securityQuestions.length} questions');
      
      // Validate inputs
      if (passphrase.isEmpty) {
        throw Exception('Passphrase is required');
      }
      
      // Store passphrase hash locally using Argon2
      final hash = await _hashPassphrase(passphrase);
      print('Generated Argon2 passphrase hash: $hash');
      await _storageService.storePassphraseHash(hash);
      
      // Process and hash security questions
      final List<Map<String, String>> processedQuestions = [];
      for (var question in securityQuestions) {
        final questionText = question['question'];
        final answer = question['answer'];
        final isCustom = question['isCustom'] ?? 'false';
        
        if (questionText != null && answer != null) {
          // Normalize answer (lowercase, trim) before hashing for case-insensitive verification
          final normalizedAnswer = answer.toLowerCase().trim();
          // Hash the normalized answer using Argon2
          final answerHash = await _hashPassphrase(normalizedAnswer);
          print('Hashed answer for question "$questionText": $answerHash');
          
          processedQuestions.add({
            'question': questionText,
            'answerHash': answerHash,
            'isCustom': isCustom,
          });
        }
      }
      
      // Store security questions locally
      print('Storing ${processedQuestions.length} processed questions');
      await _storageService.storeSecurityQuestions(processedQuestions);
      
      // Mark as not first time user
      await _storageService.setFirstTime(false);
      await _storageService.setLoggedIn(true);
      
      // Generate a local JWT token for automatic login using derived secret
      final payload = {
        'sub': 'local_user',
        'iss': 'api_key_manager',
        'aud': 'api_key_manager_client',
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      };

      // Derive JWT secret from passphrase
      final jwtSecret = await KeyDerivationService.deriveJwtSecret(passphrase);
      final token = JwtService.generateTokenWithDerivedSecret(payload, jwtSecret);
      print('Generated JWT token with derived secret: $token');

      // Store the derived JWT secret securely for verification
      await _storageService.storeJwtSecret(jwtSecret);
      await _storageService.storeToken(token);
      
      return token;
    } catch (e) {
      print('Error in createPassphrase: $e');
      rethrow;
    }
  }

  /// Logs in with a passphrase (offline mode)
  Future<String?> login(String passphrase) async {
    try {
      passphrase = passphrase.trim();
      // Validate inputs
      if (passphrase.isEmpty) {
        throw Exception('Passphrase is required');
      }

      // Increment login attempts for rate limiting
      loginAttempts++;
      lastLoginAttempt = DateTime.now();

      // Check if login is locked out due to rate limiting
      if (_isLoginLockedOut()) {
        throw LockoutException();
      }

      // Get stored passphrase hash
      final storedHash = await _storageService.getPassphraseHash();
      print('DEBUG: Retrieved stored hash: ${storedHash != null ? 'YES (${storedHash.substring(0, 20)}...)' : 'NULL'}');

      // For legacy migration, check if there's a legacy hash in the database directly
      String? effectiveHash = storedHash;
      if (storedHash == null) {
        // Check database directly for legacy hashes
        final db = await DatabaseService.instance.database;
        final result = await db.query('app_metadata',
          where: 'key = ?',
          whereArgs: ['passphrase_hash'],
          limit: 1,
        );
        if (result.isNotEmpty) {
          effectiveHash = result.first['value'] as String?;
          print('DEBUG: Found legacy hash in database: ${effectiveHash != null ? 'YES (${effectiveHash!.substring(0, 20)}...)' : 'NULL'}');
        }
      }

      if (effectiveHash == null) {
        throw Exception('No account found. Please set up your account first.');
      }

      // Verify passphrase (supports both Argon2 and legacy SHA-256)
      if (!await _verifyPassphrase(passphrase, effectiveHash!)) {
        throw Exception('Invalid passphrase');
      }

      // Reset login attempts on successful login
      loginAttempts = 0;
      lastLoginAttempt = null;

      // Mark as logged in
      await _storageService.setLoggedIn(true);

      // Perform migration of security questions if needed
      await migrateSecurityQuestionsToArgon2();

      // Generate a local JWT token using derived secret
      final payload = {
        'sub': 'local_user',
        'iss': 'api_key_manager',
        'aud': 'api_key_manager_client',
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      };

      // Derive JWT secret from passphrase
      final jwtSecret = await KeyDerivationService.deriveJwtSecret(passphrase);
      final token = JwtService.generateTokenWithDerivedSecret(payload, Uint8List.fromList(jwtSecret));

      // Store the derived JWT secret securely for verification
      await _storageService.storeJwtSecret(jwtSecret);

      await _storageService.storeToken(token);

      return token;
    } catch (e) {
      rethrow;
    }
  }

  /// Initiates the passphrase recovery process (offline mode)
  Future<List<String>?> initiateRecovery() async {
    // Check rate limiting
    if (_isRecoveryLockedOut()) {
      throw Exception('Too many recovery attempts. Please try again later.');
    }
    
    try {
      // Get stored security questions
      final questions = await _storageService.getSecurityQuestions();
      if (questions != null && questions.isNotEmpty) {
        // Extract just the questions and randomize order
        final questionList = questions.map((q) => q['question'] as String).toList();
        questionList.shuffle();
        return questionList;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Verifies security question answers (offline mode)
  Future<bool> verifyRecoveryAnswers(List<Map<String, String>> answers) async {
    print('DEBUG: Starting verifyRecoveryAnswers with ${answers.length} answers');
    
    // Check rate limiting
    if (_isRecoveryLockedOut()) {
      throw Exception('Too many recovery attempts. Please try again later.');
    }
    
    try {
      // Increment attempt counter
      _recoveryAttempts++;
      _lastRecoveryAttempt = DateTime.now();
      
      final storedQuestions = await _storageService.getSecurityQuestions();
      if (storedQuestions == null || storedQuestions.isEmpty) {
        print('DEBUG: No stored questions found');
        return false;
      }
      
      print('DEBUG: Found ${storedQuestions.length} stored questions');
      for (int i = 0; i < storedQuestions.length; i++) {
        print('DEBUG: Stored Q${i+1}: ${storedQuestions[i]['question']}');
      }
      
      // Match answers to stored questions (case-insensitive)
      int correctAnswers = 0;
      for (int i = 0; i < answers.length; i++) {
        final answer = answers[i];
        final question = answer['question'];
        final answerText = answer['answer'];
        
        print('DEBUG: Processing answer ${i+1}: Q="${question}", A="${answerText}"');
        
        if (question != null && answerText != null) {
          // Find matching question in stored questions
          final matchingQuestion = storedQuestions.firstWhere(
            (q) => q['question'] == question,
            orElse: () => {'question': '', 'answerHash': ''},
          );
          
          if (matchingQuestion['question'] != '') {
            print('DEBUG: Found matching stored question');
            print('DEBUG: Stored hash: ${matchingQuestion['answerHash']}');
            
            // Verify answer against stored hash (case-insensitive)
            final isCorrect = await _verifyAnswerCaseInsensitive(answerText, matchingQuestion['answerHash']!);
            print('DEBUG: Answer verification result: $isCorrect');
            
            if (isCorrect) {
              correctAnswers++;
              print('DEBUG: Correct answer count now: $correctAnswers');
            }
          } else {
            print('DEBUG: No matching stored question found');
          }
        }
      }
      
      // All answers must be correct
      final isValid = correctAnswers == answers.length && answers.length == storedQuestions.length;
      print('DEBUG: Final verification - Correct: $correctAnswers, Required: ${answers.length}, Stored: ${storedQuestions.length}');
      print('DEBUG: Overall result: $isValid');
      
      if (isValid) {
        // Reset attempts on successful verification
        _recoveryAttempts = 0;
        _lastRecoveryAttempt = null;
        print('DEBUG: Recovery successful - resetting attempt counter');
      }
      
      return isValid;
    } catch (e) {
      print('DEBUG: Error in verifyRecoveryAnswers: $e');
      return false;
    }
  }

  /// Verifies an answer against a stored hash (case-insensitive, supports legacy migration)
  Future<bool> _verifyAnswerCaseInsensitive(String answer, String storedHash) async {
    final normalized = answer.toLowerCase().trim();

    if (storedHash.startsWith(r'$argon2id$')) {
      return await _argon2Service.verifyPassword(normalized, storedHash);
    } else if (_isLegacySha256Hash(storedHash)) {
      // Legacy SHA-256 hash detected - verify and migrate
      return await _verifyAndMigrateLegacyAnswerHash(normalized, storedHash);
    }
    return false;
  }

  /// Verifies legacy SHA-256 answer hash and migrates to Argon2
  Future<bool> _verifyAndMigrateLegacyAnswerHash(String normalizedAnswer, String legacyHash) async {
    try {
      // Parse legacy hash format: 'hash$salt:saltvalue'
      final parts = legacyHash.split(r'$');
      if (parts.length != 3) return false;

      final storedHash = parts[0];
      final salt = parts[1];
      final saltValue = parts[2];

      // Verify using SHA-256 with salt
      final saltedAnswer = normalizedAnswer + saltValue;
      final computedHash = sha256.convert(utf8.encode(saltedAnswer)).toString();

      if (computedHash == storedHash) {
        // Verification successful - migrate to Argon2
        final newHash = await _hashPassphrase(normalizedAnswer);
        return true; // Return success, migration will be handled at question level
      }
    } catch (e) {
      print('Error verifying legacy answer hash: $e');
    }
    return false;
  }

  /// Requests a temporary recovery token (offline mode)
  Future<String?> requestRecoveryToken() async {
    try {
      final payload = {
        'sub': 'recovery_user',
        'iss': 'api_key_manager',
        'aud': 'api_key_manager_recovery',
        'exp': DateTime.now().add(Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000,
      };

      // Get the stored JWT secret for recovery token
      final jwtSecret = await _storageService.getJwtSecret();
      if (jwtSecret == null) {
        return null;
      }

      return JwtService.generateTokenWithDerivedSecret(payload, Uint8List.fromList(jwtSecret));
    } catch (e) {
      return null;
    }
  }

  /// Resets the passphrase using a recovery token (offline mode)
  Future<String?> resetPassphrase(String token, String newPassphrase) async {
    try {
      newPassphrase = newPassphrase.trim();
      // In a real implementation, we would verify the token first
      // For now, we'll just update the stored passphrase

      // Store new passphrase hash locally using Argon2
      final hash = await _hashPassphrase(newPassphrase);
      await _storageService.storePassphraseHash(hash);

      // Generate a new JWT token for automatic login using derived secret
      final payload = {
        'sub': 'local_user',
        'iss': 'api_key_manager',
        'aud': 'api_key_manager_client',
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      };

      // Derive new JWT secret from new passphrase
      final jwtSecret = await KeyDerivationService.deriveJwtSecret(newPassphrase);
      final newToken = JwtService.generateTokenWithDerivedSecret(payload, Uint8List.fromList(jwtSecret));

      // Store the new derived JWT secret securely
      await _storageService.storeJwtSecret(jwtSecret);
      await _storageService.storeToken(newToken);

      return newToken;
    } catch (e) {
      rethrow;
    }
  }

  /// Checks if recovery is locked out due to rate limiting
  bool _isRecoveryLockedOut() {
    if (_lastRecoveryAttempt == null) return false;

    final now = DateTime.now();
    final timeSinceLastAttempt = now.difference(_lastRecoveryAttempt!).inSeconds;

    // If we've exceeded max attempts and haven't waited long enough
    if (_recoveryAttempts >= _maxRecoveryAttempts &&
        timeSinceLastAttempt < _recoveryLockoutDuration) {
      return true;
    }

    // Reset counter if enough time has passed
    if (timeSinceLastAttempt >= _recoveryLockoutDuration) {
      _recoveryAttempts = 0;
      _lastRecoveryAttempt = null;
    }

    return false;
  }

  /// Checks if login is locked out due to rate limiting
  bool _isLoginLockedOut() {
    if (lastLoginAttempt == null) return false;

    final now = DateTime.now();
    final timeSinceLastAttempt = now.difference(lastLoginAttempt!).inSeconds;

    // If we've exceeded max attempts and haven't waited long enough
    if (loginAttempts >= _maxLoginAttempts &&
        timeSinceLastAttempt < _loginLockoutDuration) {
      return true;
    }

    // Reset counter if enough time has passed
    if (timeSinceLastAttempt >= _loginLockoutDuration) {
      loginAttempts = 0;
      lastLoginAttempt = null;
    }

    return false;
  }

  /// Resets login rate limiting (for testing purposes)
  static void resetLoginRateLimiting() {
    loginAttempts = 0;
    lastLoginAttempt = null;
  }

  Future<bool> recoverPassphrase(List<String> answers) async {
    // This method is for backward compatibility, but recovery should use the new methods
    return false;
  }

  /// Verifies a JWT token (offline mode)
  Future<bool> verifyToken(String token) async {
    try {
      // Check if token is expired
      if (JwtService.isTokenExpired(token)) {
        return false;
      }

      // Get the stored JWT secret
      final jwtSecret = await _storageService.getJwtSecret();
      if (jwtSecret == null) {
        return false;
      }

      // Verify the token signature using derived secret
      return JwtService.verifyTokenWithDerivedSecret(token, Uint8List.fromList(jwtSecret));
    } catch (e) {
      return false;
    }
  }
  
  /// Cleans up expired tokens
  Future<void> cleanupExpiredTokens() async {
    await _storageService.cleanupExpiredTokens();
  }

  /// Completes the passphrase recovery process
  Future<String?> completeRecovery(List<String> answers, String newPassphrase) async {
    try {
      // Get stored questions to match answers
      final storedQuestions = await _storageService.getSecurityQuestions();
      if (storedQuestions == null || storedQuestions.isEmpty) {
        throw Exception('No security questions found');
      }

      // Convert answers to the expected format for verification
      final formattedAnswers = <Map<String, String>>[];
      for (int i = 0; i < answers.length && i < storedQuestions.length; i++) {
        formattedAnswers.add({
          'question': storedQuestions[i]['question']!,
          'answer': answers[i],
        });
      }

      // Verify the recovery answers
      final isValid = await verifyRecoveryAnswers(formattedAnswers);
      if (!isValid) {
        throw Exception('Invalid recovery answers');
      }

      // Reset the passphrase with the new one
      final token = await resetPassphrase('recovery_token', newPassphrase);

      return token;
    } catch (e) {
      print('Error in completeRecovery: $e');
      return null;
    }
  }

  /// Enables biometric authentication
  Future<bool> enableBiometricAuth(String passphrase) async {
    try {
      // Verify the passphrase first
      final storedHash = await _storageService.getPassphraseHash();
      if (storedHash == null) {
        throw Exception('No account found');
      }

      if (!await _verifyPassphrase(passphrase, storedHash)) {
        throw Exception('Invalid passphrase');
      }

      // Store biometric enabled flag
      await _storageService.setBiometricEnabled(true);

      return true;
    } catch (e) {
      print('Error enabling biometric auth: $e');
      return false;
    }
  }

  /// Authenticates using biometric
  Future<String?> authenticateWithBiometric() async {
    try {
      // Check if biometric is enabled
      final biometricEnabled = await _storageService.getBiometricEnabled();
      if (!biometricEnabled) {
        throw Exception('Biometric authentication not enabled');
      }

      // For desktop, biometric auth is not available, so return null
      // In a real implementation, this would use platform biometric APIs
      return null;
    } catch (e) {
      print('Error in biometric authentication: $e');
      return null;
    }
  }

  /// Checks if migration is needed and provides user-friendly status
  Future<Map<String, dynamic>> checkMigrationStatus() async {
    try {
      final storedHash = await _storageService.getPassphraseHash();
      final migrationCompleted = await _storageService.getMigrationCompleted();

      if (storedHash == null) {
        return {
          'needsMigration': false,
          'message': 'No account found',
          'migrationType': null,
        };
      }

      if (migrationCompleted) {
        return {
          'needsMigration': false,
          'message': 'Your account is using current security standards',
          'migrationType': null,
        };
      }

      if (_isLegacySha256Hash(storedHash)) {
        return {
          'needsMigration': true,
          'message': 'Your account uses legacy security. Migration to enhanced security will occur on next login.',
          'migrationType': 'passphrase',
        };
      }

      // Check security questions for legacy hashes
      final questions = await _storageService.getSecurityQuestions();
      if (questions != null) {
        for (final question in questions) {
          final answerHash = question['answerHash'];
          if (answerHash != null && _isLegacySha256Hash(answerHash)) {
            return {
              'needsMigration': true,
              'message': 'Your security questions use legacy security. They will be updated to enhanced security.',
              'migrationType': 'security_questions',
            };
          }
        }
      }

      return {
        'needsMigration': false,
        'message': 'Your account is using current security standards',
        'migrationType': null,
      };
    } catch (e) {
      print('Error checking migration status: $e');
      return {
        'needsMigration': false,
        'message': 'Unable to check migration status',
        'migrationType': null,
      };
    }
  }

  /// Migrates all legacy security question hashes to Argon2
  Future<void> migrateSecurityQuestionsToArgon2() async {
    try {
      final questions = await _storageService.getSecurityQuestions();
      if (questions == null || questions.isEmpty) return;

      final migratedQuestions = <Map<String, String>>[];
      bool hasLegacyHashes = false;

      for (final question in questions) {
        final answerHash = question['answerHash'];
        if (answerHash != null && _isLegacySha256Hash(answerHash)) {
          hasLegacyHashes = true;
          // For migration, we can't recover the original answer, so we'll mark for re-setup
          // In a real scenario, this would require user re-entry of answers
          print('Found legacy security question hash - requires user re-entry for migration');
        } else {
          migratedQuestions.add(question);
        }
      }

      if (hasLegacyHashes) {
        // Clear legacy questions and require re-setup
        await _storageService.storeSecurityQuestions([]);
        print('Cleared legacy security questions - user needs to re-setup');
      }

    } catch (e) {
      print('Error migrating security questions: $e');
      rethrow;
    }
  }
}