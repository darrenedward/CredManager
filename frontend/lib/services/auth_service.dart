import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import 'jwt_service.dart';
import 'argon2_service.dart';

class AuthService {
  static const String _baseUrl = AppConstants.apiBaseUrl; // 'http://localhost:8080/api';
  final StorageService _storageService = StorageService();
  final Argon2Service _argon2Service = Argon2Service();
  
  // Rate limiting for recovery attempts
  static const int _maxRecoveryAttempts = 3;
  static const int _recoveryLockoutDuration = 300; // 5 minutes in seconds
  int _recoveryAttempts = 0;
  DateTime? _lastRecoveryAttempt;

  /// Generates a salt for hashing (legacy method for migration)
  String _generateSalt([int length = 32]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Hashes a passphrase with a salt using SHA-256 (legacy method for migration)
  String _hashPassphraseLegacy(String passphrase, String salt) {
    final bytes = utf8.encode(passphrase + salt);
    final digest = sha256.convert(bytes);
    return '${digest.toString()}\$salt:$salt';
  }

  /// Hashes a passphrase using Argon2 (military-grade security)
  Future<String> _hashPassphrase(String passphrase) async {
    return await _argon2Service.hashPassword(passphrase);
  }

  /// Verifies a passphrase against a stored hash (supports both Argon2 and legacy SHA-256)
  Future<bool> _verifyPassphrase(String passphrase, String storedHash) async {
    // Check if it's an Argon2 hash
    if (storedHash.startsWith('\$argon2id\$')) {
      return await _argon2Service.verifyPassword(passphrase, storedHash);
    }

    // Legacy SHA-256 hash format
    if (!storedHash.contains('\$salt:')) return false;

    final parts = storedHash.split('\$salt:');
    final salt = parts[1];

    // Hash the input passphrase with the extracted salt (legacy method)
    final hashedInput = _hashPassphraseLegacy(passphrase, salt);

    // Compare the hashes
    return hashedInput == storedHash;
  }

  /// Creates a new passphrase and security questions (offline mode)
  Future<String?> createPassphrase(String passphrase, List<Map<String, String>> securityQuestions) async {
    try {
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
          // Hash the answer using Argon2
          final answerHash = await _hashPassphrase(answer);
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
      
      // Generate a local JWT token for automatic login
      final payload = {
        'sub': 'local_user',
        'iss': 'api_key_manager',
        'aud': 'api_key_manager_client',
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      };
      
      final secret = 'local_secret_key';
      final token = JwtService.generateToken(payload, secret);
      print('Generated JWT token: $token');
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
      // Validate inputs
      if (passphrase.isEmpty) {
        throw Exception('Passphrase is required');
      }
      
      // Get stored passphrase hash
      final storedHash = await _storageService.getPassphraseHash();
      if (storedHash == null) {
        throw Exception('No account found. Please set up your account first.');
      }
      
      // Verify passphrase (supports both Argon2 and legacy SHA-256)
      if (!await _verifyPassphrase(passphrase, storedHash)) {
        throw Exception('Invalid passphrase');
      }
      
      // Mark as logged in
      await _storageService.setLoggedIn(true);
      
      // Generate a local JWT token
      final payload = {
        'sub': 'local_user',
        'iss': 'api_key_manager',
        'aud': 'api_key_manager_client',
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      };
      
      final secret = 'local_secret_key';
      final token = JwtService.generateToken(payload, secret);
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
        return false;
      }
      
      // Match answers to stored questions (case-insensitive)
      int correctAnswers = 0;
      for (var answer in answers) {
        final question = answer['question'];
        final answerText = answer['answer'];
        
        if (question != null && answerText != null) {
          // Find matching question in stored questions
          final matchingQuestion = storedQuestions.firstWhere(
            (q) => q['question'] == question,
            orElse: () => {'question': '', 'answerHash': ''},
          );
          
          if (matchingQuestion['question'] != '') {
            // Verify answer against stored hash (case-insensitive)
            if (await _verifyAnswerCaseInsensitive(answerText, matchingQuestion['answerHash']!)) {
              correctAnswers++;
            }
          }
        }
      }
      
      // All answers must be correct
      final isValid = correctAnswers == answers.length && answers.length == storedQuestions.length;
      
      if (isValid) {
        // Reset attempts on successful verification
        _recoveryAttempts = 0;
        _lastRecoveryAttempt = null;
      }
      
      return isValid;
    } catch (e) {
      return false;
    }
  }

  /// Verifies an answer against a stored hash (case-insensitive)
  Future<bool> _verifyAnswerCaseInsensitive(String answer, String storedHash) async {
    // Check if it's an Argon2 hash
    if (storedHash.startsWith('\$argon2id\$')) {
      return await _argon2Service.verifyPassword(answer.toLowerCase().trim(), storedHash);
    }

    // Legacy SHA-256 hash format
    if (!storedHash.contains('\$salt:')) return false;

    final parts = storedHash.split('\$salt:');
    final salt = parts[1];

    // Hash the input answer with the extracted salt (legacy method, lowercase for case-insensitive comparison)
    final hashedInput = _hashPassphraseLegacy(answer.toLowerCase().trim(), salt);

    // Compare the hashes
    return hashedInput == storedHash;
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
      
      final secret = 'recovery_secret_key';
      return JwtService.generateToken(payload, secret);
    } catch (e) {
      return null;
    }
  }

  /// Resets the passphrase using a recovery token (offline mode)
  Future<String?> resetPassphrase(String token, String newPassphrase) async {
    try {
      // In a real implementation, we would verify the token first
      // For now, we'll just update the stored passphrase
      
      // Store new passphrase hash locally using Argon2
      final hash = await _hashPassphrase(newPassphrase);
      await _storageService.storePassphraseHash(hash);
      
      // Generate a new JWT token for automatic login
      final payload = {
        'sub': 'local_user',
        'iss': 'api_key_manager',
        'aud': 'api_key_manager_client',
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      };
      
      final secret = 'local_secret_key';
      final newToken = JwtService.generateToken(payload, secret);
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
      
      // Verify the token signature
      final secret = 'local_secret_key';
      return JwtService.verifyToken(token, secret);
    } catch (e) {
      return false;
    }
  }
  
  /// Cleans up expired tokens
  Future<void> cleanupExpiredTokens() async {
    await _storageService.cleanupExpiredTokens();
  }
}