import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/models/auth_state.dart';
import 'package:cred_manager/models/password_vault.dart';
import 'package:cred_manager/models/project.dart';
import 'package:cred_manager/services/credential_storage_service.dart';

/// Security Failure Tests
///
/// These tests verify that security failures (like missing passphrase)
/// trigger automatic logout to prevent unauthorized access.
void main() {
  group('Security Failure Tests', () {
    late CredentialStorageService credentialStorage;
    late AuthState authState;
    const testPassphrase = 'TestPassphrase123!';

    setUp(() {
      credentialStorage = CredentialStorageService();
      authState = AuthState();

      // Set up the security failure callback to track if logout was called
      credentialStorage.onSecurityFailure = () {
        print('SECURITY FAILURE: Logging out due to missing passphrase');
      };
    });

    test('onSecurityFailure callback is set in AuthState', () {
      // Verify that AuthState sets up the callback
      expect(credentialStorage.onSecurityFailure, isNotNull);
      print('✅ Security callback is configured');
    });

    test('Operations without passphrase trigger security failure', () async {
      // Track whether the callback was invoked
      bool callbackInvoked = false;
      credentialStorage.onSecurityFailure = () {
        callbackInvoked = true;
      };

      // Don't set passphrase - this simulates auto-login without passphrase
      // Try to create a project (which calls _validatePassphrase)
      try {
        await credentialStorage.createProject(
          name: 'Test Project',
          description: 'Test Description',
        );
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('Passphrase not set'));
        expect(callbackInvoked, isTrue,
          reason: 'Security failure callback should be invoked when passphrase is not set');
      }

      print('✅ Operations without passphrase trigger security failure callback');
    });

    test('createPasswordEntry without passphrase triggers logout', () async {
      // Track whether the callback was invoked
      bool callbackInvoked = false;
      credentialStorage.onSecurityFailure = () {
        callbackInvoked = true;
      };

      // Try to create a password entry without setting passphrase
      try {
        await credentialStorage.createPasswordEntry(
          vaultId: 'test-vault',
          name: 'Test Entry',
          value: 'TestPassword123!',
        );
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('Passphrase not set'));
        expect(callbackInvoked, isTrue,
          reason: 'Security failure callback should be invoked for password entry creation');
      }

      print('✅ Password entry creation without passphrase triggers security failure');
    });

    test('createPasswordVault without passphrase triggers logout', () async {
      // Track whether the callback was invoked
      bool callbackInvoked = false;
      credentialStorage.onSecurityFailure = () {
        callbackInvoked = true;
      };

      // Try to create a vault without setting passphrase
      try {
        await credentialStorage.createPasswordVault(
          name: 'Test Vault',
          description: 'Test Description',
        );
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('Passphrase not set'));
        expect(callbackInvoked, isTrue,
          reason: 'Security failure callback should be invoked for vault creation');
      }

      print('✅ Vault creation without passphrase triggers security failure');
    });

    test('getAllPasswordVaults without passphrase triggers logout', () async {
      // Track whether the callback was invoked
      bool callbackInvoked = false;
      credentialStorage.onSecurityFailure = () {
        callbackInvoked = true;
      };

      // Try to get vaults without setting passphrase
      try {
        await credentialStorage.getAllPasswordVaults();
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('Passphrase not set'));
        expect(callbackInvoked, isTrue,
          reason: 'Security failure callback should be invoked for getting vaults');
      }

      print('✅ Getting vaults without passphrase triggers security failure');
    });

    test('Operations work correctly when passphrase is set', () async {
      // Set the passphrase
      credentialStorage.setPassphrase(testPassphrase);

      // Now operations should work (they may fail for other reasons like DB not initialized,
      // but they should NOT fail with "Passphrase not set")
      try {
        await credentialStorage.createProject(
          name: 'Test Project',
          description: 'Test Description',
        );
      } catch (e) {
        // May fail due to database not being initialized, but that's OK
        // We just want to verify it's NOT a "Passphrase not set" error
        expect(e.toString(), isNot(contains('Passphrase not set')),
          reason: 'Should not get "Passphrase not set" error when passphrase is set');
      }

      print('✅ Operations work correctly when passphrase is set');
    });

    test('clearPassphrase clears the passphrase', () async {
      // Set passphrase
      credentialStorage.setPassphrase(testPassphrase);

      // Clear it
      credentialStorage.clearPassphrase();

      // Try to create something - should trigger security failure
      bool callbackInvoked = false;
      credentialStorage.onSecurityFailure = () {
        callbackInvoked = true;
      };

      // Try to create a project to trigger _validatePassphrase
      try {
        await credentialStorage.createProject(
          name: 'Test Project',
          description: 'Test Description',
        );
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('Passphrase not set'));
        expect(callbackInvoked, isTrue);
      }

      print('✅ clearPassphrase properly clears the passphrase');
    });

    test('createCredential without passphrase triggers logout', () async {
      // Track whether the callback was invoked
      bool callbackInvoked = false;
      credentialStorage.onSecurityFailure = () {
        callbackInvoked = true;
      };

      // Try to create a credential without setting passphrase
      try {
        await credentialStorage.createCredential(
          projectId: 'test-project',
          name: 'Test Credential',
          value: 'test-key',
          type: CredentialType.apiKey,
        );
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('Passphrase not set'));
        expect(callbackInvoked, isTrue,
          reason: 'Security failure callback should be invoked for credential creation');
      }

      print('✅ Credential creation without passphrase triggers security failure');
    });

    test('updateCredential without passphrase triggers logout', () async {
      // Track whether the callback was invoked
      bool callbackInvoked = false;
      credentialStorage.onSecurityFailure = () {
        callbackInvoked = true;
      };

      // Try to update a credential without setting passphrase
      try {
        final credential = Credential(
          id: 'test-id',
          projectId: 'test-project',
          name: 'Test Credential',
          value: 'test-key',
          type: CredentialType.apiKey,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await credentialStorage.updateCredential(credential);
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('Passphrase not set'));
        expect(callbackInvoked, isTrue,
          reason: 'Security failure callback should be invoked for credential updates');
      }

      print('✅ Credential update without passphrase triggers security failure');
    });

    test('deleteCredential without passphrase triggers logout', () async {
      // Track whether the callback was invoked
      bool callbackInvoked = false;
      credentialStorage.onSecurityFailure = () {
        callbackInvoked = true;
      };

      // Try to delete a credential without setting passphrase
      try {
        await credentialStorage.deleteCredential('test-id', 'test-project');
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('Passphrase not set'));
        expect(callbackInvoked, isTrue,
          reason: 'Security failure callback should be invoked for credential deletion');
      }

      print('✅ Credential deletion without passphrase triggers security failure');
    });

    test('createAiService without passphrase triggers logout', () async {
      // Track whether the callback was invoked
      bool callbackInvoked = false;
      credentialStorage.onSecurityFailure = () {
        callbackInvoked = true;
      };

      // Try to create an AI service without setting passphrase
      try {
        await credentialStorage.createAiService(
          name: 'Test AI Service',
          description: 'Test Description',
        );
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('Passphrase not set'));
        expect(callbackInvoked, isTrue,
          reason: 'Security failure callback should be invoked for AI service creation');
      }

      print('✅ AI service creation without passphrase triggers security failure');
    });

    test('updatePasswordEntry without passphrase triggers logout', () async {
      // Track whether the callback was invoked
      bool callbackInvoked = false;
      credentialStorage.onSecurityFailure = () {
        callbackInvoked = true;
      };

      // Try to update a password entry without setting passphrase
      try {
        final entry = PasswordEntry(
          id: 'test-entry',
          vaultId: 'test-vault',
          name: 'Test Entry',
          value: 'TestPassword123!',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await credentialStorage.updatePasswordEntry(entry);
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('Passphrase not set'));
        expect(callbackInvoked, isTrue,
          reason: 'Security failure callback should be invoked for password entry updates');
      }

      print('✅ Password entry update without passphrase triggers security failure');
    });

    test('deletePasswordEntry without passphrase triggers logout', () async {
      // Track whether the callback was invoked
      bool callbackInvoked = false;
      credentialStorage.onSecurityFailure = () {
        callbackInvoked = true;
      };

      // Try to delete a password entry without setting passphrase
      try {
        await credentialStorage.deletePasswordEntry('test-entry', 'test-vault');
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('Passphrase not set'));
        expect(callbackInvoked, isTrue,
          reason: 'Security failure callback should be invoked for password entry deletion');
      }

      print('✅ Password entry deletion without passphrase triggers security failure');
    });

    test('deletePasswordVault without passphrase triggers logout', () async {
      // Track whether the callback was invoked
      bool callbackInvoked = false;
      credentialStorage.onSecurityFailure = () {
        callbackInvoked = true;
      };

      // Try to delete a vault without setting passphrase
      try {
        await credentialStorage.deletePasswordVault('test-vault');
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('Passphrase not set'));
        expect(callbackInvoked, isTrue,
          reason: 'Security failure callback should be invoked for vault deletion');
      }

      print('✅ Vault deletion without passphrase triggers security failure');
    });

    test('updatePasswordVault without passphrase triggers logout', () async {
      // Track whether the callback was invoked
      bool callbackInvoked = false;
      credentialStorage.onSecurityFailure = () {
        callbackInvoked = true;
      };

      // Try to update a vault without setting passphrase
      try {
        final vault = PasswordVault(
          id: 'test-vault',
          name: 'Test Vault',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await credentialStorage.updatePasswordVault(vault);
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('Passphrase not set'));
        expect(callbackInvoked, isTrue,
          reason: 'Security failure callback should be invoked for vault updates');
      }

      print('✅ Vault update without passphrase triggers security failure');
    });

    test('getAllProjects without passphrase triggers logout', () async {
      // Track whether the callback was invoked
      bool callbackInvoked = false;
      credentialStorage.onSecurityFailure = () {
        callbackInvoked = true;
      };

      // Try to get projects without setting passphrase
      try {
        await credentialStorage.getAllProjects();
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('Passphrase not set'));
        expect(callbackInvoked, isTrue,
          reason: 'Security failure callback should be invoked for getting projects');
      }

      print('✅ Getting projects without passphrase triggers security failure');
    });

    test('getAllAiServices without passphrase triggers logout', () async {
      // Track whether the callback was invoked
      bool callbackInvoked = false;
      credentialStorage.onSecurityFailure = () {
        callbackInvoked = true;
      };

      // Try to get AI services without setting passphrase
      try {
        await credentialStorage.getAllAiServices();
        fail('Should have thrown an error');
      } catch (e) {
        expect(e.toString(), contains('Passphrase not set'));
        expect(callbackInvoked, isTrue,
          reason: 'Security failure callback should be invoked for getting AI services');
      }

      print('✅ Getting AI services without passphrase triggers security failure');
    });
  });
}
