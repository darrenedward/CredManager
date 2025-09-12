import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cred_manager/services/biometric_auth_service.dart';
import 'package:cred_manager/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BiometricAuthService biometricService;

  setUp(() async {
    biometricService = BiometricAuthService();
    
    // Clean up any existing test database
    await DatabaseService.instance.deleteDatabase();
    DatabaseService.clearPassphrase();
    
    // Initialize database with test passphrase
    DatabaseService.setPassphrase('test_passphrase_12345');
    
    // Clear any existing biometric data
    await biometricService.setBiometricEnabled(false);
    await biometricService.removeBiometricKey();
  });

  tearDown(() async {
    // Clean up after each test
    await DatabaseService.instance.deleteDatabase();
    DatabaseService.clearPassphrase();
  });

  group('Encrypted Biometric Auth Service Tests', () {
    test('should store and retrieve biometric enabled status', () async {
      // Test default state
      expect(await biometricService.isBiometricEnabled(), isFalse);

      // Enable biometric
      await biometricService.setBiometricEnabled(true);
      expect(await biometricService.isBiometricEnabled(), isTrue);

      // Disable biometric
      await biometricService.setBiometricEnabled(false);
      expect(await biometricService.isBiometricEnabled(), isFalse);
    });

    test('should store and retrieve biometric key', () async {
      const testKey = 'encrypted_biometric_master_key_12345';
      
      await biometricService.storeBiometricKey(testKey);
      final retrievedKey = await biometricService.getBiometricKey();
      
      expect(retrievedKey, equals(testKey));
    });

    test('should remove biometric key', () async {
      const testKey = 'encrypted_biometric_master_key_12345';
      
      // Store key
      await biometricService.storeBiometricKey(testKey);
      expect(await biometricService.getBiometricKey(), equals(testKey));

      // Remove key
      await biometricService.removeBiometricKey();
      expect(await biometricService.getBiometricKey(), isNull);
    });

    test('should handle biometric type names correctly', () async {
      expect(biometricService.getBiometricTypeName(BiometricType.face), equals('Face ID'));
      expect(biometricService.getBiometricTypeName(BiometricType.fingerprint), equals('Fingerprint'));
      expect(biometricService.getBiometricTypeName(BiometricType.iris), equals('Iris'));
      expect(biometricService.getBiometricTypeName(BiometricType.strong), equals('Strong Biometric'));
      expect(biometricService.getBiometricTypeName(BiometricType.weak), equals('Weak Biometric'));
    });

    test('should handle encryption/decryption errors gracefully', () async {
      // Test with corrupted data in database
      await DatabaseService.instance.updateMetadata('biometric_key', 'corrupted_data');
      
      final retrievedKey = await biometricService.getBiometricKey();
      expect(retrievedKey, isNull);
    });

    test('should handle database errors gracefully', () async {
      // Close database to simulate error
      await DatabaseService.instance.close();
      
      // These should not throw exceptions
      expect(await biometricService.isBiometricEnabled(), isFalse);
      expect(await biometricService.getBiometricKey(), isNull);
    });

    test('should validate biometric authentication flow', () async {
      // Test when biometric is not enabled
      final result = await biometricService.authenticateWithBiometrics();
      expect(result.success, isFalse);
      expect(result.errorType, equals(BiometricAuthError.notEnabled));
    });
  });
}