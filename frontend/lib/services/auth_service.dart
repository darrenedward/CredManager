import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import 'jwt_service.dart';

class AuthService {
  static const String _baseUrl = AppConstants.apiBaseUrl; // 'http://localhost:8080/api';
  final StorageService _storageService = StorageService();
  
  // Rate limiting for recovery attempts
  static const int _maxRecoveryAttempts = 3;
  static const int _recoveryLockoutDuration = 300; // 5 minutes in seconds
  int _recoveryAttempts = 0;
  DateTime? _lastRecoveryAttempt;

  /// Generates a salt for hashing
  String _generateSalt([int length = 32]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Hashes a passphrase with a salt using SHA-256
  String _hashPassphrase(String passphrase, String salt) {
    final bytes = utf8.encode(passphrase + salt);
    final digest = sha256.convert(bytes);
    return '${digest.toString()}\$salt:$salt';
  }

  /// Verifies a passphrase against a stored hash
  bool _verifyPassphrase(String passphrase, String storedHash) {
    // Extract salt from stored hash
    if (!storedHash.contains('\$salt:')) return false;
    
    final parts = storedHash.split('\$salt:');
    final hashPart = parts[0];
    final salt = parts[1];
    
    // Hash the input passphrase with the extracted salt
    final hashedInput = _hashPassphrase(passphrase, salt);
    
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
      
      // Store passphrase hash locally
      final salt = _generateSalt();
      final hash = _hashPassphrase(passphrase, salt);
      print('Generated passphrase hash: $hash');
      await _storageService.storePassphraseHash(hash);
      
      // Process and hash security questions
      final List<Map<String, String>> processedQuestions = [];
      for (var question in securityQuestions) {
        final questionText = question['question'];
        final answer = question['answer'];
        final isCustom = question['isCustom'] ?? 'false';
        
        if (questionText != null && answer != null) {
          // Hash the answer
          final answerSalt = _generateSalt();
          final answerHash = _hashPassphrase(answer, answerSalt);
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
      
      // Verify passphrase
      if (!_verifyPassphrase(passphrase, storedHash)) {
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
            if (_verifyAnswerCaseInsensitive(answerText, matchingQuestion['answerHash']!)) {
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
  bool _verifyAnswerCaseInsensitive(String answer, String storedHash) {
    // Extract salt from stored hash
    if (!storedHash.contains('\$salt:')) return false;
    
    final parts = storedHash.split('\$salt:');
    final hashPart = parts[0];
    final salt = parts[1];
    
    // Hash the input answer with the extracted salt (lowercase for case-insensitive comparison)
    final hashedInput = _hashPassphrase(answer.toLowerCase().trim(), salt);
    
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
      
      // Store new passphrase hash locally
      final salt = _generateSalt();
      final hash = _hashPassphrase(newPassphrase, salt);
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