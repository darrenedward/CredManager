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

  group('SQLCipher Error Handling and Edge Cases', () {
    group('Database Corruption Handling', () {
      test('should detect database corruption gracefully', () async {
        // TDD: Test behavior with corrupted SQLCipher database
        const testPassphrase = 'CorruptionDetectionTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        // Create a valid database first
        await databaseService.database;
        await databaseService.insert('app_metadata', {
          'key': 'corruption_test',
          'value': 'original_value',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
        await databaseService.close();

        // Simulate corruption by writing invalid data to the database file
        final dbPath = await databaseService.getDatabasePath();
        final dbFile = File(dbPath);
        
        // Corrupt the database by overwriting part of it
        final randomAccess = await dbFile.open(mode: FileMode.writeOnlyAppend);
        await randomAccess.writeFrom(Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]));
        await randomAccess.close();

        // Attempt to open corrupted database
        expect(() async {
          DatabaseService.setPassphrase(testPassphrase);
          await databaseService.database;
        }, throwsA(isA<DatabaseException>()),
               reason: 'Corrupted database should throw DatabaseException');
      });

      test('should handle integrity check failures', () async {
        // TDD: Test integrity check with corrupted data
        const testPassphrase = 'IntegrityCheckTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        // Create database and add data
        await databaseService.database;
        await databaseService.insert('credentials', {
          'id': 'integrity-test-1',
          'project_id': 'test-project',
          'name': 'Integrity Test',
          'encrypted_value': 'test-value',
          'credential_type': 'api_key',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        // Initial integrity check should pass
        final initialIntegrity = await databaseService.checkIntegrity();
        expect(initialIntegrity, true, reason: 'Fresh database should pass integrity check');

        // Simulate integrity failure scenario
        final corruptionResult = await databaseService.simulateDatabaseCorruption();
        expect(corruptionResult.corruptionDetected, true);

        // Integrity check should now fail
        final corruptedIntegrity = await databaseService.checkIntegrity();
        expect(corruptedIntegrity, false, reason: 'Corrupted database should fail integrity check');
      });

      test('should recover from minor database corruption', () async {
        // TDD: Test automatic recovery mechanisms
        const testPassphrase = 'RecoveryTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        // Create database with data
        await databaseService.database;
        const originalData = 'recovery_test_data';
        await databaseService.updateMetadata('recovery_test', originalData);

        // Simulate minor corruption
        await databaseService.simulateMinorCorruption();

        // Attempt recovery
        final recoveryResult = await databaseService.attemptDatabaseRecovery();
        expect(recoveryResult.recoverySuccessful, true, 
               reason: 'Minor corruption should be recoverable');

        // Verify data integrity after recovery
        final recoveredData = await databaseService.getMetadata('recovery_test');
        expect(recoveredData, equals(originalData),
               reason: 'Data should be intact after recovery');
      });

      test('should handle severe corruption with user notification', () async {
        // TDD: Test handling of unrecoverable corruption
        const testPassphrase = 'SevereCorruptionTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        // Create database
        await databaseService.database;
        await databaseService.close();

        // Simulate severe corruption
        await databaseService.simulateSevereCorruption();

        // Attempt to open corrupted database
        expect(() async {
          await databaseService.database;
        }, throwsA(predicate((e) => 
          e is DatabaseCorruptionException && 
          e.severity == CorruptionSeverity.severe
        )), reason: 'Severe corruption should throw specific exception');
      });
    });

    group('Memory and Resource Constraints', () {
      test('should handle low memory conditions gracefully', () async {
        // TDD: Test behavior under memory pressure
        const testPassphrase = 'LowMemoryTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database;

        // Simulate low memory condition
        await databaseService.simulateLowMemoryCondition();

        // Operations should still work but may be slower
        final stopwatch = Stopwatch()..start();
        
        await databaseService.insert('credentials', {
          'id': 'low-memory-test',
          'project_id': 'memory-test',
          'name': 'Low Memory Test',
          'encrypted_value': 'A' * 10000, // 10KB data
          'credential_type': 'api_key',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        stopwatch.stop();

        // Should complete within reasonable time even under memory pressure
        expect(stopwatch.elapsedMilliseconds, lessThan(5000),
               reason: 'Operations should complete within 5 seconds under memory pressure');

        // Verify data integrity
        final results = await databaseService.query('credentials',
                                                   where: 'id = ?',
                                                   whereArgs: ['low-memory-test']);
        expect(results.length, equals(1));
      });

      test('should handle disk space exhaustion', () async {
        // TDD: Test behavior when disk space is low
        const testPassphrase = 'DiskSpaceTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database;

        // Simulate disk space exhaustion
        await databaseService.simulateDiskSpaceExhaustion();

        // Attempt large insert that would exceed available space
        expect(() async {
          await databaseService.insert('credentials', {
            'id': 'large-insert-test',
            'project_id': 'disk-test',
            'name': 'Large Insert Test',
            'encrypted_value': 'X' * 1000000, // 1MB data
            'credential_type': 'large_data',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
        }, throwsA(isA<DatabaseException>()),
               reason: 'Disk space exhaustion should throw DatabaseException');
      });

      test('should clean up resources on operation failure', () async {
        // TDD: Test resource cleanup after failures
        const testPassphrase = 'ResourceCleanupTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database;

        // Force an operation to fail
        expect(() async {
          await databaseService.transaction((txn) async {
            await txn.insert('credentials', {
              'id': 'cleanup-test-1',
              'project_id': 'cleanup-project',
              'name': 'Cleanup Test',
              'encrypted_value': 'test-value',
              'credential_type': 'api_key',
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            });

            // Force failure
            throw DatabaseException('Simulated failure');
          });
        }, throwsA(isA<DatabaseException>()));

        // Database should still be usable after failure
        await databaseService.insert('credentials', {
          'id': 'cleanup-test-2',
          'project_id': 'cleanup-project',
          'name': 'Post-Failure Test',
          'encrypted_value': 'post-failure-value',
          'credential_type': 'api_key',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        // Verify only successful operation was committed
        final results = await databaseService.query('credentials',
                                                   where: 'project_id = ?',
                                                   whereArgs: ['cleanup-project']);
        expect(results.length, equals(1));
        expect(results.first['id'], equals('cleanup-test-2'));
      });
    });

    group('Concurrent Access and Locking', () {
      test('should handle concurrent database access properly', () async {
        // TDD: Test concurrent access patterns
        const testPassphrase = 'ConcurrentAccessTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database;

        final futures = <Future>[];
        final results = <String>[];

        // Start multiple concurrent operations
        for (int i = 0; i < 10; i++) {
          futures.add(() async {
            try {
              await databaseService.insert('app_metadata', {
                'key': 'concurrent_test_$i',
                'value': 'concurrent_value_$i',
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              });
              results.add('success_$i');
            } catch (e) {
              results.add('error_$i: $e');
            }
          }());
        }

        await Future.wait(futures);

        // All operations should succeed
        expect(results.length, equals(10));
        expect(results.where((r) => r.startsWith('success')).length, equals(10),
               reason: 'All concurrent operations should succeed');

        // Verify all data was inserted
        for (int i = 0; i < 10; i++) {
          final value = await databaseService.getMetadata('concurrent_test_$i');
          expect(value, equals('concurrent_value_$i'));
        }
      });

      test('should handle database locking conflicts', () async {
        // TDD: Test locking mechanism behavior
        const testPassphrase = 'LockingConflictTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database;

        // Start a long-running transaction
        final longTransaction = databaseService.transaction((txn) async {
          for (int i = 0; i < 100; i++) {
            await txn.insert('credentials', {
              'id': 'lock-test-$i',
              'project_id': 'lock-project',
              'name': 'Lock Test $i',
              'encrypted_value': 'lock-value-$i',
              'credential_type': 'api_key',
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            });
            
            // Small delay to extend transaction time
            await Future.delayed(Duration(milliseconds: 10));
          }
        });

        // Try to access database during transaction
        final quickOperation = () async {
          await databaseService.updateMetadata('quick_test', 'quick_value');
        };

        // Both operations should complete successfully
        await Future.wait([longTransaction, quickOperation()]);

        // Verify both operations succeeded
        final credCount = await databaseService.rawQuery('SELECT COUNT(*) as count FROM credentials');
        expect(credCount.first['count'], equals(100));

        final quickValue = await databaseService.getMetadata('quick_test');
        expect(quickValue, equals('quick_value'));
      });

      test('should detect and resolve deadlock situations', () async {
        // TDD: Test deadlock detection and resolution
        const testPassphrase = 'DeadlockTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database;

        // Create potential deadlock scenario
        final transaction1 = databaseService.transaction((txn) async {
          await txn.insert('projects', {
            'id': 'deadlock-project-1',
            'name': 'Deadlock Test 1',
            'description': 'First transaction',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });

          // Delay to create potential deadlock
          await Future.delayed(Duration(milliseconds: 100));

          await txn.insert('credentials', {
            'id': 'deadlock-cred-1',
            'project_id': 'deadlock-project-1',
            'name': 'Deadlock Credential 1',
            'encrypted_value': 'deadlock-value-1',
            'credential_type': 'api_key',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
        });

        final transaction2 = databaseService.transaction((txn) async {
          await txn.insert('credentials', {
            'id': 'deadlock-cred-2',
            'project_id': 'deadlock-project-2',
            'name': 'Deadlock Credential 2',
            'encrypted_value': 'deadlock-value-2',
            'credential_type': 'api_key',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });

          // Delay to create potential deadlock
          await Future.delayed(Duration(milliseconds: 100));

          await txn.insert('projects', {
            'id': 'deadlock-project-2',
            'name': 'Deadlock Test 2',
            'description': 'Second transaction',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
        });

        // Both transactions should complete without deadlock
        await Future.wait([transaction1, transaction2]);

        // Verify both transactions completed
        final projectCount = await databaseService.rawQuery('SELECT COUNT(*) as count FROM projects');
        final credentialCount = await databaseService.rawQuery('SELECT COUNT(*) as count FROM credentials');

        expect(projectCount.first['count'], equals(2));
        expect(credentialCount.first['count'], equals(2));
      });
    });

    group('Encryption Key and Passphrase Errors', () {
      test('should handle incorrect passphrase gracefully', () async {
        // TDD: Test wrong passphrase behavior
        const correctPassphrase = 'CorrectPassphrase123!';
        const wrongPassphrase = 'WrongPassphrase456!';

        // Create database with correct passphrase
        DatabaseService.setPassphrase(correctPassphrase);
        await databaseService.database;
        await databaseService.updateMetadata('passphrase_test', 'secret_data');
        await databaseService.close();

        // Try to open with wrong passphrase
        DatabaseService.setPassphrase(wrongPassphrase);
        
        expect(() async => await databaseService.database,
               throwsA(isA<DatabaseException>()),
               reason: 'Wrong passphrase should be rejected');
      });

      test('should handle passphrase change during operation', () async {
        // TDD: Test behavior when passphrase changes mid-session
        const originalPassphrase = 'OriginalPassphrase123!';
        const newPassphrase = 'NewPassphrase456!';

        DatabaseService.setPassphrase(originalPassphrase);
        await databaseService.database;

        // Insert data with original passphrase
        await databaseService.updateMetadata('rekey_test', 'original_data');

        // Change passphrase (this should trigger re-keying)
        final rekeyResult = await databaseService.changePassphrase(newPassphrase);
        expect(rekeyResult.success, true, reason: 'Passphrase change should succeed');

        // Verify data is still accessible with new passphrase
        DatabaseService.setPassphrase(newPassphrase);
        await databaseService.close(); // Force reconnection
        
        final data = await databaseService.getMetadata('rekey_test');
        expect(data, equals('original_data'),
               reason: 'Data should be accessible after passphrase change');
      });

      test('should handle corrupted encryption keys', () async {
        // TDD: Test behavior with corrupted key material
        const testPassphrase = 'CorruptedKeyTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database;
        await databaseService.updateMetadata('key_corruption_test', 'sensitive_data');

        // Simulate key corruption
        await databaseService.simulateKeyCorruption();

        // Attempt to access data with corrupted key
        expect(() async => await databaseService.getMetadata('key_corruption_test'),
               throwsA(isA<EncryptionException>()),
               reason: 'Corrupted key should throw EncryptionException');
      });

      test('should handle key derivation failures', () async {
        // TDD: Test Argon2 key derivation error handling
        const testPassphrase = 'KeyDerivationFailureTest123!';

        // Simulate key derivation failure
        await argon2Service.simulateDerivationFailure();

        expect(() async {
          DatabaseService.setPassphrase(testPassphrase);
          await databaseService.database;
        }, throwsA(isA<KeyDerivationException>()),
               reason: 'Key derivation failure should throw KeyDerivationException');
      });
    });

    group('Data Validation and Integrity Errors', () {
      test('should validate data types and constraints', () async {
        // TDD: Test data validation during insertion
        const testPassphrase = 'DataValidationTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database;

        // Test invalid foreign key constraint
        expect(() async {
          await databaseService.insert('credentials', {
            'id': 'invalid-fk-test',
            'project_id': 'non-existent-project', // Invalid foreign key
            'name': 'Invalid FK Test',
            'encrypted_value': 'test-value',
            'credential_type': 'api_key',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
        }, throwsA(isA<DatabaseException>()),
               reason: 'Invalid foreign key should be rejected');

        // Test null constraint violation
        expect(() async {
          await databaseService.insert('projects', {
            'id': 'null-constraint-test',
            'name': null, // NOT NULL constraint violation
            'description': 'Test project',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
        }, throwsA(isA<DatabaseException>()),
               reason: 'NULL constraint violation should be rejected');
      });

      test('should handle malformed encrypted data', () async {
        // TDD: Test handling of corrupted encrypted values
        const testPassphrase = 'MalformedDataTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database;

        // Insert valid data first
        await databaseService.insert('credentials', {
          'id': 'malformed-test',
          'project_id': 'test-project',
          'name': 'Malformed Test',
          'encrypted_value': 'valid-encrypted-value',
          'credential_type': 'api_key',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        // Simulate data corruption in storage
        await databaseService.simulateDataCorruption('malformed-test');

        // Attempt to read corrupted data
        expect(() async {
          await databaseService.query('credentials',
                                     where: 'id = ?',
                                     whereArgs: ['malformed-test']);
        }, throwsA(isA<DataCorruptionException>()),
               reason: 'Corrupted encrypted data should throw DataCorruptionException');
      });

      test('should detect and handle schema mismatches', () async {
        // TDD: Test behavior with incompatible schema versions
        const testPassphrase = 'SchemaMismatchTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        // Create database with current schema
        await databaseService.database;
        await databaseService.close();

        // Simulate schema version mismatch
        await databaseService.simulateSchemaVersionMismatch();

        // Attempt to open database with mismatched schema
        expect(() async => await databaseService.database,
               throwsA(isA<SchemaMismatchException>()),
               reason: 'Schema version mismatch should throw SchemaMismatchException');
      });
    });

    group('Network and File System Errors', () {
      test('should handle file system permission errors', () async {
        // TDD: Test behavior with insufficient file permissions
        const testPassphrase = 'PermissionErrorTest123!';
        
        // Simulate permission error
        await databaseService.simulatePermissionError();

        expect(() async {
          DatabaseService.setPassphrase(testPassphrase);
          await databaseService.database;
        }, throwsA(isA<FileSystemException>()),
               reason: 'Permission error should throw FileSystemException');
      });

      test('should handle database file deletion during operation', () async {
        // TDD: Test behavior when database file is externally deleted
        const testPassphrase = 'FileDeletionTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        // Create and use database
        await databaseService.database;
        await databaseService.updateMetadata('deletion_test', 'test_data');

        // Simulate external file deletion
        final dbPath = await databaseService.getDatabasePath();
        final dbFile = File(dbPath);
        await dbFile.delete();

        // Attempt database operation after file deletion
        expect(() async => await databaseService.getMetadata('deletion_test'),
               throwsA(isA<DatabaseException>()),
               reason: 'Missing database file should throw DatabaseException');
      });

      test('should handle temporary file system failures', () async {
        // TDD: Test resilience to temporary file system issues
        const testPassphrase = 'TempFailureTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database;

        // Simulate temporary file system failure
        await databaseService.simulateTemporaryFileSystemFailure();

        // Operations should eventually succeed after retry
        final retryResult = await databaseService.updateMetadataWithRetry(
          'temp_failure_test', 
          'recovered_data',
          maxRetries: 3
        );

        expect(retryResult.success, true, 
               reason: 'Operations should succeed after temporary failure recovery');
        expect(retryResult.attemptsRequired, greaterThan(1),
               reason: 'Should require multiple attempts after temporary failure');
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      test('should handle extremely large database operations', () async {
        // TDD: Test behavior at scale limits
        const testPassphrase = 'LargeOperationTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database;

        // Test with very large single record
        final largeValue = 'X' * (1024 * 1024); // 1MB string
        
        final stopwatch = Stopwatch()..start();
        
        await databaseService.insert('credentials', {
          'id': 'large-record-test',
          'project_id': 'large-test',
          'name': 'Large Record Test',
          'encrypted_value': largeValue,
          'credential_type': 'large_data',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(10000),
               reason: '1MB record should be processed within 10 seconds');

        // Verify data integrity
        final results = await databaseService.query('credentials',
                                                   where: 'id = ?',
                                                   whereArgs: ['large-record-test']);
        expect(results.first['encrypted_value'], equals(largeValue));
      });

      test('should handle special characters and encoding edge cases', () async {
        // TDD: Test Unicode and special character handling
        const testPassphrase = 'SpecialCharsTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database;

        final specialCharTests = [
          'Unicode: 🔐🗝️🛡️ Пароль ñáéíóú',
          'Emojis: 😀😃😄😁😆😅😂🤣',
          'Control chars: \n\r\t\x00\x01\x02',
          'SQL injection: \'; DROP TABLE credentials; --',
          'Null bytes: \x00\x00\x00',
          'Mixed encoding: UTF-8 Москва ελληνικά 中文',
        ];

        for (int i = 0; i < specialCharTests.length; i++) {
          final testValue = specialCharTests[i];
          
          await databaseService.insert('app_metadata', {
            'key': 'special_char_test_$i',
            'value': testValue,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });

          final retrievedValue = await databaseService.getMetadata('special_char_test_$i');
          expect(retrievedValue, equals(testValue),
                 reason: 'Special characters should be preserved: $testValue');
        }
      });

      test('should handle empty and null data appropriately', () async {
        // TDD: Test boundary conditions with empty data
        const testPassphrase = 'EmptyDataTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database;

        // Test empty string
        await databaseService.updateMetadata('empty_string_test', '');
        final emptyResult = await databaseService.getMetadata('empty_string_test');
        expect(emptyResult, equals(''));

        // Test null handling
        expect(() async {
          await databaseService.updateMetadata('null_test', null);
        }, throwsArgumentError, reason: 'Null values should be rejected');

        // Test very long keys
        final longKey = 'very_long_key_' + 'x' * 1000;
        await databaseService.updateMetadata(longKey, 'long_key_value');
        final longKeyResult = await databaseService.getMetadata(longKey);
        expect(longKeyResult, equals('long_key_value'));
      });

      test('should handle rapid database state changes', () async {
        // TDD: Test rapid open/close/reopen cycles
        const testPassphrase = 'RapidStateChangeTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        for (int i = 0; i < 10; i++) {
          // Open database
          await databaseService.database;
          
          // Perform operation
          await databaseService.updateMetadata('rapid_test_$i', 'value_$i');
          
          // Close database
          await databaseService.close();
          
          // Small delay
          await Future.delayed(Duration(milliseconds: 10));
        }

        // Verify all operations persisted
        await databaseService.database;
        for (int i = 0; i < 10; i++) {
          final value = await databaseService.getMetadata('rapid_test_$i');
          expect(value, equals('value_$i'));
        }
      });
    });
  });
}

// Custom exception classes for testing
class DatabaseCorruptionException implements Exception {
  final String message;
  final CorruptionSeverity severity;
  
  DatabaseCorruptionException(this.message, this.severity);
}

class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);
}

class KeyDerivationException implements Exception {
  final String message;
  KeyDerivationException(this.message);
}

class DataCorruptionException implements Exception {
  final String message;
  DataCorruptionException(this.message);
}

class SchemaMismatchException implements Exception {
  final String message;
  SchemaMismatchException(this.message);
}

enum CorruptionSeverity { minor, moderate, severe }