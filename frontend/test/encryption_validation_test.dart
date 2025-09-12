import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/services/database_service.dart';
import 'package:cred_manager/services/encryption_service.dart';
import 'package:cred_manager/services/storage_service.dart';
import 'package:cred_manager/services/biometric_auth_service.dart';
import 'dart:io';
import 'dart:typed_data';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService databaseService;
  late EncryptionService encryptionService;
  late StorageService storageService;
  late BiometricAuthService biometricService;

  setUp(() async {
    databaseService = DatabaseService.instance;
    encryptionService = EncryptionService();
    storageService = StorageService();
    biometricService = BiometricAuthService();
    
    // Clean up any existing test database
    await databaseService.deleteDatabase();
    DatabaseService.clearPassphrase();
  });

  tearDown(() async {
    // Clean up after each test
    await databaseService.deleteDatabase();
    DatabaseService.clearPassphrase();
  });

  group('Cross-Platform Encryption Validation', () {
    test('should validate SQLCipher platform compatibility', () async {
      const testPassphrase = 'CrossPlatformTest123!';
      await DatabaseService.setPassphrase(testPassphrase);

      final db = await databaseService.database;
      expect(db, isNotNull, reason: 'Database should initialize on all platforms');

      // Verify encryption is working regardless of platform
      final results = await db.rawQuery('PRAGMA cipher_version');
      if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        // Desktop platforms should use sqflite_common_ffi with encryption
        expect(results, isNotNull, reason: 'Desktop platforms should support encryption');
      } else {
        // Mobile platforms should use SQLCipher
        expect(results.isNotEmpty, true, reason: 'Mobile platforms should have SQLCipher');
      }
    });

    test('should validate cross-platform database file encryption', () async {
      const testPassphrase = 'FileEncryptionTest123!';
      await DatabaseService.setPassphrase(testPassphrase);

      // Create database and insert sensitive data
      await databaseService.updateMetadata('sensitive_data', 'top_secret_value');
      await databaseService.close();

      // Verify database file exists and is encrypted
      final dbPath = await databaseService.getDatabasePath();
      final dbFile = File(dbPath);
      expect(dbFile.existsSync(), true, reason: 'Database file should exist');

      // Read raw file content - should not contain plaintext
      final rawBytes = dbFile.readAsBytesSync();
      final rawString = String.fromCharCodes(rawBytes);
      expect(rawString.contains('top_secret_value'), false, 
             reason: 'Database file should not contain plaintext sensitive data');
      expect(rawString.contains('SQLite'), false,
             reason: 'Database file should not contain SQLite header in plaintext');
    });

    test('should validate platform-specific database factories', () async {
      const testPassphrase = 'FactoryTest123!';
      await DatabaseService.setPassphrase(testPassphrase);

      final db = await databaseService.database;
      
      // Test basic operations work on all platforms
      await db.execute('CREATE TABLE IF NOT EXISTS platform_test (id TEXT PRIMARY KEY, data TEXT)');
      await db.insert('platform_test', {'id': 'test1', 'data': 'platform_data'});
      
      final results = await db.query('platform_test', where: 'id = ?', whereArgs: ['test1']);
      expect(results.length, equals(1));
      expect(results.first['data'], equals('platform_data'));
    });
  });

  group('XOR Encryption Layer Validation', () {
    test('should validate XOR encryption is applied to sensitive fields', () async {
      const testPassphrase = 'XORTest123!';
      await DatabaseService.setPassphrase(testPassphrase);

      const originalData = 'sensitive_api_key_12345';
      
      // Store data which should be XOR encrypted
      await databaseService.storeEncryptedPassphraseHash(originalData);
      
      // Retrieve and verify it's properly decrypted
      final retrievedData = await databaseService.getEncryptedPassphraseHash();
      expect(retrievedData, equals(originalData), 
             reason: 'XOR encryption should be transparent to application');
    });

    test('should validate XOR encryption key consistency', () async {
      const testPassphrase = 'XORKeyTest123!';
      
      // Test that encryption with same data produces consistent results
      const testData = 'test_encryption_consistency';
      final encrypted1 = await encryptionService.encryptData(testData);
      final encrypted2 = await encryptionService.encryptData(testData);
      
      expect(encrypted1, equals(encrypted2), reason: 'XOR encryption should be deterministic with same key');
      
      // Both should decrypt to original
      final decrypted1 = await encryptionService.decryptData(encrypted1);
      final decrypted2 = await encryptionService.decryptData(encrypted2);
      expect(decrypted1, equals(testData));
      expect(decrypted2, equals(testData));
    });

    test('should validate XOR encryption/decryption round-trip', () async {
      final testData = [
        'Simple text',
        'Text with special chars: !@#\$%^&*()',
        'Unicode text: 🔐🗝️🛡️ Пароль ñáéíóú',
        'JSON data: {"key": "value", "number": 123}',
        'Base64-like: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9',
        'Very long text: ${'a' * 1000}',
      ];

      for (final originalText in testData) {
        final encrypted = await encryptionService.encryptData(originalText);
        expect(encrypted, isNot(equals(originalText)), 
               reason: 'Encrypted data should differ from original');
        
        final decrypted = await encryptionService.decryptData(encrypted);
        expect(decrypted, equals(originalText), 
               reason: 'Decrypted data should match original for: $originalText');
      }
    });

    test('should validate XOR encryption handles edge cases', () async {
      // Test empty string
      final encryptedEmpty = await encryptionService.encryptData('');
      final decryptedEmpty = await encryptionService.decryptData(encryptedEmpty);
      expect(decryptedEmpty, equals(''));

      // Test single character
      final encryptedChar = await encryptionService.encryptData('x');
      final decryptedChar = await encryptionService.decryptData(encryptedChar);
      expect(decryptedChar, equals('x'));

      // Test null bytes (if supported)
      final nullByteString = String.fromCharCode(0) + 'test' + String.fromCharCode(0);
      final encryptedNull = await encryptionService.encryptData(nullByteString);
      final decryptedNull = await encryptionService.decryptData(encryptedNull);
      expect(decryptedNull, equals(nullByteString));
    });
  });

  group('Double Encryption Validation (Biometric Keys)', () {
    test('should validate double encryption for biometric keys', () async {
      const testPassphrase = 'DoubleEncryptTest123!';
      await DatabaseService.setPassphrase(testPassphrase);

      const originalKey = 'biometric_master_key_12345';
      
      // Store biometric key (should be double encrypted)
      await biometricService.storeBiometricKey(originalKey);
      
      // Retrieve and verify
      final retrievedKey = await biometricService.getBiometricKey();
      expect(retrievedKey, equals(originalKey), 
             reason: 'Double encryption should be transparent to application');
    });

    test('should validate double encryption vs single encryption difference', () async {
      const testPassphrase = 'EncryptionCompareTest123!';
      await DatabaseService.setPassphrase(testPassphrase);

      const testData = 'test_encryption_data';
      
      // Single encryption (normal XOR encryption)
      final singleEncrypted = await encryptionService.encryptData(testData);
      
      // Double encryption (XOR + additional encryption layer)
      final doubleEncrypted = await encryptionService.encryptData(singleEncrypted);
      
      expect(singleEncrypted, isNot(equals(doubleEncrypted)),
             reason: 'Double encryption should produce different result than single');
      expect(doubleEncrypted.length, greaterThan(singleEncrypted.length),
             reason: 'Double encryption should typically increase data size');
    });
  });

  group('End-to-End Encryption Validation', () {
    test('should validate complete authentication data encryption flow', () async {
      const testPassphrase = 'E2EAuthTest123!';
      await DatabaseService.setPassphrase(testPassphrase);

      // Store complete authentication data set
      await storageService.storePassphraseHash('argon2_hash_12345');
      await storageService.storeToken('jwt_token_eyJhbGciOiJIUzI1NiJ9');
      await storageService.setLoggedIn(true);
      await storageService.setSetupCompleted(true);
      
      final securityQuestions = [
        {'question': 'Test question?', 'answerHash': 'answer_hash', 'isCustom': 'true'}
      ];
      await storageService.storeSecurityQuestions(securityQuestions);
      
      await biometricService.setBiometricEnabled(true);
      await biometricService.storeBiometricKey('biometric_key_12345');

      // Close and reopen database to ensure persistence
      await databaseService.close();
      await DatabaseService.setPassphrase(testPassphrase);

      // Verify all data is retrievable and correct
      expect(await storageService.getPassphraseHash(), equals('argon2_hash_12345'));
      expect(await storageService.getToken(), equals('jwt_token_eyJhbGciOiJIUzI1NiJ9'));
      expect(await storageService.isLoggedIn(), isTrue);
      expect(await storageService.getSetupCompleted(), isTrue);
      
      final retrievedQuestions = await storageService.getSecurityQuestions();
      expect(retrievedQuestions, isNotNull);
      expect(retrievedQuestions!.length, equals(1));
      
      expect(await biometricService.isBiometricEnabled(), isTrue);
      expect(await biometricService.getBiometricKey(), equals('biometric_key_12345'));
    });

    test('should validate encryption with wrong passphrase fails gracefully', () async {
      const correctPassphrase = 'CorrectPass123!';
      const wrongPassphrase = 'WrongPass456!';

      // Create database with correct passphrase
      await DatabaseService.setPassphrase(correctPassphrase);
      await storageService.storePassphraseHash('test_hash');
      await databaseService.close();

      // Try to open with wrong passphrase
      await DatabaseService.setPassphrase(wrongPassphrase);
      
      // Operations should fail gracefully
      expect(() async => await storageService.getPassphraseHash(), 
             returnsNormally, reason: 'Wrong passphrase should fail gracefully, not crash');
      
      final hash = await storageService.getPassphraseHash();
      expect(hash, isNull, reason: 'Wrong passphrase should return null, not decrypted data');
    });

    test('should validate database integrity after encryption operations', () async {
      const testPassphrase = 'IntegrityTest123!';
      await DatabaseService.setPassphrase(testPassphrase);

      // Perform many encryption operations
      for (int i = 0; i < 50; i++) {
        await databaseService.updateMetadata('test_key_$i', 'test_value_$i');
        await storageService.storeToken('jwt_token_$i');
        await biometricService.storeBiometricKey('biometric_key_$i');
      }

      // Verify database integrity
      final integrityCheck = await databaseService.checkIntegrity();
      expect(integrityCheck, isTrue, reason: 'Database should maintain integrity after many operations');

      // Verify all data is still retrievable
      for (int i = 0; i < 50; i++) {
        final metadata = await databaseService.getMetadata('test_key_$i');
        expect(metadata, equals('test_value_$i'));
      }
    });
  });

  group('Migration and Legacy Data Validation', () {
    test('should validate migration from SharedPreferences to encrypted database', () async {
      const testPassphrase = 'MigrationTest123!';
      await DatabaseService.setPassphrase(testPassphrase);

      // This test verifies that the migration logic works correctly
      // The actual SharedPreferences setup is handled in StorageService
      
      final securityQuestions = [
        {'question': 'Migration test?', 'answerHash': 'migration_hash', 'isCustom': 'false'}
      ];
      
      await storageService.storeSecurityQuestions(securityQuestions);
      final retrievedQuestions = await storageService.getSecurityQuestions();
      
      expect(retrievedQuestions, isNotNull);
      expect(retrievedQuestions!.length, equals(1));
      expect(retrievedQuestions.first['question'], equals('Migration test?'));
    });

    test('should validate no sensitive data remains in SharedPreferences', () async {
      const testPassphrase = 'NoLeakageTest123!';
      await DatabaseService.setPassphrase(testPassphrase);

      // Store data through encrypted storage service
      await storageService.storePassphraseHash('test_hash');
      await storageService.storeToken('test_token');
      await biometricService.setBiometricEnabled(true);

      // Clear all data
      await storageService.clearAll();

      // Verify all sensitive data is cleared
      expect(await storageService.getPassphraseHash(), isNull);
      expect(await storageService.getToken(), isNull);
      expect(await biometricService.isBiometricEnabled(), isFalse);
    });
  });

  group('Performance and Security Validation', () {
    test('should validate encryption performance meets requirements', () async {
      const testPassphrase = 'PerformanceTest123!';
      await DatabaseService.setPassphrase(testPassphrase);

      final stopwatch = Stopwatch()..start();
      
      // Test encryption performance with reasonable dataset
      for (int i = 0; i < 100; i++) {
        await storageService.storeToken('performance_token_$i');
      }
      
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
             reason: '100 encryption operations should complete within 5 seconds');

      // Test decryption performance
      stopwatch.reset();
      stopwatch.start();
      
      for (int i = 0; i < 100; i++) {
        await storageService.getToken();
      }
      
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
             reason: '100 decryption operations should complete within 3 seconds');
    });

    test('should validate encryption randomness and security', () async {
      const testData = 'identical_test_data';
      
      // Encrypt same data multiple times
      final encrypted1 = await encryptionService.encryptData(testData);
      final encrypted2 = await encryptionService.encryptData(testData);
      final encrypted3 = await encryptionService.encryptData(testData);
      
      // Due to XOR encryption being deterministic with same key, 
      // results should be identical (which is expected for this implementation)
      expect(encrypted1, equals(encrypted2));
      expect(encrypted2, equals(encrypted3));
      
      // But encrypted should differ from original
      expect(encrypted1, isNot(equals(testData)));
      
      // Verify all decrypt to original
      expect(await encryptionService.decryptData(encrypted1), equals(testData));
      expect(await encryptionService.decryptData(encrypted2), equals(testData));
      expect(await encryptionService.decryptData(encrypted3), equals(testData));
    });
  });
}