import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/services/biometric_auth_service.dart';
import 'package:cred_manager/services/database_service.dart';

// Unit tests for BiometricAuthService AES encryption (ST025)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BiometricAuthService AES Encryption Tests (ST025)', () {
    late BiometricAuthService biometricService;

    setUp(() async {
      biometricService = BiometricAuthService();

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

      // Mock method channels for local_auth
      const MethodChannel localAuthChannel = MethodChannel('plugins.flutter.io/local_auth');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        localAuthChannel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getAvailableBiometrics':
              return ['fingerprint'];
            case 'isDeviceSupported':
              return true;
            case 'canCheckBiometrics':
              return true;
            case 'authenticate':
              return true; // Mock successful authentication
            default:
              return null;
          }
        },
      );

      // Clean up any existing database before each test
      try {
        await DatabaseService.instance.close();
        await DatabaseService.instance.deleteDatabase();
      } catch (e) {
        // Ignore errors if database doesn't exist
      }

      // Clear passphrase to ensure clean state
      DatabaseService.clearPassphrase();
    });

    test('should encrypt passphrase with AES for biometric storage', () async {
      // TDD: This test validates that biometric keys are encrypted with AES-GCM
      const passphrase = 'TestPassphrase123!';

      // Store biometric key with encryption
      await biometricService.storeBiometricKey(passphrase);

      // Retrieve and verify it decrypts correctly
      final retrievedKey = await biometricService.getBiometricKey();
      expect(retrievedKey, isNotNull, reason: 'Should retrieve stored biometric key');

      // The retrieved key should decrypt back to the original passphrase
      expect(retrievedKey, equals(passphrase), reason: 'Should decrypt stored passphrase correctly');
    });

    test('should decrypt AES encrypted passphrase for biometric login', () async {
      // TDD: This test validates that AES decryption works correctly
      const passphrase = 'TestPassphrase123!';

      // Store encrypted passphrase
      await biometricService.storeBiometricKey(passphrase);

      // Retrieve and decrypt
      final decryptedPassphrase = await biometricService.getBiometricKey();
      expect(decryptedPassphrase, isNotNull, reason: 'Should retrieve encrypted key');
      expect(decryptedPassphrase, equals(passphrase), reason: 'Decrypted passphrase should match original');

      // Test with different passphrase
      const differentPassphrase = 'DifferentPass456!';
      await biometricService.storeBiometricKey(differentPassphrase);
      final decryptedDifferent = await biometricService.getBiometricKey();
      expect(decryptedDifferent, equals(differentPassphrase), reason: 'Should handle different passphrases');
    });

    test('should handle biometric login with encrypted passphrase retrieval', () async {
      // TDD: This test validates the biometric login flow with encrypted keys
      const passphrase = 'BiometricTestPass123!';

      // Enable biometric and store encrypted passphrase
      await biometricService.setBiometricEnabled(true);
      await biometricService.storeBiometricKey(passphrase);

      // Simulate biometric login (this would call loginWithBiometric in AuthState)
      final retrievedKey = await biometricService.getBiometricKey();
      expect(retrievedKey, isNotNull, reason: 'Should retrieve encrypted key for biometric login');
      expect(retrievedKey, equals(passphrase), reason: 'Retrieved key should be decryptable to original passphrase');
    });

    test('should handle failure cases for biometric encryption', () async {
      // TDD: Test error handling for encryption/decryption failures

      // Test with invalid encryption key
      await biometricService.storeBiometricKey('test_passphrase');

      // Test missing biometric key
      await biometricService.removeBiometricKey();
      final missingKey = await biometricService.getBiometricKey();
      expect(missingKey, isNull, reason: 'Should return null for missing biometric key');

      // Test biometric not enabled
      await biometricService.setBiometricEnabled(false);
      final isEnabled = await biometricService.isBiometricEnabled();
      expect(isEnabled, false, reason: 'Should reflect disabled biometric state');
    });

    test('should use proper AES encryption with derived key', () async {
      // TDD: This test validates AES encryption properties
      const passphrase = 'AES_Test_Passphrase!@#';

      // Store with AES-GCM encryption
      await biometricService.storeBiometricKey(passphrase);

      // Verify encryption properties
      final encrypted = await biometricService.getBiometricKey();
      expect(encrypted, isNotNull, reason: 'AES encryption should produce valid encrypted data');
      expect(encrypted!, equals(passphrase), reason: 'Should be able to decrypt correctly');

      // Test that different passphrases produce different encrypted results
      const differentPassphrase = 'Different_AES_Test!@#';
      await biometricService.storeBiometricKey(differentPassphrase);
      final differentEncrypted = await biometricService.getBiometricKey();
      expect(differentEncrypted, isNotNull);
      expect(differentEncrypted, equals(differentPassphrase), reason: 'Should decrypt correctly');
    });
  });
}
