import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/services/auth_service.dart';
import 'package:cred_manager/services/argon2_service.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService authService;
  late Argon2Service argon2Service;

  setUp(() {
    // Mock method channels for flutter_secure_storage
    const MethodChannel secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'read':
            return null; // Return null for reads in tests
          case 'write':
            return null; // Mock successful write
          case 'delete':
            return null; // Mock successful delete
          case 'deleteAll':
            return null; // Mock successful deleteAll
          default:
            return null;
        }
      },
    );

    // Mock method channels for shared_preferences
    const MethodChannel sharedPrefsChannel = MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      sharedPrefsChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getAll':
            return {}; // Return empty map for getAll
          case 'setBool':
            return true; // Mock successful setBool
          case 'setString':
            return true; // Mock successful setString
          case 'remove':
            return true; // Mock successful remove
          case 'clear':
            return true; // Mock successful clear
          default:
            return null;
        }
      },
    );

    // We'll test the AuthService methods directly since they're now local
    authService = AuthService();
    argon2Service = Argon2Service();
  });

  test('createPassphrase succeeds', () async {
    final token = await authService.createPassphrase('ValidPass123', [
      {'question': 'What is your favorite color?', 'answerHash': 'hash1'},
      {'question': 'What was your first pet?', 'answerHash': 'hash2'}
    ]);
    expect(token, isNotNull);
    expect(token, isA<String>());
  });

  test('login succeeds with valid passphrase', () async {
    // First create a passphrase to test login
    await authService.createPassphrase('ValidPass123', [
      {'question': 'What is your favorite color?', 'answerHash': 'hash1'},
      {'question': 'What was your first pet?', 'answerHash': 'hash2'}
    ]);
    
    final token = await authService.login('ValidPass123');
    expect(token, isNotNull);
    expect(token, isA<String>());
  });

  test('initiateRecovery returns questions', () async {
    // First create security questions
    await authService.createPassphrase('ValidPass123', [
      {'question': 'What is your favorite color?', 'answerHash': 'hash1'},
      {'question': 'What was your first pet?', 'answerHash': 'hash2'}
    ]);
    
    final questions = await authService.initiateRecovery();
    expect(questions, isNotNull);
    expect(questions, isA<List<String>>());
  });

  test('verifyToken succeeds with valid token', () async {
    final token = await authService.createPassphrase('ValidPass123', [
      {'question': 'What is your favorite color?', 'answerHash': 'hash1'},
      {'question': 'What was your first pet?', 'answerHash': 'hash2'}
    ]);
    
    final result = await authService.verifyToken(token!);
    expect(result, true);
  });

  group('Argon2 Integration Tests with AuthService', () {
    test('AuthService should use Argon2 for password hashing', () async {
      // TDD: This test validates that AuthService integrates with Argon2Service
      // Initially may fail if AuthService doesn't use Argon2 yet
      
      const passphrase = 'TestPassphrase123!';
      final securityQuestions = [
        {'question': 'What is your favorite color?', 'answerHash': 'hash1'},
        {'question': 'What was your first pet?', 'answerHash': 'hash2'}
      ];
      
      // Create passphrase using AuthService
      final token = await authService.createPassphrase(passphrase, securityQuestions);
      expect(token, isNotNull, reason: 'AuthService should create passphrase successfully');
      
      // Login should work with the same passphrase
      final loginToken = await authService.login(passphrase);
      expect(loginToken, isNotNull, reason: 'AuthService should authenticate with Argon2');
      expect(loginToken, equals(token), reason: 'Login should return same token for same passphrase');
    });

    test('AuthService should handle whitespace normalization in passphrases', () async {
      // TDD: This test validates the trimming requirement from the spec
      const cleanPassphrase = 'CleanPassphrase123!';
      const passphraseWithSpaces = '  CleanPassphrase123!  ';
      
      final securityQuestions = [
        {'question': 'What is your favorite color?', 'answerHash': 'hash1'},
      ];
      
      // Create with clean passphrase
      await authService.createPassphrase(cleanPassphrase, securityQuestions);
      
      // Should be able to login with whitespace version (after trimming)
      final token = await authService.login(passphraseWithSpaces);
      expect(token, isNotNull, reason: 'AuthService should trim whitespace from passphrases');
    });

    test('AuthService should reject incorrect passphrases', () async {
      const correctPassphrase = 'CorrectPassphrase123!';
      const wrongPassphrase = 'WrongPassphrase456!';
      
      final securityQuestions = [
        {'question': 'What is your favorite color?', 'answerHash': 'hash1'},
      ];
      
      // Create with correct passphrase
      await authService.createPassphrase(correctPassphrase, securityQuestions);
      
      // Should fail with wrong passphrase
      final token = await authService.login(wrongPassphrase);
      expect(token, isNull, reason: 'AuthService should reject incorrect passphrases');
    });

    test('AuthService should handle special characters in passphrases', () async {
      const specialPassphrase = 'Special!@#\$%^&*()_+-=[]{}|;:,.<>?123';
      
      final securityQuestions = [
        {'question': 'What is your favorite color?', 'answerHash': 'hash1'},
      ];
      
      // Create and login with special character passphrase
      await authService.createPassphrase(specialPassphrase, securityQuestions);
      final token = await authService.login(specialPassphrase);
      
      expect(token, isNotNull, reason: 'AuthService should handle special characters in passphrases');
    });

    test('AuthService should handle Unicode characters in passphrases', () async {
      const unicodePassphrase = 'Пароль🔐Test123ñáéíóú';
      
      final securityQuestions = [
        {'question': 'What is your favorite color?', 'answerHash': 'hash1'},
      ];
      
      // Create and login with Unicode passphrase
      await authService.createPassphrase(unicodePassphrase, securityQuestions);
      final token = await authService.login(unicodePassphrase);
      
      expect(token, isNotNull, reason: 'AuthService should handle Unicode characters in passphrases');
    });

    test('AuthService performance should be acceptable', () async {
      const passphrase = 'PerformanceTestPassphrase123!';
      
      final securityQuestions = [
        {'question': 'What is your favorite color?', 'answerHash': 'hash1'},
      ];
      
      // Test creation performance
      final createStopwatch = Stopwatch()..start();
      await authService.createPassphrase(passphrase, securityQuestions);
      createStopwatch.stop();
      
      // Test login performance
      final loginStopwatch = Stopwatch()..start();
      final token = await authService.login(passphrase);
      loginStopwatch.stop();
      
      expect(token, isNotNull, reason: 'Performance test should succeed');
      expect(loginStopwatch.elapsedMilliseconds, lessThan(500),
             reason: 'Login should complete within 500ms (actual: ${loginStopwatch.elapsedMilliseconds}ms)');
      
      // Note: Creation can be slower as it's less performance-critical
      expect(createStopwatch.elapsedMilliseconds, lessThan(1000),
             reason: 'Passphrase creation should complete within 1000ms');
    });
  });
}