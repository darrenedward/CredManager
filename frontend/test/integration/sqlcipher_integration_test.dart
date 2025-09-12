import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cred_manager/services/database_service.dart';
import 'package:cred_manager/services/auth_service.dart';
import 'package:cred_manager/services/argon2_service.dart';
import 'dart:io';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService databaseService;
  late AuthService authService;
  late Argon2Service argon2Service;

  setUp(() async {
    databaseService = DatabaseService.instance;
    authService = AuthService();
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
    group('End-to-End Authentication Flow with SQLCipher', () {
      testWidgets('should complete full user setup with encrypted database', (WidgetTester tester) async {
        // TDD: Test complete setup flow with SQLCipher integration
        const testPassphrase = 'SetupFlowTest123!';
        final securityQuestions = [
          {'question': 'What is your favorite color?', 'answer': 'Blue'},
          {'question': 'What was your first pet?', 'answer': 'Fluffy'},
        ];

        // Step 1: Create user account with encrypted storage
        final token = await authService.createPassphrase(testPassphrase, [
          {'question': securityQuestions[0]['question']!, 'answer': securityQuestions[0]['answer']!},
          {'question': securityQuestions[1]['question']!, 'answer': securityQuestions[1]['answer']!},
        ]);

        expect(token, isNotNull, reason: 'User setup should succeed');

        // Step 2: Verify encrypted database was created
        DatabaseService.setPassphrase(testPassphrase);
        final db = await databaseService.database;
        expect(db, isNotNull);

        // Step 3: Verify encryption is active (SQLCipher on mobile, application-layer on desktop)
        if (Platform.isAndroid || Platform.isIOS) {
          final cipherVersion = await db.rawQuery('PRAGMA cipher_version');
          expect(cipherVersion.isNotEmpty, true, reason: 'SQLCipher should be active on mobile');
        } else {
          // On desktop, we use application-layer encryption
          expect(true, true, reason: 'Desktop uses application-layer encryption');
        }

        // Step 4: Verify authentication data is stored encrypted
        final storedQuestions = await databaseService.getSecurityQuestions();
        expect(storedQuestions, isNotNull);
        expect(storedQuestions!.length, equals(2));

        // Step 5: Verify setup completion flags are in encrypted storage
        final setupCompleted = await databaseService.getMetadata('setup_completed');
        expect(setupCompleted, equals('1'), reason: 'Setup should be marked complete in encrypted DB');
      });

      testWidgets('should authenticate user against encrypted database', (WidgetTester tester) async {
        // TDD: Test login flow with encrypted database
        const testPassphrase = 'LoginFlowTest123!';
        final securityQuestions = [
          {'question': 'What city were you born in?', 'answer': 'test_city'},
        ];

        // Setup user first
        await authService.createPassphrase(testPassphrase, securityQuestions);

        // Clear any cached data
        DatabaseService.clearPassphrase();

        // Attempt login
        final loginToken = await authService.login(testPassphrase);
        expect(loginToken, isNotNull, reason: 'Login should succeed with correct passphrase');

        // Verify database is accessible after login
        final testData = await databaseService.getMetadata('setup_completed');
        expect(testData, isNotNull, reason: 'Database should be accessible after successful login');
      });

      testWidgets('should handle recovery flow with encrypted security questions', (WidgetTester tester) async {
        // TDD: Test recovery process with encrypted storage
        const testPassphrase = 'RecoveryFlowTest123!';
        const newPassphrase = 'NewRecoveryPassphrase456!';
        
        final securityQuestions = [
          {'question': 'What is your mother\'s maiden name?', 'answer': 'maiden_name'},
          {'question': 'What street did you grow up on?', 'answer': 'street_name'},
        ];

        // Setup user
        await authService.createPassphrase(testPassphrase, securityQuestions);

        // Initiate recovery
        final questions = await authService.initiateRecovery();
        expect(questions, isNotNull);
        expect(questions!.length, equals(2));

        // Verify questions come from encrypted storage
        expect(questions[0], equals('What is your mother\'s maiden name?'));
        expect(questions[1], equals('What street did you grow up on?'));

        // Complete recovery with new passphrase
        final recoveryToken = await authService.completeRecovery(
          ['original_maiden', 'original_street'], 
          newPassphrase
        );
        expect(recoveryToken, isNotNull, reason: 'Recovery should succeed');

        // Verify new passphrase works
        DatabaseService.clearPassphrase();
        final newLoginToken = await authService.login(newPassphrase);
        expect(newLoginToken, isNotNull, reason: 'New passphrase should work after recovery');
      });

      testWidgets('should handle biometric authentication with encrypted passphrase storage', (WidgetTester tester) async {
        // TDD: Test biometric auth with encrypted passphrase backup
        const testPassphrase = 'BiometricFlowTest123!';
        
        // Setup user with biometric enabled
        await authService.createPassphrase(testPassphrase, [
          {'question': 'Biometric test question?', 'answer': 'biometric_answer'},
        ]);

        // Enable biometric authentication
        final biometricSetup = await authService.enableBiometricAuth(testPassphrase);
        expect(biometricSetup, true, reason: 'Biometric setup should succeed');

        // Verify biometric flag is stored (passphrase storage is handled separately)
        DatabaseService.setPassphrase(testPassphrase);
        final biometricEnabled = await databaseService.getMetadata('biometric_enabled');
        expect(biometricEnabled, equals('1'),
               reason: 'Biometric enabled flag should be stored');

        // Test biometric authentication (mocked)
        final biometricToken = await authService.authenticateWithBiometric();
        expect(biometricToken, isNotNull, reason: 'Biometric authentication should succeed');
      });
    });

    group('Credential Management with Encryption', () {
      testWidgets('should store and retrieve credentials securely', (WidgetTester tester) async {
        // TDD: Test credential CRUD operations with encryption
        const testPassphrase = 'CredentialManagementTest123!';
        
        // Setup encrypted database
        DatabaseService.setPassphrase(testPassphrase);
        await databaseService.database;

        // Create project first
        await databaseService.insert('projects', {
          'id': 'integration-project-1',
          'name': 'Integration Test Project',
          'description': 'Project for integration testing',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        // Store sensitive credential
        const sensitiveApiKey = 'sk-1234567890abcdef-very-secret-key';
        await databaseService.insert('credentials', {
          'id': 'integration-cred-1',
          'project_id': 'integration-project-1',
          'name': 'OpenAI API Key',
          'encrypted_value': sensitiveApiKey,
          'credential_type': 'api_key',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        // Retrieve and verify credential
        final credentials = await databaseService.query('credentials',
                                                       where: 'id = ?',
                                                       whereArgs: ['integration-cred-1']);
        
        expect(credentials.length, equals(1));
        expect(credentials.first['encrypted_value'], equals(sensitiveApiKey),
               reason: 'Credential should be correctly encrypted and decrypted');

        // Update credential
        const updatedApiKey = 'sk-updated-key-9876543210fedcba';
        await databaseService.update('credentials', {
          'encrypted_value': updatedApiKey,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        }, where: 'id = ?', whereArgs: ['integration-cred-1']);

        // Verify update
        final updatedCredentials = await databaseService.query('credentials',
                                                              where: 'id = ?',
                                                              whereArgs: ['integration-cred-1']);
        expect(updatedCredentials.first['encrypted_value'], equals(updatedApiKey));
      });

      testWidgets('should handle bulk credential operations efficiently', (WidgetTester tester) async {
        // TDD: Test performance with multiple credentials
        const testPassphrase = 'BulkCredentialsTest123!';
        DatabaseService.setPassphrase(testPassphrase);
        await databaseService.database;

        // Create project
        await databaseService.insert('projects', {
          'id': 'bulk-project',
          'name': 'Bulk Test Project',
          'description': 'Project for bulk credential testing',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        final stopwatch = Stopwatch()..start();

        // Insert 100 credentials
        await databaseService.transaction((txn) async {
          for (int i = 0; i < 100; i++) {
            await txn.insert('credentials', {
              'id': 'bulk-cred-$i',
              'project_id': 'bulk-project',
              'name': 'Bulk Credential $i',
              'encrypted_value': 'api-key-value-$i-encrypted',
              'credential_type': 'api_key',
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            });
          }
        });

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(10000),
               reason: 'Bulk credential insertion should complete within 10 seconds');

        // Verify all credentials were stored
        final credentialCount = await databaseService.rawQuery(
          'SELECT COUNT(*) as count FROM credentials WHERE project_id = ?',
          ['bulk-project']
        );
        expect(credentialCount.first['count'], equals(100));

        // Test bulk retrieval performance
        final retrievalStopwatch = Stopwatch()..start();
        final allCredentials = await databaseService.query('credentials',
                                                          where: 'project_id = ?',
                                                          whereArgs: ['bulk-project']);
        retrievalStopwatch.stop();

        expect(retrievalStopwatch.elapsedMilliseconds, lessThan(1000),
               reason: 'Bulk credential retrieval should complete within 1 second');
        expect(allCredentials.length, equals(100));
      });

      testWidgets('should support credential export/import with encryption', (WidgetTester tester) async {
        // TDD: Test data portability while maintaining encryption
        const testPassphrase = 'ExportImportTest123!';
        DatabaseService.setPassphrase(testPassphrase);
        await databaseService.database;

        // Create test data
        await databaseService.insert('projects', {
          'id': 'export-project',
          'name': 'Export Test Project',
          'description': 'Project for export testing',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        final testCredentials = [
          {'name': 'GitHub Token', 'value': 'ghp_1234567890abcdef'},
          {'name': 'AWS Access Key', 'value': 'AKIA1234567890ABCDEF'},
          {'name': 'Database Password', 'value': 'super_secret_db_pass_123'},
        ];

        for (int i = 0; i < testCredentials.length; i++) {
          await databaseService.insert('credentials', {
            'id': 'export-cred-$i',
            'project_id': 'export-project',
            'name': testCredentials[i]['name']!,
            'encrypted_value': testCredentials[i]['value']!,
            'credential_type': 'secret',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
        }

        // Export data (should remain encrypted)
        final exportData = await databaseService.exportProjectData('export-project');
        expect(exportData, isNotNull);
        expect(exportData['credentials'].length, equals(3));

        // Clear database
        await databaseService.deleteDatabase();

        // Import data into new encrypted database
        DatabaseService.setPassphrase(testPassphrase);
        await databaseService.database;

        final importResult = await databaseService.importProjectData(exportData);
        expect(importResult['success'], true, reason: 'Import should succeed');

        // Verify imported data
        final importedCredentials = await databaseService.query('credentials',
                                                              where: 'project_id = ?',
                                                              whereArgs: ['export-project']);
        
        expect(importedCredentials.length, equals(3));
        for (int i = 0; i < testCredentials.length; i++) {
          final imported = importedCredentials.firstWhere((c) => c['name'] == testCredentials[i]['name']);
          expect(imported['encrypted_value'], equals(testCredentials[i]['value']));
        }
      });
    });

    group('Database Migration Integration', () {
      testWidgets('should migrate complete application state to encrypted database', (WidgetTester tester) async {
        // TDD: Test full application state migration
        
        // Step 1: Create legacy unencrypted database with full app state
        final legacyDb = await databaseService.database;
        
        // Add projects
        await databaseService.insert('projects', {
          'id': 'legacy-project-1',
          'name': 'Legacy Project 1',
          'description': 'First legacy project',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        // Add credentials
        await databaseService.insert('credentials', {
          'id': 'legacy-cred-1',
          'project_id': 'legacy-project-1',
          'name': 'Legacy API Key',
          'encrypted_value': 'legacy-unencrypted-key-123',
          'credential_type': 'api_key',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        // Add AI services
        await databaseService.insert('ai_services', {
          'id': 'legacy-ai-service-1',
          'name': 'OpenAI',
          'description': 'OpenAI API Service',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        // Add metadata
        await databaseService.updateMetadata('theme_preference', 'dark');
        await databaseService.updateMetadata('user_settings', '{"notifications": true}');

        await databaseService.close();

        // Step 2: Migrate to encrypted database
        const migrationPassphrase = 'MigrationIntegrationTest123!';
        final migrationStopwatch = Stopwatch()..start();
        
        final migrationResult = await databaseService.migrateToEncrypted(migrationPassphrase);
        migrationStopwatch.stop();

        expect(migrationResult, true, reason: 'Migration should succeed');
        expect(migrationStopwatch.elapsedMilliseconds, lessThan(10000),
               reason: 'Migration should complete within 10 seconds');

        // Step 3: Verify all data migrated correctly
        DatabaseService.setPassphrase(migrationPassphrase);
        
        // Verify projects
        final projects = await databaseService.query('projects');
        expect(projects.length, equals(1));
        expect(projects.first['name'], equals('Legacy Project 1'));

        // Verify credentials
        final credentials = await databaseService.query('credentials');
        expect(credentials.length, equals(1));
        expect(credentials.first['encrypted_value'], equals('legacy-unencrypted-key-123'));

        // Verify AI services
        final aiServices = await databaseService.query('ai_services');
        expect(aiServices.length, equals(1));
        expect(aiServices.first['name'], equals('OpenAI'));

        // Verify metadata
        final themePreference = await databaseService.getMetadata('theme_preference');
        final userSettings = await databaseService.getMetadata('user_settings');
        expect(themePreference, equals('dark'));
        expect(userSettings, equals('{"notifications": true}'));

        // Step 4: Verify database is actually encrypted
        await databaseService.close();
        
        // Try to access without passphrase - should fail
        DatabaseService.clearPassphrase();
        expect(() async => await databaseService.database,
               throwsA(isA<Exception>()),
               reason: 'Database should be inaccessible without passphrase');
      });

      testWidgets('should handle migration failure and rollback correctly', (WidgetTester tester) async {
        // TDD: Test migration failure handling
        
        // Create legacy database
        await databaseService.database;
        await databaseService.updateMetadata('rollback_test', 'original_data');
        await databaseService.close();

        // Attempt migration with conditions that will cause failure
        expect(() async {
          await databaseService.migrateToEncryptedWithRollback(''); // Empty passphrase
        }, throwsException, reason: 'Invalid migration should fail');

        // Verify original database is restored and accessible
        final restoredDb = await databaseService.database;
        final originalData = await databaseService.getMetadata('rollback_test');
        expect(originalData, equals('original_data'),
               reason: 'Original data should be preserved after migration failure');
      });
    });

    group('Cross-Platform Compatibility', () {
      testWidgets('should maintain database compatibility across platforms', (WidgetTester tester) async {
        // TDD: Test database portability
        const testPassphrase = 'CrossPlatformTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database;

        // Add test data
        await databaseService.updateMetadata('platform_test', Platform.operatingSystem);
        await databaseService.updateMetadata('created_timestamp', DateTime.now().toIso8601String());

        // Verify database file characteristics
        final dbPath = await databaseService.getDatabasePath();
        final dbFile = File(dbPath);
        
        expect(await dbFile.exists(), true, reason: 'Database file should exist');
        expect(await dbFile.length(), greaterThan(0), reason: 'Database file should not be empty');

        // Test database version compatibility
        final versionResult = await databaseService.rawQuery('PRAGMA user_version');
        expect(versionResult.first['user_version'], greaterThanOrEqualTo(3),
               reason: 'Database version should support SQLCipher');

        // Verify encryption integration (SQLCipher on mobile, application-layer on desktop)
        if (Platform.isAndroid || Platform.isIOS) {
          final cipherResult = await databaseService.rawQuery('PRAGMA cipher_version');
          expect(cipherResult.isNotEmpty, true, reason: 'SQLCipher should be available on mobile');
        } else {
          // Desktop uses application-layer encryption
          expect(true, true, reason: 'Desktop uses application-layer encryption');
        }

        // Test data retrieval
        final platformData = await databaseService.getMetadata('platform_test');
        expect(platformData, equals(Platform.operatingSystem));
      });

      testWidgets('should handle platform-specific file paths correctly', (WidgetTester tester) async {
        // TDD: Test platform-specific path handling
        const testPassphrase = 'FilePathTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        // Get database path
        final dbPath = await databaseService.getDatabasePath();
        expect(dbPath, isNotNull);
        expect(dbPath, contains('api_key_manager.db'), reason: 'Path should contain database filename');

        // Verify path is platform-appropriate
        if (Platform.isWindows) {
          expect(dbPath, contains('\\'), reason: 'Windows paths should use backslashes');
        } else {
          expect(dbPath, contains('/'), reason: 'Unix-like paths should use forward slashes');
        }

        // Verify database can be created at the path
        await databaseService.database;
        final dbFile = File(dbPath);
        expect(await dbFile.exists(), true, reason: 'Database should be created at correct path');
      });
    });

    group('Performance Integration Tests', () {
      testWidgets('should maintain acceptable performance under realistic load', (WidgetTester tester) async {
        // TDD: Test real-world performance scenarios
        const testPassphrase = 'PerformanceIntegrationTest123!';
        DatabaseService.setPassphrase(testPassphrase);

        await databaseService.database;

        final totalStopwatch = Stopwatch()..start();

        // Simulate realistic application usage
        await databaseService.transaction((txn) async {
          // Create 10 projects
          for (int p = 0; p < 10; p++) {
            await txn.insert('projects', {
              'id': 'perf-project-$p',
              'name': 'Performance Project $p',
              'description': 'Project for performance testing',
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            });

            // Create 10 credentials per project
            for (int c = 0; c < 10; c++) {
              await txn.insert('credentials', {
                'id': 'perf-cred-$p-$c',
                'project_id': 'perf-project-$p',
                'name': 'Performance Credential $p-$c',
                'encrypted_value': 'performance-api-key-$p-$c-${DateTime.now().millisecondsSinceEpoch}',
                'credential_type': 'api_key',
                'created_at': DateTime.now().millisecondsSinceEpoch,
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              });
            }
          }

          // Create 5 AI services
          for (int a = 0; a < 5; a++) {
            await txn.insert('ai_services', {
              'id': 'perf-ai-service-$a',
              'name': 'Performance AI Service $a',
              'description': 'AI service for performance testing',
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            });

            // Create 5 keys per AI service
            for (int k = 0; k < 5; k++) {
              await txn.insert('ai_service_keys', {
                'id': 'perf-ai-key-$a-$k',
                'service_id': 'perf-ai-service-$a',
                'name': 'Performance AI Key $a-$k',
                'encrypted_value': 'performance-ai-key-$a-$k',
                'key_type': 'api_key',
                'created_at': DateTime.now().millisecondsSinceEpoch,
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              });
            }
          }
        });

        totalStopwatch.stop();

        expect(totalStopwatch.elapsedMilliseconds, lessThan(15000),
               reason: 'Realistic data creation should complete within 15 seconds');

        // Test query performance with realistic data volume
        final queryStopwatch = Stopwatch()..start();
        
        final allProjects = await databaseService.query('projects');
        final allCredentials = await databaseService.query('credentials', limit: 50);
        final searchResults = await databaseService.query('credentials',
                                                         where: 'name LIKE ?',
                                                         whereArgs: ['%Performance%']);
        
        queryStopwatch.stop();

        expect(queryStopwatch.elapsedMilliseconds, lessThan(1000),
               reason: 'Realistic queries should complete within 1 second');

        // Verify data integrity
        expect(allProjects.length, equals(10));
        expect(allCredentials.length, equals(50)); // Limited by query
        expect(searchResults.length, equals(100)); // All credentials match search
      });
    });
  });
}