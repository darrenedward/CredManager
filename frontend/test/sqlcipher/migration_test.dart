import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/services/database_service.dart';
import 'package:cred_manager/services/argon2_service.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'dart:io';
import 'dart:convert';

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

  group('SQLCipher Database Migration Tests', () {
    group('Legacy SQLite to SQLCipher Migration', () {
      test('should detect existing unencrypted SQLite database', () async {
        // TDD: This will fail until migration detection is implemented
        
        // Create an unencrypted database first (simulate legacy state)
        final unencryptedDb = await databaseService.database;
        
        // Add some legacy data
        await databaseService.insert('projects', {
          'id': 'legacy-project-1',
          'name': 'Legacy Project',
          'description': 'This is legacy unencrypted data',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        await databaseService.insert('app_metadata', {
          'key': 'legacy_flag',
          'value': 'true',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        await databaseService.close();

        // Now check if migration detector identifies it as unencrypted
        final migrationNeeded = await databaseService.detectLegacyDatabase();
        expect(migrationNeeded, true, 
               reason: 'Should detect existing unencrypted database');
      });

      test('should migrate all data from SQLite to SQLCipher', () async {
        // TDD: Test complete data migration process
        
        // Step 1: Create legacy unencrypted database with sample data
        final legacyDb = await databaseService.database;
        
        await databaseService.insert('projects', {
          'id': 'migrate-project-1',
          'name': 'Migration Test Project',
          'description': 'Project to be migrated',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        await databaseService.insert('credentials', {
          'id': 'migrate-cred-1',
          'project_id': 'migrate-project-1',
          'name': 'API Key to Migrate',
          'encrypted_value': 'legacy-api-key-12345',
          'credential_type': 'api_key',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        await databaseService.insert('app_metadata', {
          'key': 'legacy_setting',
          'value': 'legacy_value',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });

        await databaseService.close();

        // Step 2: Initiate migration to encrypted database
        const migrationPassphrase = 'MigrationTestPassphrase123!';
        
        final migrationResult = await databaseService.migrateToEncrypted(migrationPassphrase);
        expect(migrationResult, true, reason: 'Migration should succeed');

        // Step 3: Verify encrypted database contains all migrated data
        DatabaseService.setPassphrase(migrationPassphrase);
        
        final projects = await databaseService.query('projects', 
                                                    where: 'id = ?', 
                                                    whereArgs: ['migrate-project-1']);
        expect(projects.length, equals(1));
        expect(projects.first['name'], equals('Migration Test Project'));

        final credentials = await databaseService.query('credentials',
                                                       where: 'id = ?',
                                                       whereArgs: ['migrate-cred-1']);
        expect(credentials.length, equals(1));
        expect(credentials.first['encrypted_value'], equals('legacy-api-key-12345'));

        final metadata = await databaseService.getMetadata('legacy_setting');
        expect(metadata, equals('legacy_value'));
      });

      test('should preserve all table schemas during migration', () async {
        // TDD: Verify schema integrity during migration
        
        // Create legacy database
        final legacyDb = await databaseService.database;
        
        // Get original schema information
        final originalTables = await legacyDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
        );
        
        final originalIndexes = await legacyDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'"
        );

        await databaseService.close();

        // Migrate to encrypted
        const migrationPassphrase = 'SchemaTestPassphrase123!';
        await databaseService.migrateToEncrypted(migrationPassphrase);

        // Verify schema in encrypted database
        DatabaseService.setPassphrase(migrationPassphrase);
        final encryptedDb = await databaseService.database;

        final migratedTables = await encryptedDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
        );

        final migratedIndexes = await encryptedDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'"
        );

        expect(migratedTables.length, equals(originalTables.length),
               reason: 'All tables should be migrated');
        expect(migratedIndexes.length, equals(originalIndexes.length),
               reason: 'All indexes should be migrated');

        // Verify specific required tables exist
        final tableNames = migratedTables.map((t) => t['name']).toSet();
        expect(tableNames, contains('projects'));
        expect(tableNames, contains('credentials'));
        expect(tableNames, contains('app_metadata'));
        expect(tableNames, contains('security_questions'));
        expect(tableNames, contains('ai_services'));
        expect(tableNames, contains('ai_service_keys'));
      });

      test('should handle large datasets during migration', () async {
        // TDD: Test migration performance with substantial data
        
        // Create legacy database with substantial data
        final legacyDb = await databaseService.database;
        
        final stopwatch = Stopwatch()..start();
        
        // Insert 1000 projects and credentials
        for (int i = 0; i < 1000; i++) {
          await databaseService.insert('projects', {
            'id': 'bulk-project-$i',
            'name': 'Bulk Project $i',
            'description': 'Bulk project for migration testing',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });

          await databaseService.insert('credentials', {
            'id': 'bulk-cred-$i',
            'project_id': 'bulk-project-$i',
            'name': 'Bulk Credential $i',
            'encrypted_value': 'bulk-api-key-$i',
            'credential_type': 'api_key',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
        }

        await databaseService.close();
        stopwatch.stop();
        print('Legacy data creation took: ${stopwatch.elapsedMilliseconds}ms');

        // Migrate to encrypted
        const migrationPassphrase = 'BulkMigrationTest123!';
        
        final migrationStopwatch = Stopwatch()..start();
        final migrationResult = await databaseService.migrateToEncrypted(migrationPassphrase);
        migrationStopwatch.stop();

        expect(migrationResult, true);
        expect(migrationStopwatch.elapsedMilliseconds, lessThan(30000),
               reason: 'Migration of 1000 records should complete within 30 seconds');

        // Verify data integrity after migration
        DatabaseService.setPassphrase(migrationPassphrase);
        
        final projectCount = await databaseService.rawQuery('SELECT COUNT(*) as count FROM projects');
        final credentialCount = await databaseService.rawQuery('SELECT COUNT(*) as count FROM credentials');

        expect(projectCount.first['count'], equals(1000));
        expect(credentialCount.first['count'], equals(1000));
      });

      test('should handle migration failure gracefully', () async {
        // TDD: Test error handling during migration
        
        // Create legacy database
        final legacyDb = await databaseService.database;
        await databaseService.insert('projects', {
          'id': 'failure-test-project',
          'name': 'Failure Test',
          'description': 'Testing migration failure handling',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
        await databaseService.close();

        // Attempt migration with invalid conditions
        expect(() async {
          await databaseService.migrateToEncrypted(''); // Empty passphrase should fail
        }, throwsArgumentError, reason: 'Migration should fail with invalid passphrase');

        // Verify original database is intact after failed migration
        final originalDb = await databaseService.database;
        final projects = await databaseService.query('projects',
                                                    where: 'id = ?',
                                                    whereArgs: ['failure-test-project']);
        expect(projects.length, equals(1));
        expect(projects.first['name'], equals('Failure Test'));
      });

      test('should backup original database before migration', () async {
        // TDD: Ensure safe migration with backup
        
        // Create legacy database
        final legacyDb = await databaseService.database;
        await databaseService.insert('app_metadata', {
          'key': 'backup_test',
          'value': 'original_data',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
        await databaseService.close();

        // Migrate with backup
        const migrationPassphrase = 'BackupTestPassphrase123!';
        
        final migrationResult = await databaseService.migrateToEncryptedWithBackup(migrationPassphrase);
        expect(migrationResult.migrationSuccess, true);
        expect(migrationResult.backupPath, isNotNull);

        // Verify backup file exists and contains original data
        final backupFile = File(migrationResult.backupPath!);
        expect(await backupFile.exists(), true, reason: 'Backup file should exist');

        // Verify original data is accessible in backup
        // Note: This would require opening the backup database separately
        expect(await backupFile.length(), greaterThan(0),
               reason: 'Backup file should not be empty');
      });
    });

    group('SharedPreferences Migration', () {
      test('should migrate authentication flags from SharedPreferences to encrypted DB', () async {
        // TDD: Test migration of SharedPreferences data
        
        // Simulate existing SharedPreferences data (mocked in test setup)
        const migrationPassphrase = 'SharedPrefsTestPassphrase123!';
        DatabaseService.setPassphrase(migrationPassphrase);

        // Migrate SharedPreferences data to encrypted database
        await databaseService.migrateSharedPreferencesToDB({
          'is_first_time': false,
          'setup_completed': true,
          'biometric_enabled': true,
          'theme_mode': 'dark',
          'last_login': '2024-01-01T12:00:00Z',
        });

        // Verify data is now in encrypted database
        expect(await databaseService.getMetadata('is_first_time'), equals('false'));
        expect(await databaseService.getMetadata('setup_completed'), equals('true'));
        expect(await databaseService.getMetadata('biometric_enabled'), equals('true'));
        expect(await databaseService.getMetadata('theme_mode'), equals('dark'));
        expect(await databaseService.getMetadata('last_login'), equals('2024-01-01T12:00:00Z'));
      });

      test('should remove SharedPreferences after successful migration', () async {
        // TDD: Verify cleanup of SharedPreferences
        const migrationPassphrase = 'CleanupTestPassphrase123!';
        DatabaseService.setPassphrase(migrationPassphrase);

        // Mock SharedPreferences cleanup verification
        final cleanupResult = await databaseService.cleanupSharedPreferencesAfterMigration();
        expect(cleanupResult, true, reason: 'SharedPreferences cleanup should succeed');

        // Verify that SharedPreferences no longer contains sensitive data
        // This would be verified by checking that SharedPreferences.getInstance()
        // returns null for auth-related keys
        expect(await databaseService.hasLegacySharedPreferencesData(), false,
               reason: 'No legacy SharedPreferences data should remain');
      });

      test('should handle missing SharedPreferences gracefully', () async {
        // TDD: Test behavior when no SharedPreferences exist
        const migrationPassphrase = 'NoSharedPrefsTest123!';
        DatabaseService.setPassphrase(migrationPassphrase);

        // Attempt migration with no existing SharedPreferences
        final migrationResult = await databaseService.migrateSharedPreferencesToDB({});
        
        expect(migrationResult, completes,
               reason: 'Migration should handle empty SharedPreferences');

        // Verify default values are set in database
        expect(await databaseService.getMetadata('is_first_time'), equals('1'));
        expect(await databaseService.getMetadata('setup_completed'), equals('0'));
      });

      test('should preserve custom settings during migration', () async {
        // TDD: Test migration of user-specific settings
        const migrationPassphrase = 'CustomSettingsTest123!';
        DatabaseService.setPassphrase(migrationPassphrase);

        final customSettings = {
          'user_theme_preference': 'custom_blue',
          'notification_settings': '{"enabled": true, "frequency": "daily"}',
          'ui_scale_factor': '1.25',
          'language_preference': 'en_US',
          'backup_frequency': 'weekly',
        };

        await databaseService.migrateSharedPreferencesToDB(customSettings);

        // Verify all custom settings are preserved
        for (final entry in customSettings.entries) {
          final value = await databaseService.getMetadata(entry.key);
          expect(value, equals(entry.value),
                 reason: 'Custom setting ${entry.key} should be preserved');
        }
      });
    });

    group('Security Question Migration', () {
      test('should migrate predefined security questions to user-defined', () async {
        // TDD: Test removal of predefined questions during migration
        const migrationPassphrase = 'SecurityQuestionMigration123!';
        DatabaseService.setPassphrase(migrationPassphrase);

        // Simulate legacy predefined security questions
        final legacyQuestions = [
          {
            'question': 'What is your mother\'s maiden name?',
            'answerHash': 'legacy_hash_1',
            'isCustom': 'false', // Predefined
          },
          {
            'question': 'What was your first pet\'s name?',
            'answerHash': 'legacy_hash_2',
            'isCustom': 'false', // Predefined
          },
          {
            'question': 'What is your custom security question?',
            'answerHash': 'custom_hash_1',
            'isCustom': 'true', // User-defined
          },
        ];

        await databaseService.storeSecurityQuestions(legacyQuestions);

        // Migrate to remove predefined questions
        await databaseService.migratePredefinedSecurityQuestions();

        // Verify only user-defined questions remain
        final migratedQuestions = await databaseService.getSecurityQuestions();
        expect(migratedQuestions, isNotNull);
        expect(migratedQuestions!.length, equals(1));
        expect(migratedQuestions.first['question'], equals('What is your custom security question?'));
        expect(migratedQuestions.first['isCustom'], equals('true'));
      });

      test('should prompt user to replace removed predefined questions', () async {
        // TDD: Test user notification for question replacement
        const migrationPassphrase = 'QuestionReplacementTest123!';
        DatabaseService.setPassphrase(migrationPassphrase);

        // Store only predefined questions
        final predefinedOnlyQuestions = [
          {
            'question': 'What is your mother\'s maiden name?',
            'answerHash': 'legacy_hash_1',
            'isCustom': 'false',
          },
          {
            'question': 'What was your first pet\'s name?',
            'answerHash': 'legacy_hash_2',
            'isCustom': 'false',
          },
        ];

        await databaseService.storeSecurityQuestions(predefinedOnlyQuestions);

        // Migrate predefined questions
        final migrationResult = await databaseService.migratePredefinedSecurityQuestions();
        
        expect(migrationResult.requiresUserInput, true,
               reason: 'Should require user input when all questions are predefined');
        expect(migrationResult.questionsRemoved, equals(2));
        expect(migrationResult.questionsRemaining, equals(0));

        // Verify no questions remain
        final remainingQuestions = await databaseService.getSecurityQuestions();
        expect(remainingQuestions?.length ?? 0, equals(0));
      });

      test('should preserve user-defined questions during migration', () async {
        // TDD: Ensure custom questions are not affected
        const migrationPassphrase = 'CustomQuestionPreservation123!';
        DatabaseService.setPassphrase(migrationPassphrase);

        final mixedQuestions = [
          {
            'question': 'What is your mother\'s maiden name?',
            'answerHash': 'predefined_hash',
            'isCustom': 'false',
          },
          {
            'question': 'What is the name of your favorite book?',
            'answerHash': 'custom_hash_1',
            'isCustom': 'true',
          },
          {
            'question': 'What was the name of your elementary school?',
            'answerHash': 'custom_hash_2',
            'isCustom': 'true',
          },
        ];

        await databaseService.storeSecurityQuestions(mixedQuestions);

        await databaseService.migratePredefinedSecurityQuestions();

        // Verify custom questions are preserved
        final preservedQuestions = await databaseService.getSecurityQuestions();
        expect(preservedQuestions!.length, equals(2));
        
        final customQuestions = preservedQuestions.where((q) => q['isCustom'] == 'true').toList();
        expect(customQuestions.length, equals(2));
        expect(customQuestions[0]['question'], equals('What is the name of your favorite book?'));
        expect(customQuestions[1]['question'], equals('What was the name of your elementary school?'));
      });
    });

    group('Migration Rollback and Recovery', () {
      test('should rollback migration on failure', () async {
        // TDD: Test rollback mechanism for failed migrations
        
        // Create legacy database
        final legacyDb = await databaseService.database;
        await databaseService.insert('app_metadata', {
          'key': 'rollback_test',
          'value': 'original_value',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
        await databaseService.close();

        // Attempt migration that will fail
        expect(() async {
          await databaseService.migrateToEncryptedWithRollback('invalid_passphrase!@#');
        }, throwsException);

        // Verify original database is restored
        final restoredDb = await databaseService.database;
        final originalData = await databaseService.getMetadata('rollback_test');
        expect(originalData, equals('original_value'));
      });

      test('should recover from corrupted migration state', () async {
        // TDD: Test recovery from partially completed migration
        
        // Simulate corrupted migration state
        await databaseService.createCorruptedMigrationState();

        // Attempt recovery
        final recoveryResult = await databaseService.recoverFromCorruptedMigration();
        expect(recoveryResult.recoverySuccessful, true);
        expect(recoveryResult.dataIntegrityVerified, true);

        // Verify database is in clean state
        final integrityCheck = await databaseService.checkIntegrity();
        expect(integrityCheck, true);
      });

      test('should validate data integrity after migration', () async {
        // TDD: Test comprehensive data validation post-migration
        
        // Create legacy database with known data
        final legacyDb = await databaseService.database;
        const testData = {
          'project_count': 5,
          'credential_count': 10,
          'metadata_entries': 8,
        };

        // Insert known quantities of data
        for (int i = 0; i < testData['project_count']!; i++) {
          await databaseService.insert('projects', {
            'id': 'validation-project-$i',
            'name': 'Validation Project $i',
            'description': 'Project for validation testing',
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
        }

        await databaseService.close();

        // Migrate
        const migrationPassphrase = 'ValidationTestPassphrase123!';
        await databaseService.migrateToEncrypted(migrationPassphrase);

        // Validate data integrity
        DatabaseService.setPassphrase(migrationPassphrase);
        
        final validationResult = await databaseService.validateMigrationIntegrity(testData);
        expect(validationResult.isValid, true);
        expect(validationResult.projectCount, equals(testData['project_count']));
        expect(validationResult.missingRecords.length, equals(0));
        expect(validationResult.corruptedRecords.length, equals(0));
      });
    });

    group('Cross-Platform Migration Compatibility', () {
      test('should handle platform-specific database paths during migration', () async {
        // TDD: Test migration across different platforms
        
        final originalPath = await databaseService.getDatabasePath();
        expect(originalPath, isNotNull);

        // Create legacy database
        final legacyDb = await databaseService.database;
        await databaseService.insert('app_metadata', {
          'key': 'platform_test',
          'value': 'cross_platform_data',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
        await databaseService.close();

        // Migrate
        const migrationPassphrase = 'PlatformTestPassphrase123!';
        await databaseService.migrateToEncrypted(migrationPassphrase);

        // Verify migration worked regardless of platform
        DatabaseService.setPassphrase(migrationPassphrase);
        final platformData = await databaseService.getMetadata('platform_test');
        expect(platformData, equals('cross_platform_data'));

        // Verify new database path is correctly set
        final newPath = await databaseService.getDatabasePath();
        expect(newPath, isNotNull);
        expect(File(newPath).existsSync(), true);
      });

      test('should maintain database compatibility across Flutter versions', () async {
        // TDD: Test database format compatibility
        
        // Create database with current schema version
        const migrationPassphrase = 'CompatibilityTestPassphrase123!';
        DatabaseService.setPassphrase(migrationPassphrase);
        
        final db = await databaseService.database;
        
        // Check database version and compatibility
        final versionResult = await db.rawQuery('PRAGMA user_version');
        final currentVersion = versionResult.first['user_version'] as int;
        
        expect(currentVersion, greaterThanOrEqualTo(3),
               reason: 'Database should be at least version 3 for SQLCipher compatibility');

        // Verify SQLCipher specific pragmas work
        final cipherResult = await db.rawQuery('PRAGMA cipher_version');
        expect(cipherResult.isNotEmpty, true,
               reason: 'SQLCipher should be available');
      });
    });
  });
}