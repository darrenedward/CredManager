import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/services/storage_service.dart';
import 'package:cred_manager/services/database_service.dart';
import 'package:cred_manager/services/encryption_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;

  setUp(() async {
    storageService = StorageService();
    
    // Clean up any existing test database
    await DatabaseService.instance.deleteDatabase();
    DatabaseService.clearPassphrase();
    
    // Initialize database with test passphrase
    await DatabaseService.setPassphrase('test_passphrase_12345');
    
    // Ensure clean state
    await DatabaseService.instance.clearAllAuthData();
  });

  tearDown(() async {
    // Clean up after each test
    await DatabaseService.instance.deleteDatabase();
    DatabaseService.clearPassphrase();
  });

  group('Encrypted Database Storage Tests', () {
    test('should store and retrieve passphrase hash', () async {
      const testHash = 'test_argon2_hash_value';
      
      await storageService.storePassphraseHash(testHash);
      final retrievedHash = await storageService.getPassphraseHash();
      
      expect(retrievedHash, equals(testHash));
    });

    test('should store and retrieve JWT token', () async {
      const testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.signature';
      
      await storageService.storeToken(testToken);
      final retrievedToken = await storageService.getToken();
      
      expect(retrievedToken, equals(testToken));
    });

    test('should handle authentication flags correctly', () async {
      // Test first time flag
      await storageService.setFirstTime(false);
      final isFirstTime = await storageService.isFirstTime();
      expect(isFirstTime, isFalse);

      // Test logged in flag
      await storageService.setLoggedIn(true);
      final isLoggedIn = await storageService.isLoggedIn();
      expect(isLoggedIn, isTrue);

      // Test setup completed flag
      await storageService.setSetupCompleted(true);
      final setupCompleted = await storageService.getSetupCompleted();
      expect(setupCompleted, isTrue);
    });

    test('should clear all authentication data', () async {
      // Store test data
      await storageService.storePassphraseHash('test_hash');
      await storageService.storeToken('test_token');
      await storageService.setLoggedIn(true);
      await storageService.setSetupCompleted(true);

      // Clear all data
      await storageService.clearAll();

      // Verify all data is cleared
      expect(await storageService.getPassphraseHash(), isNull);
      expect(await storageService.getToken(), isNull);
      expect(await storageService.isLoggedIn(), isFalse);
      expect(await storageService.isFirstTime(), isTrue);
      expect(await storageService.getSetupCompleted(), isFalse);
    });

    test('should reset setup correctly', () async {
      // Set up some data
      await storageService.storePassphraseHash('test_hash');
      await storageService.storeToken('test_token');
      await storageService.setLoggedIn(true);
      await storageService.setSetupCompleted(true);

      // Reset setup
      await storageService.resetSetup();

      // Verify reset state
      expect(await storageService.getPassphraseHash(), isNull);
      expect(await storageService.getToken(), isNull);
      expect(await storageService.isFirstTime(), isTrue);
      expect(await storageService.getSetupCompleted(), isFalse);
    });

    test('should handle token expiration check', () async {
      // Test with no token
      expect(await storageService.isTokenExpired(), isTrue);

      // Test with invalid token
      await storageService.storeToken('invalid_token');
      expect(await storageService.isTokenExpired(), isTrue);

      // Test cleanup of expired tokens
      await storageService.setLoggedIn(true);
      await storageService.cleanupExpiredTokens();
      expect(await storageService.isLoggedIn(), isFalse);
      expect(await storageService.getToken(), isNull);
    });

    test('should store and retrieve security questions', () async {
      final testQuestions = [
        {
          'question': 'Test question 1?',
          'answerHash': 'test_hash_1',
          'isCustom': 'true',
        },
        {
          'question': 'Test question 2?',
          'answerHash': 'test_hash_2',
          'isCustom': 'false',
        },
      ];

      await storageService.storeSecurityQuestions(testQuestions);
      final retrievedQuestions = await storageService.getSecurityQuestions();

      expect(retrievedQuestions, isNotNull);
      expect(retrievedQuestions!.length, equals(2));
      expect(retrievedQuestions[0]['question'], equals('Test question 1?'));
      expect(retrievedQuestions[1]['question'], equals('Test question 2?'));
    });

    test('should handle encryption/decryption errors gracefully', () async {
      // Test with corrupted data in database
      await DatabaseService.instance.updateMetadata('encrypted_passphrase_hash', 'corrupted_data');
      
      final retrievedHash = await storageService.getPassphraseHash();
      expect(retrievedHash, isNull);
    });
  });
}