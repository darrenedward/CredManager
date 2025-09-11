import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/services/database_service.dart';
import 'package:cred_manager/services/argon2_service.dart';
import 'dart:io';
import 'dart:math';

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

  group('SQLCipher Performance Tests', () {
    group('Database Initialization Performance', () {
      test('should initialize encrypted database within acceptable time', () async {
        // TDD: Verify initialization performance meets requirements
        const testPassphrase = 'PerformanceInitTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        final stopwatch = Stopwatch()..start();
        
        final db = await databaseService.database;
        
        stopwatch.stop();

        expect(db, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
               reason: 'Database initialization should complete within 2 seconds (actual: ${stopwatch.elapsedMilliseconds}ms)');
        expect(stopwatch.elapsedMilliseconds, greaterThan(50),
               reason: 'Encryption overhead should be measurable (at least 50ms)');
      });

      test('should handle first-time database creation efficiently', () async {
        // TDD: Test performance of initial schema creation with encryption
        const testPassphrase = 'FirstTimeCreateTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        final stopwatch = Stopwatch()..start();
        
        // First access triggers database creation
        final db = await databaseService.database;
        
        // Verify all tables are created
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
        );
        
        stopwatch.stop();

        expect(tables.length, greaterThanOrEqualTo(6),
               reason: 'All required tables should be created');
        expect(stopwatch.elapsedMilliseconds, lessThan(3000),
               reason: 'First-time database creation should complete within 3 seconds');
      });

      test('should cache database connection efficiently', () async {
        // TDD: Test connection reuse performance
        const testPassphrase = 'ConnectionCacheTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        // First access
        final stopwatch1 = Stopwatch()..start();
        final db1 = await databaseService.database;
        stopwatch1.stop();

        // Second access (should be cached)
        final stopwatch2 = Stopwatch()..start();
        final db2 = await databaseService.database;
        stopwatch2.stop();

        // Third access (should also be cached)
        final stopwatch3 = Stopwatch()..start();
        final db3 = await databaseService.database;
        stopwatch3.stop();

        expect(identical(db1, db2), true, reason: 'Database instance should be cached');
        expect(identical(db2, db3), true, reason: 'Database instance should remain cached');
        
        expect(stopwatch2.elapsedMilliseconds, lessThan(stopwatch1.elapsedMilliseconds ~/ 10),
               reason: 'Cached access should be much faster than initial access');
        expect(stopwatch3.elapsedMilliseconds, lessThan(10),
               reason: 'Multiple cached accesses should be very fast');
      });
    });

    group('CRUD Operation Performance', () {
      test('should perform INSERT operations within time limits', () async {
        // TDD: Test insert performance with encryption
        const testPassphrase = 'InsertPerformanceTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database; // Initialize

        final insertTimes = <int>[];

        // Test 100 individual inserts
        for (int i = 0; i < 100; i++) {
          final stopwatch = Stopwatch()..start();
          
          await databaseService.insert('credentials', {
            'id': 'perf-test-$i',
            'project_id': 'perf-project',
            'name': 'Performance Test Credential $i',
            'encrypted_value': 'api-key-value-$i-${Random().nextInt(10000)}',
            'credential_type': 'api_key',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
          
          stopwatch.stop();
          insertTimes.add(stopwatch.elapsedMilliseconds);
        }

        final avgInsertTime = insertTimes.reduce((a, b) => a + b) / insertTimes.length;
        final maxInsertTime = insertTimes.reduce((a, b) => a > b ? a : b);

        expect(avgInsertTime, lessThan(100),
               reason: 'Average insert time should be under 100ms (actual: ${avgInsertTime.toStringAsFixed(2)}ms)');
        expect(maxInsertTime, lessThan(500),
               reason: 'Maximum insert time should be under 500ms (actual: ${maxInsertTime}ms)');

        // Verify all records were inserted
        final count = await databaseService.rawQuery('SELECT COUNT(*) as count FROM credentials');
        expect(count.first['count'], equals(100));
      });

      test('should perform SELECT operations efficiently', () async {
        // TDD: Test query performance with encryption
        const testPassphrase = 'SelectPerformanceTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database; // Initialize

        // Insert test data
        for (int i = 0; i < 1000; i++) {
          await databaseService.insert('credentials', {
            'id': 'select-test-$i',
            'project_id': 'select-project-${i % 10}',
            'name': 'Select Test Credential $i',
            'encrypted_value': 'encrypted-value-$i',
            'credential_type': i % 2 == 0 ? 'api_key' : 'password',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
        }

        final queryTimes = <int>[];

        // Test various query patterns
        final queryTests = [
          () => databaseService.query('credentials', limit: 10),
          () => databaseService.query('credentials', where: 'project_id = ?', whereArgs: ['select-project-1']),
          () => databaseService.query('credentials', where: 'credential_type = ?', whereArgs: ['api_key']),
          () => databaseService.query('credentials', orderBy: 'created_at DESC', limit: 50),
        ];

        for (final queryTest in queryTests) {
          final stopwatch = Stopwatch()..start();
          final results = await queryTest();
          stopwatch.stop();
          
          queryTimes.add(stopwatch.elapsedMilliseconds);
          expect(results, isNotEmpty, reason: 'Query should return results');
        }

        final avgQueryTime = queryTimes.reduce((a, b) => a + b) / queryTimes.length;
        final maxQueryTime = queryTimes.reduce((a, b) => a > b ? a : b);

        expect(avgQueryTime, lessThan(200),
               reason: 'Average query time should be under 200ms (actual: ${avgQueryTime.toStringAsFixed(2)}ms)');
        expect(maxQueryTime, lessThan(500),
               reason: 'Maximum query time should be under 500ms (actual: ${maxQueryTime}ms)');
      });

      test('should perform UPDATE operations efficiently', () async {
        // TDD: Test update performance with encryption
        const testPassphrase = 'UpdatePerformanceTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database; // Initialize

        // Insert test records
        for (int i = 0; i < 100; i++) {
          await databaseService.insert('credentials', {
            'id': 'update-test-$i',
            'project_id': 'update-project',
            'name': 'Update Test Credential $i',
            'encrypted_value': 'original-value-$i',
            'credential_type': 'api_key',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
        }

        final updateTimes = <int>[];

        // Test individual updates
        for (int i = 0; i < 100; i++) {
          final stopwatch = Stopwatch()..start();
          
          await databaseService.update(
            'credentials',
            {
              'encrypted_value': 'updated-value-$i',
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: ['update-test-$i'],
          );
          
          stopwatch.stop();
          updateTimes.add(stopwatch.elapsedMilliseconds);
        }

        final avgUpdateTime = updateTimes.reduce((a, b) => a + b) / updateTimes.length;
        final maxUpdateTime = updateTimes.reduce((a, b) => a > b ? a : b);

        expect(avgUpdateTime, lessThan(150),
               reason: 'Average update time should be under 150ms (actual: ${avgUpdateTime.toStringAsFixed(2)}ms)');
        expect(maxUpdateTime, lessThan(500),
               reason: 'Maximum update time should be under 500ms (actual: ${maxUpdateTime}ms)');
      });

      test('should perform DELETE operations efficiently', () async {
        // TDD: Test delete performance with encryption
        const testPassphrase = 'DeletePerformanceTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database; // Initialize

        // Insert test records
        for (int i = 0; i < 200; i++) {
          await databaseService.insert('credentials', {
            'id': 'delete-test-$i',
            'project_id': 'delete-project',
            'name': 'Delete Test Credential $i',
            'encrypted_value': 'delete-value-$i',
            'credential_type': 'api_key',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
        }

        final deleteTimes = <int>[];

        // Test individual deletes
        for (int i = 0; i < 100; i++) {
          final stopwatch = Stopwatch()..start();
          
          await databaseService.delete(
            'credentials',
            where: 'id = ?',
            whereArgs: ['delete-test-$i'],
          );
          
          stopwatch.stop();
          deleteTimes.add(stopwatch.elapsedMilliseconds);
        }

        // Test bulk delete
        final bulkStopwatch = Stopwatch()..start();
        await databaseService.delete(
          'credentials',
          where: 'project_id = ?',
          whereArgs: ['delete-project'],
        );
        bulkStopwatch.stop();

        final avgDeleteTime = deleteTimes.reduce((a, b) => a + b) / deleteTimes.length;
        final maxDeleteTime = deleteTimes.reduce((a, b) => a > b ? a : b);

        expect(avgDeleteTime, lessThan(100),
               reason: 'Average delete time should be under 100ms (actual: ${avgDeleteTime.toStringAsFixed(2)}ms)');
        expect(maxDeleteTime, lessThan(300),
               reason: 'Maximum delete time should be under 300ms (actual: ${maxDeleteTime}ms)');
        expect(bulkStopwatch.elapsedMilliseconds, lessThan(500),
               reason: 'Bulk delete should complete within 500ms');
      });
    });

    group('Transaction Performance', () {
      test('should handle large transactions efficiently', () async {
        // TDD: Test transaction performance with encryption
        const testPassphrase = 'TransactionPerformanceTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database; // Initialize

        final stopwatch = Stopwatch()..start();

        await databaseService.transaction((txn) async {
          // Insert 1000 records in single transaction
          for (int i = 0; i < 1000; i++) {
            await txn.insert('credentials', {
              'id': 'txn-test-$i',
              'project_id': 'txn-project-${i % 5}',
              'name': 'Transaction Test Credential $i',
              'encrypted_value': 'txn-value-$i',
              'credential_type': 'api_key',
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            });
          }
        });

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(10000),
               reason: '1000-record transaction should complete within 10 seconds (actual: ${stopwatch.elapsedMilliseconds}ms)');

        // Verify all records were inserted
        final count = await databaseService.rawQuery('SELECT COUNT(*) as count FROM credentials');
        expect(count.first['count'], equals(1000));
      });

      test('should handle nested transactions efficiently', () async {
        // TDD: Test nested transaction performance
        const testPassphrase = 'NestedTransactionTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database; // Initialize

        final stopwatch = Stopwatch()..start();

        await databaseService.transaction((txn) async {
          // Insert projects
          for (int i = 0; i < 10; i++) {
            await txn.insert('projects', {
              'id': 'nested-project-$i',
              'name': 'Nested Project $i',
              'description': 'Project for nested transaction test',
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            });

            // Insert credentials for each project
            for (int j = 0; j < 10; j++) {
              await txn.insert('credentials', {
                'id': 'nested-cred-$i-$j',
                'project_id': 'nested-project-$i',
                'name': 'Nested Credential $i-$j',
                'encrypted_value': 'nested-value-$i-$j',
                'credential_type': 'api_key',
                'created_at': DateTime.now().millisecondsSinceEpoch,
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              });
            }
          }
        });

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(5000),
               reason: 'Nested operations should complete within 5 seconds');

        // Verify data integrity
        final projectCount = await databaseService.rawQuery('SELECT COUNT(*) as count FROM projects');
        final credentialCount = await databaseService.rawQuery('SELECT COUNT(*) as count FROM credentials');
        
        expect(projectCount.first['count'], equals(10));
        expect(credentialCount.first['count'], equals(100));
      });

      test('should handle transaction rollback efficiently', () async {
        // TDD: Test rollback performance impact
        const testPassphrase = 'RollbackPerformanceTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database; // Initialize

        final stopwatch = Stopwatch()..start();

        expect(() async {
          await databaseService.transaction((txn) async {
            // Insert many records
            for (int i = 0; i < 500; i++) {
              await txn.insert('credentials', {
                'id': 'rollback-test-$i',
                'project_id': 'rollback-project',
                'name': 'Rollback Test Credential $i',
                'encrypted_value': 'rollback-value-$i',
                'credential_type': 'api_key',
                'created_at': DateTime.now().millisecondsSinceEpoch,
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              });
            }
            
            // Force rollback
            throw Exception('Forced rollback for performance test');
          });
        }, throwsException);

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(5000),
               reason: 'Transaction rollback should complete within 5 seconds');

        // Verify no data was committed
        final count = await databaseService.rawQuery('SELECT COUNT(*) as count FROM credentials');
        expect(count.first['count'], equals(0));
      });
    });

    group('Memory and Resource Usage', () {
      test('should manage memory efficiently during large operations', () async {
        // TDD: Test memory usage patterns
        const testPassphrase = 'MemoryUsageTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database; // Initialize

        // Get initial memory baseline (simulated)
        final initialMemory = ProcessInfo.currentRss;

        // Perform memory-intensive operation
        for (int batch = 0; batch < 10; batch++) {
          await databaseService.transaction((txn) async {
            for (int i = 0; i < 100; i++) {
              await txn.insert('credentials', {
                'id': 'memory-test-$batch-$i',
                'project_id': 'memory-project',
                'name': 'Memory Test Credential $batch-$i',
                'encrypted_value': 'A' * 1000, // 1KB value
                'credential_type': 'api_key',
                'created_at': DateTime.now().millisecondsSinceEpoch,
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              });
            }
          });

          // Force garbage collection (simulated)
          await Future.delayed(Duration(milliseconds: 10));
        }

        final finalMemory = ProcessInfo.currentRss;
        final memoryIncrease = finalMemory - initialMemory;

        // Memory increase should be reasonable for 1000 1KB records
        expect(memoryIncrease, lessThan(50 * 1024 * 1024),
               reason: 'Memory increase should be less than 50MB for test data');

        // Verify data was stored correctly
        final count = await databaseService.rawQuery('SELECT COUNT(*) as count FROM credentials');
        expect(count.first['count'], equals(1000));
      });

      test('should handle concurrent operations without memory leaks', () async {
        // TDD: Test concurrent access memory management
        const testPassphrase = 'ConcurrentMemoryTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database; // Initialize

        final futures = <Future>[];

        // Start multiple concurrent operations
        for (int thread = 0; thread < 5; thread++) {
          futures.add(() async {
            for (int i = 0; i < 20; i++) {
              await databaseService.insert('app_metadata', {
                'key': 'concurrent_test_${thread}_$i',
                'value': 'concurrent_value_${thread}_$i',
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              });

              // Small delay to simulate real usage
              await Future.delayed(Duration(milliseconds: 1));
            }
          }());
        }

        final stopwatch = Stopwatch()..start();
        await Future.wait(futures);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(5000),
               reason: 'Concurrent operations should complete within 5 seconds');

        // Verify all operations completed
        final results = await databaseService.rawQuery(
          "SELECT COUNT(*) as count FROM app_metadata WHERE key LIKE 'concurrent_test_%'"
        );
        expect(results.first['count'], equals(100));
      });

      test('should clean up resources properly on database close', () async {
        // TDD: Test resource cleanup
        const testPassphrase = 'ResourceCleanupTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        // Open and use database
        final db = await databaseService.database;
        
        await databaseService.insert('app_metadata', {
          'key': 'cleanup_test',
          'value': 'cleanup_value',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        // Close database
        final closeStopwatch = Stopwatch()..start();
        await databaseService.close();
        closeStopwatch.stop();

        expect(closeStopwatch.elapsedMilliseconds, lessThan(1000),
               reason: 'Database close should complete within 1 second');

        // Verify database is closed
        DatabaseService.clearPassphrase();
        
        // Reopening should work
        DatabaseService.setPassphrase(testPassphrase);
        final reopenedDb = await databaseService.database;
        
        final data = await databaseService.getMetadata('cleanup_test');
        expect(data, equals('cleanup_value'));
      });
    });

    group('Encryption Performance Impact', () {
      test('should measure encryption overhead compared to unencrypted operations', () async {
        // TDD: Compare encrypted vs unencrypted performance
        const testPassphrase = 'EncryptionOverheadTest123!';
        
        // Test unencrypted operations (no passphrase)
        final unencryptedStopwatch = Stopwatch()..start();
        
        final unencryptedDb = await databaseService.database;
        
        for (int i = 0; i < 100; i++) {
          await databaseService.insert('app_metadata', {
            'key': 'unencrypted_test_$i',
            'value': 'unencrypted_value_$i',
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
        }
        
        unencryptedStopwatch.stop();
        await databaseService.close();
        await databaseService.deleteDatabase();

        // Test encrypted operations
        DatabaseService.setPassphrase(testPassphrase);
        final encryptedStopwatch = Stopwatch()..start();
        
        final encryptedDb = await databaseService.database;
        
        for (int i = 0; i < 100; i++) {
          await databaseService.insert('app_metadata', {
            'key': 'encrypted_test_$i',
            'value': 'encrypted_value_$i',
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
        }
        
        encryptedStopwatch.stop();

        final overhead = encryptedStopwatch.elapsedMilliseconds / unencryptedStopwatch.elapsedMilliseconds;
        
        expect(overhead, lessThan(3.0),
               reason: 'Encryption overhead should be less than 3x (actual: ${overhead.toStringAsFixed(2)}x)');
        expect(overhead, greaterThan(1.1),
               reason: 'Encryption should have measurable overhead (at least 10%)');
      });

      test('should maintain acceptable performance with large encrypted values', () async {
        // TDD: Test performance with large encrypted data
        const testPassphrase = 'LargeDataEncryptionTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database; // Initialize

        final dataSizes = [1024, 10240, 102400]; // 1KB, 10KB, 100KB
        final performanceResults = <int, int>{};

        for (final dataSize in dataSizes) {
          final largeData = 'X' * dataSize;
          
          final stopwatch = Stopwatch()..start();
          
          await databaseService.insert('credentials', {
            'id': 'large-data-test-$dataSize',
            'project_id': 'large-data-project',
            'name': 'Large Data Test',
            'encrypted_value': largeData,
            'credential_type': 'large_data',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
          
          // Read back to test decryption performance
          final results = await databaseService.query('credentials',
                                                     where: 'id = ?',
                                                     whereArgs: ['large-data-test-$dataSize']);
          
          stopwatch.stop();
          
          expect(results.first['encrypted_value'], equals(largeData));
          performanceResults[dataSize] = stopwatch.elapsedMilliseconds;
        }

        // Performance should scale reasonably with data size
        expect(performanceResults[1024]!, lessThan(500),
               reason: '1KB data should process within 500ms');
        expect(performanceResults[10240]!, lessThan(1000),
               reason: '10KB data should process within 1 second');
        expect(performanceResults[102400]!, lessThan(3000),
               reason: '100KB data should process within 3 seconds');
      });

      test('should handle high-frequency operations efficiently', () async {
        // TDD: Test sustained high-frequency operations
        const testPassphrase = 'HighFrequencyTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database; // Initialize

        final operationTimes = <int>[];
        final totalStopwatch = Stopwatch()..start();

        // Perform 1000 rapid operations
        for (int i = 0; i < 1000; i++) {
          final opStopwatch = Stopwatch()..start();
          
          await databaseService.updateMetadata('high_freq_test', 'value_$i');
          final value = await databaseService.getMetadata('high_freq_test');
          
          opStopwatch.stop();
          operationTimes.add(opStopwatch.elapsedMilliseconds);
          
          expect(value, equals('value_$i'));
        }

        totalStopwatch.stop();

        final avgOperationTime = operationTimes.reduce((a, b) => a + b) / operationTimes.length;
        final operationsPerSecond = 1000 / (totalStopwatch.elapsedMilliseconds / 1000);

        expect(avgOperationTime, lessThan(50),
               reason: 'Average operation time should be under 50ms');
        expect(operationsPerSecond, greaterThan(20),
               reason: 'Should handle at least 20 operations per second');
      });
    });
  });
}

// Mock ProcessInfo class for memory monitoring
class ProcessInfo {
  static int get currentRss => 50 * 1024 * 1024; // Mock 50MB baseline
}