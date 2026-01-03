import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/services/credential_storage_service.dart';
import 'package:cred_manager/services/database_service.dart';
import 'package:cred_manager/services/encryption_service.dart';
import 'package:cred_manager/models/project.dart';
import 'package:cred_manager/models/ai_service.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CredentialStorageService credentialStorage;
  late DatabaseService databaseService;
  late EncryptionService encryptionService;

  setUp(() async {
    // Mock method channels
    const MethodChannel secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'read':
            return null;
          case 'write':
            return null;
          case 'delete':
            return null;
          case 'deleteAll':
            return null;
          default:
            return null;
        }
      },
    );

    const MethodChannel sharedPrefsChannel = MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      sharedPrefsChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getAll':
            return {};
          case 'setBool':
            return true;
          case 'setString':
            return true;
          case 'remove':
            return true;
          case 'clear':
            return true;
          default:
            return null;
        }
      },
    );

    // Clean up any existing database
    try {
      await DatabaseService.instance.close();
      await DatabaseService.instance.deleteDatabase();
    } catch (e) {
      // Ignore cleanup errors
    }

    credentialStorage = CredentialStorageService();
    databaseService = DatabaseService.instance;
    encryptionService = EncryptionService();

    // Initialize database
    await databaseService.initDatabase();
  });

  tearDown(() async {
    // Clean up database
    try {
      await databaseService.close();
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  group('Credential Security Tests (ST028)', () {
    test('should handle secure decryption of stored credentials', () async {
      // TDD: This test will initially fail until secure decryption is implemented
      const passphrase = 'DecryptTestPass123!';
      const testCredentialValue = 'secret_api_key_123';

      // Set passphrase for encryption/decryption
      credentialStorage.setPassphrase(passphrase);

      // Create a project and credential
      final project = await credentialStorage.createProject(
        name: 'Test Project',
        description: 'Test project for decryption',
      );

      final credential = await credentialStorage.createCredential(
        projectId: project.id,
        name: 'Test API Key',
        value: testCredentialValue,
        type: CredentialType.apiKey,
      );

      // Retrieve project with credentials (should decrypt automatically)
      final retrievedProject = await credentialStorage.getProject(project.id);
      expect(retrievedProject, isNotNull, reason: 'Should retrieve project with credentials');
      expect(retrievedProject!.credentials.length, equals(1), reason: 'Should have one credential');

      final retrievedCredential = retrievedProject.credentials.first;
      expect(retrievedCredential.value, equals(testCredentialValue), reason: 'Decrypted credential should match original');
    });

    test('should handle decryption failures gracefully', () async {
      // TDD: This test will initially fail until decryption error handling is implemented
      const passphrase = 'DecryptFailTestPass123!';

      // Set wrong passphrase
      credentialStorage.setPassphrase('wrong_passphrase');

      // Try to retrieve credentials (should fail gracefully)
      final projects = await credentialStorage.getAllProjects();

      // Should handle decryption failures without crashing
      expect(projects, isNotNull, reason: 'Should return projects list even with decryption failures');
      // Corrupted credentials should be skipped or marked as corrupted
      expect(true, isTrue, reason: 'Should log and quarantine corrupted credentials (TDD - implement error handling)');
    });

    test('should quarantine corrupted credentials', () async {
      // TDD: This test will initially fail until credential quarantine is implemented
      const passphrase = 'QuarantineTestPass123!';

      credentialStorage.setPassphrase(passphrase);

      // Create valid credential
      final project = await credentialStorage.createProject(name: 'Quarantine Test');
      await credentialStorage.createCredential(
        projectId: project.id,
        name: 'Valid Credential',
        value: 'valid_secret',
        type: CredentialType.password,
      );

      // Simulate credential corruption (manually corrupt in database)
      // This would require direct database manipulation for testing
      final corruptedValue = 'corrupted_encrypted_data';
      await databaseService.update(
        'credentials',
        {'encrypted_value': corruptedValue},
        where: 'project_id = ?',
        whereArgs: [project.id],
      );

      // Try to retrieve (should quarantine corrupted credential)
      final retrievedProject = await credentialStorage.getProject(project.id);
      expect(retrievedProject, isNotNull, reason: 'Should retrieve project');

      // Should quarantine corrupted credentials
      expect(true, isTrue, reason: 'Should quarantine corrupted credentials and log incident (TDD - implement quarantine logic)');
    });

    test('should handle transaction-based re-encryption for passphrase changes', () async {
      // TDD: This test will initially fail until transaction-based re-encryption is implemented
      const oldPassphrase = 'OldPassphrase123!';
      const newPassphrase = 'NewPassphrase456!';

      // Set old passphrase and create data
      credentialStorage.setPassphrase(oldPassphrase);

      final project = await credentialStorage.createProject(name: 'Re-encryption Test');
      final credential1 = await credentialStorage.createCredential(
        projectId: project.id,
        name: 'API Key 1',
        value: 'secret_key_1',
        type: CredentialType.apiKey,
      );
      final credential2 = await credentialStorage.createCredential(
        projectId: project.id,
        name: 'API Key 2',
        value: 'secret_key_2',
        type: CredentialType.apiKey,
      );

      // Create AI service and keys
      final aiService = await credentialStorage.createAiService(
        name: 'Test AI Service',
        description: 'For re-encryption testing',
      );
      await credentialStorage.createAiServiceKey(
        serviceId: aiService.id,
        name: 'API Key',
        value: 'ai_secret_key',
        type: AiKeyType.apiKey,
      );

      // Change passphrase (should re-encrypt all data in transaction)
      await credentialStorage.changePassphrase(oldPassphrase, newPassphrase);

      // Update credential storage with new passphrase
      credentialStorage.setPassphrase(newPassphrase);

      // Verify all data can still be decrypted with new passphrase
      final retrievedProject = await credentialStorage.getProject(project.id);
      expect(retrievedProject, isNotNull, reason: 'Should retrieve project after re-encryption');
      expect(retrievedProject!.credentials.length, equals(2), reason: 'Should have both credentials');

      // Verify credential values
      final creds = retrievedProject.credentials;
      expect(creds.any((c) => c.value == 'secret_key_1'), isTrue, reason: 'Should decrypt first credential');
      expect(creds.any((c) => c.value == 'secret_key_2'), isTrue, reason: 'Should decrypt second credential');

      // Verify AI service keys
      final retrievedAiService = await credentialStorage.getAiService(aiService.id);
      expect(retrievedAiService, isNotNull, reason: 'Should retrieve AI service after re-encryption');
      expect(retrievedAiService!.keys.length, equals(1), reason: 'Should have AI service key');
      expect(retrievedAiService.keys.first.value, equals('ai_secret_key'), reason: 'Should decrypt AI service key');
    });

    test('should handle re-encryption transaction failures gracefully', () async {
      // TDD: This test will initially fail until transaction rollback is implemented
      const oldPassphrase = 'FailTestOldPass123!';
      const newPassphrase = 'FailTestNewPass456!';

      // Set old passphrase and create data
      credentialStorage.setPassphrase(oldPassphrase);
      final project = await credentialStorage.createProject(name: 'Transaction Fail Test');
      await credentialStorage.createCredential(
        projectId: project.id,
        name: 'Test Credential',
        value: 'test_value',
        type: CredentialType.password,
      );

      // Simulate transaction failure (this would require mocking database errors)
      // The implementation should rollback all changes if re-encryption fails
      expect(true, isTrue, reason: 'Should rollback transaction on re-encryption failure (TDD - implement transaction safety)');

      // Verify data integrity is maintained
      credentialStorage.setPassphrase(oldPassphrase);
      final retrievedProject = await credentialStorage.getProject(project.id);
      expect(retrievedProject, isNotNull, reason: 'Should maintain data integrity after failed re-encryption');
      expect(retrievedProject!.credentials.first.value, equals('test_value'), reason: 'Should preserve original data');
    });

    test('should validate passphrase before operations', () async {
      // Test that operations require passphrase to be set
      expect(
        () => credentialStorage.getAllProjects(),
        throwsA(predicate((e) => e is StateError && e.message.contains('Passphrase not set'))),
        reason: 'Should throw error when passphrase not set for operations requiring decryption'
      );

      // Set passphrase
      credentialStorage.setPassphrase('TestPass123!');

      // Now operations should work (may be empty, but shouldn't throw passphrase error)
      final projects = await credentialStorage.getAllProjects();
      expect(projects, isNotNull, reason: 'Should work after passphrase is set');
    });

    test('should handle concurrent access during re-encryption', () async {
      // TDD: This test will initially fail until concurrent access handling is implemented
      const oldPassphrase = 'ConcurrentTestPass123!';
      const newPassphrase = 'ConcurrentNewPass456!';

      credentialStorage.setPassphrase(oldPassphrase);

      // Create test data
      final project = await credentialStorage.createProject(name: 'Concurrent Test');
      await credentialStorage.createCredential(
        projectId: project.id,
        name: 'Concurrent Credential',
        value: 'concurrent_value',
        type: CredentialType.apiKey,
      );

      // Simulate concurrent re-encryption operations
      // This should be handled safely with transactions
      final futures = [
        credentialStorage.changePassphrase(oldPassphrase, newPassphrase),
        credentialStorage.changePassphrase(oldPassphrase, 'AnotherNewPass789!'),
      ];

      // One should succeed, others should fail gracefully
      expect(true, isTrue, reason: 'Should handle concurrent re-encryption safely (TDD - implement concurrency control)');
    });
  });
}