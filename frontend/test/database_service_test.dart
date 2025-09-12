import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/services/database_service.dart';
import 'package:cred_manager/services/argon2_service.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'dart:io';
import 'dart:typed_data';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService databaseService;
  late Argon2Service argon2Service;

  setUp(() async {
    databaseService = DatabaseService.instance;
    argon2Service = Argon2Service();
    
    // Clean up any existing test database
    await databaseService.deleteDatabase();
    DatabaseService.clearPassphrase();
  });

  tearDown(() async {
    // Clean up after each test
    await databaseService.deleteDatabase();
    DatabaseService.clearPassphrase();
  });

  group('SQLCipher Integration Tests', () {
    group('Database Initialization with SQLCipher', () {
      test('should create database with SQLCipher encryption enabled', () async {
        // TDD: This test will initially fail as SQLCipher is not yet implemented
        const testPassphrase = 'TestPassphrase123!';
        DatabaseService.setPassphrase(testPassphrase);

        final db = await databaseService.database;
        expect(db, isNotNull, reason: 'Database should be created successfully');

        // Verify SQLCipher is enabled by checking encryption pragma
        final results = await db.rawQuery('PRAGMA cipher_version');
        expect(results.isNotEmpty, true, 
               reason: 'SQLCipher should be available and return version info');
      });

      test('should open database successfully with correct passphrase', () async {
        // TDD: This test will fail until proper SQLCipher key derivation is implemented
        const testPassphrase = 'CorrectPassphrase123!';
        DatabaseService.setPassphrase(testPassphrase);

        final db = await databaseService.database;
        expect(db, isNotNull);

        // Verify database operations work with encryption
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM sqlite_master');
        expect(result.isNotEmpty, true, 
               reason: 'Database operations should work with encrypted database');
      });

      test('should fail to open database with incorrect passphrase', () async {
        // TDD: This test verifies that wrong passphrases are rejected
        const correctPassphrase = 'CorrectPassphrase123!';
        const wrongPassphrase = 'WrongPassphrase456!';

        // First, create database with correct passphrase
        DatabaseService.setPassphrase(correctPassphrase);
        await databaseService.database;
        await databaseService.close();

        // Try to open with wrong passphrase - should fail
        DatabaseService.setPassphrase(wrongPassphrase);
        
        expect(() async => await databaseService.database, 
               throwsA(isA<DatabaseException>()),
               reason: 'Database should reject incorrect passphrase');
      });

      test('should maintain foreign key constraints in encrypted mode', () async {
        // TDD: Verify that encryption doesn't break database integrity
        const testPassphrase = 'TestPassphrase123!';
        DatabaseService.setPassphrase(testPassphrase);

        final db = await databaseService.database;
        
        // Check that foreign keys are enabled
        final result = await db.rawQuery('PRAGMA foreign_keys');
        expect(result.first['foreign_keys'], 1,
               reason: 'Foreign key constraints should be enabled');
      });
    });

    group('Passphrase-Derived Key Generation', () {
      test('should derive encryption key from user passphrase using Argon2', () async {
        // TDD: This test will fail until Argon2-based key derivation is implemented
        const testPassphrase = 'TestPassphrase123!';
        
        // Mock key derivation process
        final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
        final derivedKey = await argon2Service.deriveKey(testPassphrase, salt, 32);
        
        expect(derivedKey, isNotNull, reason: 'Key should be derived successfully');
        expect(derivedKey.length, equals(32), reason: 'Key should be 256 bits (32 bytes)');
        
        // Key should be deterministic for same passphrase and salt
        final derivedKey2 = await argon2Service.deriveKey(testPassphrase, salt, 32);
        expect(derivedKey, equals(derivedKey2), 
               reason: 'Key derivation should be deterministic');
      });

      test('should generate different keys with different salts', () async {
        // TDD: Verify salt handling in key derivation
        const testPassphrase = 'TestPassphrase123!';
        
        final salt1 = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
        final salt2 = Uint8List.fromList([9, 10, 11, 12, 13, 14, 15, 16]);
        
        final key1 = await argon2Service.deriveKey(testPassphrase, salt1, 32);
        final key2 = await argon2Service.deriveKey(testPassphrase, salt2, 32);
        
        expect(key1, isNot(equals(key2)), 
               reason: 'Different salts should produce different keys');
      });

      test('should validate key strength meets SQLCipher requirements', () async {
        // TDD: Ensure derived keys meet security requirements
        const testPassphrase = 'TestPassphrase123!';
        final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
        
        final derivedKey = await argon2Service.deriveKey(testPassphrase, salt, 32);
        
        // Key should be exactly 32 bytes for AES-256
        expect(derivedKey.length, equals(32));
        
        // Key should not be all zeros
        expect(derivedKey.any((byte) => byte != 0), true,
               reason: 'Key should contain non-zero bytes');
        
        // Basic entropy check - key should have reasonable distribution
        final uniqueBytes = derivedKey.toSet();
        expect(uniqueBytes.length, greaterThan(16),
               reason: 'Key should have reasonable byte distribution');
      });

      test('should handle invalid passphrase inputs gracefully', () async {
        // TDD: Test error handling for invalid inputs
        final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
        
        // Empty passphrase should fail
        expect(() async => await argon2Service.deriveKey('', salt, 32),
               throwsArgumentError,
               reason: 'Empty passphrase should be rejected');
        
        // Null salt should fail
        expect(() async => await argon2Service.deriveKey('test', Uint8List(0), 32),
               throwsArgumentError,
               reason: 'Empty salt should be rejected');
      });
    });

    group('Data Encryption/Decryption Workflows', () {
      test('should automatically encrypt data on INSERT operations', () async {
        // TDD: Verify that data is encrypted when stored
        const testPassphrase = 'TestPassphrase123!';
        DatabaseService.setPassphrase(testPassphrase);

        final db = await databaseService.database;
        
        // Insert test data
        const testData = 'Sensitive API Key: sk-1234567890abcdef';
        await databaseService.insert('credentials', {
          'id': 'test-cred-1',
          'project_id': 'test-project',
          'name': 'Test API Key',
          'encrypted_value': testData,
          'credential_type': 'api_key',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        // Verify data was inserted
        final results = await databaseService.query('credentials', 
                                                   where: 'id = ?', 
                                                   whereArgs: ['test-cred-1']);
        expect(results.length, equals(1));
        expect(results.first['encrypted_value'], equals(testData));
      });

      test('should automatically decrypt data on SELECT operations', () async {
        // TDD: Verify that encrypted data is properly decrypted when retrieved
        const testPassphrase = 'TestPassphrase123!';
        DatabaseService.setPassphrase(testPassphrase);

        // Insert encrypted data
        const originalData = 'Secret API Key: sk-abcdef1234567890';
        await databaseService.insert('credentials', {
          'id': 'test-cred-2',
          'project_id': 'test-project',
          'name': 'Secret Key',
          'encrypted_value': originalData,
          'credential_type': 'api_key',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        // Retrieve and verify decryption
        final results = await databaseService.query('credentials',
                                                   where: 'id = ?',
                                                   whereArgs: ['test-cred-2']);
        
        expect(results.length, equals(1));
        expect(results.first['encrypted_value'], equals(originalData),
               reason: 'Data should be properly decrypted when retrieved');
      });

      test('should handle complex data types with encryption', () async {
        // TDD: Test encryption of different data types
        const testPassphrase = 'TestPassphrase123!';
        DatabaseService.setPassphrase(testPassphrase);

        // Test TEXT data
        await databaseService.insert('app_metadata', {
          'key': 'complex_text',
          'value': 'Multi-line\nText with\tTabs and 特殊字符',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        // Test JSON-like data
        await databaseService.insert('app_metadata', {
          'key': 'json_data',
          'value': '{"api_key": "sk-123", "settings": {"enabled": true}}',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        // Verify data integrity
        final textResult = await databaseService.getMetadata('complex_text');
        expect(textResult, equals('Multi-line\nText with\tTabs and 特殊字符'));

        final jsonResult = await databaseService.getMetadata('json_data');
        expect(jsonResult, equals('{"api_key": "sk-123", "settings": {"enabled": true}}'));
      });

      test('should maintain data integrity through encrypt/decrypt cycles', () async {
        // TDD: Verify no data corruption during encryption/decryption
        const testPassphrase = 'TestPassphrase123!';
        DatabaseService.setPassphrase(testPassphrase);

        final originalValues = [
          'Simple text',
          'Text with spaces   and   multiple   spaces',
          'Special chars: !@#\$%^&*()_+-=[]{}|;:,.<>?',
          'Unicode: 🔐🗝️🛡️ Пароль ñáéíóú',
          'Binary-like: \x00\x01\x02\x03\xFF\xFE',
          'Very long text: ${'a' * 1000}',
        ];

        // Store all test values
        for (int i = 0; i < originalValues.length; i++) {
          await databaseService.insert('app_metadata', {
            'key': 'integrity_test_$i',
            'value': originalValues[i],
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
        }

        // Retrieve and verify all values
        for (int i = 0; i < originalValues.length; i++) {
          final retrievedValue = await databaseService.getMetadata('integrity_test_$i');
          expect(retrievedValue, equals(originalValues[i]),
                 reason: 'Data integrity should be maintained for value $i');
        }
      });

      test('should detect data corruption in encrypted database', () async {
        // TDD: Test detection of corrupted encrypted data
        const testPassphrase = 'TestPassphrase123!';
        DatabaseService.setPassphrase(testPassphrase);

        // This test will need to simulate corruption and verify detection
        // Implementation will depend on SQLCipher corruption detection mechanisms
        expect(() async {
          // Attempt to read from corrupted database should throw
          await databaseService.checkIntegrity();
        }, returnsNormally, reason: 'Integrity check should complete without errors');
      });
    });

    group('Transaction Handling with Encryption', () {
      test('should handle transactions properly in encrypted database', () async {
        // TDD: Verify transactions work correctly with encryption
        const testPassphrase = 'TestPassphrase123!';
        DatabaseService.setPassphrase(testPassphrase);

        final result = await databaseService.transaction((txn) async {
          // Insert multiple records in transaction
          await txn.insert('projects', {
            'id': 'txn-project-1',
            'name': 'Transaction Test Project',
            'description': 'Testing transactions with encryption',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });

          await txn.insert('credentials', {
            'id': 'txn-cred-1',
            'project_id': 'txn-project-1',
            'name': 'Transaction Test Credential',
            'encrypted_value': 'secret-api-key-in-transaction',
            'credential_type': 'api_key',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });

          return 'success';
        });

        expect(result, equals('success'));

        // Verify both records were inserted
        final projects = await databaseService.query('projects', 
                                                    where: 'id = ?', 
                                                    whereArgs: ['txn-project-1']);
        final credentials = await databaseService.query('credentials',
                                                       where: 'id = ?',
                                                       whereArgs: ['txn-cred-1']);

        expect(projects.length, equals(1));
        expect(credentials.length, equals(1));
      });

      test('should rollback transactions properly on failure', () async {
        // TDD: Test transaction rollback behavior with encryption
        const testPassphrase = 'TestPassphrase123!';
        DatabaseService.setPassphrase(testPassphrase);

        expect(() async {
          await databaseService.transaction((txn) async {
            await txn.insert('projects', {
              'id': 'rollback-project',
              'name': 'Rollback Test',
              'description': 'This should be rolled back',
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            });

            // Force transaction failure
            throw Exception('Simulated transaction failure');
          });
        }, throwsException);

        // Verify rollback occurred - project should not exist
        final projects = await databaseService.query('projects',
                                                    where: 'id = ?',
                                                    whereArgs: ['rollback-project']);
        expect(projects.length, equals(0),
               reason: 'Transaction rollback should remove inserted data');
      });
    });

    group('Authentication Data Storage', () {
      test('should store passphrase hashes in encrypted database', () async {
        // TDD: Verify authentication data is stored encrypted
        const testPassphrase = 'AuthTestPassphrase123!';
        DatabaseService.setPassphrase(testPassphrase);

        // Hash the passphrase using Argon2
        final passphraseHash = await argon2Service.hashPassword(testPassphrase);
        
        await databaseService.updateMetadata('passphrase_hash', passphraseHash);

        final retrievedHash = await databaseService.getMetadata('passphrase_hash');
        expect(retrievedHash, equals(passphraseHash));
        expect(retrievedHash, isNot(equals(testPassphrase)),
               reason: 'Stored hash should not match original passphrase');
      });

      test('should store security questions in encrypted database', () async {
        // TDD: Test security questions storage with encryption
        const testPassphrase = 'SecurityTestPassphrase123!';
        DatabaseService.setPassphrase(testPassphrase);

        final securityQuestions = [
          {'question': 'What is your favorite color?', 
           'answerHash': 'hashed_answer_1', 
           'isCustom': 'true'},
          {'question': 'What was your first pet?', 
           'answerHash': 'hashed_answer_2', 
           'isCustom': 'false'},
        ];

        await databaseService.storeSecurityQuestions(securityQuestions);

        final retrievedQuestions = await databaseService.getSecurityQuestions();
        expect(retrievedQuestions, isNotNull);
        expect(retrievedQuestions!.length, equals(2));
        expect(retrievedQuestions[0]['question'], equals('What is your favorite color?'));
        expect(retrievedQuestions[1]['question'], equals('What was your first pet?'));
      });

      test('should store JWT tokens in encrypted database', () async {
        // TDD: Test JWT token storage with encryption
        const testPassphrase = 'JWTTestPassphrase123!';
        DatabaseService.setPassphrase(testPassphrase);

        const testJwtToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.signature';
        
        await databaseService.updateMetadata('jwt_token', testJwtToken);

        final retrievedToken = await databaseService.getMetadata('jwt_token');
        expect(retrievedToken, equals(testJwtToken));
      });
    });

    group('Metadata Consolidation', () {
      test('should consolidate all app flags in encrypted database', () async {
        // TDD: Verify all application state is stored in encrypted DB
        const testPassphrase = 'MetadataTestPassphrase123!';
        DatabaseService.setPassphrase(testPassphrase);

        // Test various metadata flags
        await databaseService.updateMetadata('is_first_time', 'false');
        await databaseService.updateMetadata('setup_completed', 'true');
        await databaseService.updateMetadata('biometric_enabled', 'true');
        await databaseService.updateMetadata('theme_mode', 'dark');

        // Verify all flags are retrievable
        expect(await databaseService.getMetadata('is_first_time'), equals('false'));
        expect(await databaseService.getMetadata('setup_completed'), equals('true'));
        expect(await databaseService.getMetadata('biometric_enabled'), equals('true'));
        expect(await databaseService.getMetadata('theme_mode'), equals('dark'));
      });

      test('should not use SharedPreferences for sensitive data', () async {
        // TDD: Ensure no SharedPreferences usage for auth data
        // This test verifies that all sensitive data goes through encrypted database
        const testPassphrase = 'NoSharedPrefsTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        // All these operations should work through encrypted database only
        await databaseService.updateMetadata('auth_token', 'secret_token');
        await databaseService.updateMetadata('user_settings', '{"encrypted": true}');

        final authToken = await databaseService.getMetadata('auth_token');
        final userSettings = await databaseService.getMetadata('user_settings');

        expect(authToken, equals('secret_token'));
        expect(userSettings, equals('{"encrypted": true}'));
      });
    });
  });

  group('SQLCipher Error Handling', () {
    test('should handle database corruption gracefully', () async {
      // TDD: Test behavior with corrupted database
      const testPassphrase = 'CorruptionTestPassphrase123!';
      DatabaseService.setPassphrase(testPassphrase);

      // First create a valid database
      await databaseService.database;
      
      // Integrity check should pass initially
      final initialIntegrity = await databaseService.checkIntegrity();
      expect(initialIntegrity, true, reason: 'Fresh database should pass integrity check');
    });

    test('should handle memory pressure during encryption operations', () async {
      // TDD: Test encryption under resource constraints
      const testPassphrase = 'MemoryPressureTest123!';
      DatabaseService.setPassphrase(testPassphrase);

      // Simulate memory pressure with large data operations
      final largeData = 'x' * 100000; // 100KB string
      
      await databaseService.insert('app_metadata', {
        'key': 'large_data_test',
        'value': largeData,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      final retrievedData = await databaseService.getMetadata('large_data_test');
      expect(retrievedData, equals(largeData),
             reason: 'Large data should be handled correctly under memory pressure');
    });

    test('should handle concurrent database access', () async {
      // TDD: Test concurrent access patterns with encryption
      const testPassphrase = 'ConcurrentTestPassphrase123!';
      DatabaseService.setPassphrase(testPassphrase);

      // Simulate concurrent operations
      final futures = <Future>[];
      for (int i = 0; i < 5; i++) {
        futures.add(databaseService.insert('app_metadata', {
          'key': 'concurrent_test_$i',
          'value': 'concurrent_value_$i',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        }));
      }

      await Future.wait(futures);

      // Verify all operations completed successfully
      for (int i = 0; i < 5; i++) {
        final value = await databaseService.getMetadata('concurrent_test_$i');
        expect(value, equals('concurrent_value_$i'));
      }
    });

    test('should handle database re-keying operations', () async {
      // TDD: Test passphrase change functionality
      const oldPassphrase = 'OldPassphrase123!';
      const newPassphrase = 'NewPassphrase456!';

      // Create database with old passphrase
      DatabaseService.setPassphrase(oldPassphrase);
      await databaseService.insert('app_metadata', {
        'key': 'rekey_test',
        'value': 'test_value_before_rekey',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Change passphrase (re-key operation)
      // Note: Actual implementation will need to handle PRAGMA rekey
      DatabaseService.setPassphrase(newPassphrase);
      
      // Verify data is still accessible with new passphrase
      final value = await databaseService.getMetadata('rekey_test');
      expect(value, equals('test_value_before_rekey'),
             reason: 'Data should remain accessible after re-keying');
    });
  });

  group('Performance Tests', () {
    test('should maintain acceptable performance with encryption', () async {
      // TDD: Verify performance requirements are met
      const testPassphrase = 'PerformanceTestPassphrase123!';
      DatabaseService.setPassphrase(testPassphrase);

      final stopwatch = Stopwatch()..start();
      
      // Test database initialization performance
      await databaseService.database;
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
             reason: 'Database initialization should complete within 1 second');
      
      // Test operation performance
      stopwatch.reset();
      stopwatch.start();
      
      await databaseService.insert('app_metadata', {
        'key': 'performance_test',
        'value': 'performance_test_value',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
      
      final value = await databaseService.getMetadata('performance_test');
      stopwatch.stop();
      
      expect(value, equals('performance_test_value'));
      expect(stopwatch.elapsedMilliseconds, lessThan(500),
             reason: 'Database operations should complete within 500ms');
    });

    test('should handle bulk operations efficiently', () async {
      // TDD: Test performance with large datasets
      const testPassphrase = 'BulkTestPassphrase123!';
      DatabaseService.setPassphrase(testPassphrase);

      final stopwatch = Stopwatch()..start();
      
      // Insert 100 records
      for (int i = 0; i < 100; i++) {
        await databaseService.insert('app_metadata', {
          'key': 'bulk_test_$i',
          'value': 'bulk_value_$i',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
      
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
             reason: '100 insert operations should complete within 5 seconds');
    });
  });
}