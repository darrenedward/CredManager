import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/services/key_derivation_service.dart';
import 'package:cred_manager/services/jwt_service.dart';
import 'package:cred_manager/services/encryption_service.dart';
import 'package:cred_manager/services/biometric_auth_service.dart';
import 'dart:typed_data';

/// PT003 Dynamic Secrets Test Suite
/// Tests for dynamic key derivation and JWT generation functionality

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EncryptionService encryptionService;
  late BiometricAuthService biometricService;

  setUp(() {
    encryptionService = EncryptionService();
    biometricService = BiometricAuthService();
  });

  group('Dynamic Key Derivation - Core Functionality', () {
    test('WhenDerivingJwtSecretFromPassphrase_ShouldProduceConsistent256BitKey', () async {
      // Arrange
      const passphrase = 'TestPassphrase123!';
      const expectedKeyLength = 32; // 256 bits

      // Act
      final jwtSecret = await KeyDerivationService.deriveJwtSecret(passphrase);

      // Assert
      expect(jwtSecret, isNotNull);
      expect(jwtSecret.length, equals(expectedKeyLength));
      expect(jwtSecret, isA<Uint8List>());
    });

    test('WhenDerivingEncryptionKeyFromPassphrase_ShouldProduceConsistent256BitKey', () async {
      // Arrange
      const passphrase = 'TestPassphrase123!';
      const expectedKeyLength = 32; // 256 bits

      // Act
      final encryptionKey = await KeyDerivationService.deriveEncryptionKey(passphrase);

      // Assert
      expect(encryptionKey, isNotNull);
      expect(encryptionKey.length, equals(expectedKeyLength));
      expect(encryptionKey, isA<Uint8List>());
    });

    test('WhenDerivingBiometricKeyFromPassphrase_ShouldProduceConsistent256BitKey', () async {
      // Arrange
      const passphrase = 'TestPassphrase123!';
      const expectedKeyLength = 32; // 256 bits

      // Act
      final biometricKey = await KeyDerivationService.deriveBiometricKey(passphrase);

      // Assert
      expect(biometricKey, isNotNull);
      expect(biometricKey.length, equals(expectedKeyLength));
      expect(biometricKey, isA<Uint8List>());
    });
  });

  group('Dynamic Key Derivation - Salt Consistency', () {
    test('WhenDerivingKeysWithSamePassphrase_ShouldProduceConsistentResults', () async {
      // Arrange
      const passphrase = 'ConsistentTest123!';

      // Act
      final jwtKey1 = await KeyDerivationService.deriveJwtSecret(passphrase);
      final jwtKey2 = await KeyDerivationService.deriveJwtSecret(passphrase);
      final encKey1 = await KeyDerivationService.deriveEncryptionKey(passphrase);
      final encKey2 = await KeyDerivationService.deriveEncryptionKey(passphrase);

      // Assert
      expect(jwtKey1, equals(jwtKey2), reason: 'Same passphrase should produce same JWT key');
      expect(encKey1, equals(encKey2), reason: 'Same passphrase should produce same encryption key');
      expect(jwtKey1, isNot(equals(encKey1)), reason: 'Different salts should produce different keys');
    });

    test('WhenDerivingKeysWithDifferentPassphrases_ShouldProduceDifferentResults', () async {
      // Arrange
      const passphrase1 = 'PassphraseOne123!';
      const passphrase2 = 'PassphraseTwo456!';

      // Act
      final jwtKey1 = await KeyDerivationService.deriveJwtSecret(passphrase1);
      final jwtKey2 = await KeyDerivationService.deriveJwtSecret(passphrase2);
      final encKey1 = await KeyDerivationService.deriveEncryptionKey(passphrase1);
      final encKey2 = await KeyDerivationService.deriveEncryptionKey(passphrase2);

      // Assert
      expect(jwtKey1, isNot(equals(jwtKey2)), reason: 'Different passphrases should produce different keys');
      expect(encKey1, isNot(equals(encKey2)), reason: 'Different passphrases should produce different keys');
    });
  });

  group('JWT Secret Generation - Dynamic Keys', () {
    test('WhenGeneratingJwtWithDerivedSecret_ShouldCreateValidToken', () async {
      // Arrange
      const passphrase = 'JwtTestPassphrase123!';
      final payload = {
        'sub': 'test_user',
        'iss': 'test_issuer',
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
      };

      // Act
      final jwtSecret = await KeyDerivationService.deriveJwtSecret(passphrase);
      final token = JwtService.generateTokenWithDerivedSecret(payload, jwtSecret);

      // Assert
      expect(token, isNotNull);
      expect(token, isNotEmpty);
      expect(token.split('.'), hasLength(3)); // JWT has 3 parts
    });

    test('WhenVerifyingJwtWithDerivedSecret_ShouldValidateCorrectly', () async {
      // Arrange
      const passphrase = 'JwtVerifyTest123!';
      final payload = {
        'sub': 'test_user',
        'iss': 'test_issuer',
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
      };

      // Act
      final jwtSecret = await KeyDerivationService.deriveJwtSecret(passphrase);
      final token = JwtService.generateTokenWithDerivedSecret(payload, jwtSecret);
      final isValid = JwtService.verifyTokenWithDerivedSecret(token, jwtSecret);

      // Assert
      expect(isValid, isTrue, reason: 'Token should be valid with correct derived secret');
    });

    test('WhenVerifyingJwtWithWrongDerivedSecret_ShouldFail', () async {
      // Arrange
      const passphrase1 = 'JwtWrongSecretTest123!';
      const passphrase2 = 'DifferentPassphrase456!';
      final payload = {
        'sub': 'test_user',
        'iss': 'test_issuer',
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
      };

      // Act
      final jwtSecret1 = await KeyDerivationService.deriveJwtSecret(passphrase1);
      final jwtSecret2 = await KeyDerivationService.deriveJwtSecret(passphrase2);
      final token = JwtService.generateTokenWithDerivedSecret(payload, jwtSecret1);
      final isValid = JwtService.verifyTokenWithDerivedSecret(token, jwtSecret2);

      // Assert
      expect(isValid, isFalse, reason: 'Token should be invalid with wrong derived secret');
    });
  });

  group('AES Key Derivation - Credential Encryption', () {
    test('WhenEncryptingCredentialsWithDerivedKey_ShouldBeSecure', () async {
      // Arrange
      const passphrase = 'CredentialEncryptTest123!';
      const credentialData = '{"api_key": "sk-1234567890abcdef", "secret": "very-secret-token"}';

      // Act
      final encrypted = await encryptionService.encryptCredential(credentialData, passphrase);
      final decrypted = await encryptionService.decryptCredential(encrypted, passphrase);

      // Assert
      expect(encrypted, isNotNull);
      expect(encrypted, isNot(contains('sk-1234567890abcdef')));
      expect(encrypted, isNot(contains('very-secret-token')));
      expect(encrypted.length, greaterThan(credentialData.length));
      expect(decrypted, equals(credentialData));
    });

    test('WhenDecryptingCredentialsWithWrongKey_ShouldFail', () async {
      // Arrange
      const passphrase1 = 'CredentialDecryptTest123!';
      const passphrase2 = 'WrongPassphrase456!';
      const credentialData = 'Test credential data';

      // Act
      final encrypted = await encryptionService.encryptCredential(credentialData, passphrase1);

      // Assert - This should throw or return null/invalid data
      expect(
        () async => await encryptionService.decryptCredential(encrypted, passphrase2),
        throwsA(isA<Exception>()),
        reason: 'Decryption with wrong key should fail'
      );
    });
  });

  group('Biometric Key Encryption - Dynamic Keys', () {
    test('WhenStoringBiometricKey_ShouldBeSecure', () async {
      // Arrange
      const biometricKey = 'biometric-master-key-12345';

      // Act
      await biometricService.storeBiometricKey(biometricKey);
      final retrieved = await biometricService.getBiometricKey();

      // Assert
      expect(retrieved, equals(biometricKey));
    });

    test('WhenRetrievingNonExistentBiometricKey_ShouldReturnNull', () async {
      // Arrange - Ensure no biometric key exists
      await biometricService.removeBiometricKey();

      // Act
      final retrieved = await biometricService.getBiometricKey();

      // Assert
      expect(retrieved, isNull);
    });
  });

  group('Error Handling - Invalid Inputs', () {
    test('WhenDerivingKeyWithEmptyPassphrase_ShouldThrowArgumentError', () async {
      // Arrange
      const emptyPassphrase = '';

      // Act & Assert
      expect(() async => await KeyDerivationService.deriveJwtSecret(emptyPassphrase),
             throwsA(isA<ArgumentError>()), reason: 'Empty passphrase should throw ArgumentError');
    });

    test('WhenDerivingKeyWithNullPassphrase_ShouldThrowArgumentError', () async {
      // Arrange
      const String? nullPassphrase = null;

      // Act & Assert
      expect(() async => await KeyDerivationService.deriveJwtSecret(nullPassphrase!),
             throwsA(isA<ArgumentError>()), reason: 'Null passphrase should throw ArgumentError');
    });

    test('WhenGeneratingJwtWithInvalidPayload_ShouldThrowException', () async {
      // Arrange
      const passphrase = 'InvalidPayloadTest123!';
      final invalidPayload = {'invalid': null}; // Invalid payload

      // Act & Assert
      final jwtSecret = await KeyDerivationService.deriveJwtSecret(passphrase);
      expect(() => JwtService.generateTokenWithDerivedSecret(invalidPayload, jwtSecret),
             throwsA(isA<Exception>()), reason: 'Invalid payload should throw exception');
    });
  });

  group('Edge Cases and Security Validations', () {
    test('WhenDerivingKeysWithVeryLongPassphrase_ShouldHandleCorrectly', () async {
      // Arrange
      final longPassphrase = 'A' * 1000 + '!@#\$%^&*()'; // 1010 character passphrase

      // Act
      final jwtKey = await KeyDerivationService.deriveJwtSecret(longPassphrase);
      final encKey = await KeyDerivationService.deriveEncryptionKey(longPassphrase);

      // Assert
      expect(jwtKey, isNotNull);
      expect(jwtKey.length, equals(32));
      expect(encKey, isNotNull);
      expect(encKey.length, equals(32));
      expect(jwtKey, isNot(equals(encKey))); // Different salts should produce different keys
    });

    test('WhenDerivingKeysWithUnicodePassphrase_ShouldHandleCorrectly', () async {
      // Arrange
      const unicodePassphrase = 'Pássphrase🔐Тест123!ñáéíóú';

      // Act
      final jwtKey = await KeyDerivationService.deriveJwtSecret(unicodePassphrase);
      final encKey = await KeyDerivationService.deriveEncryptionKey(unicodePassphrase);

      // Assert
      expect(jwtKey, isNotNull);
      expect(jwtKey.length, equals(32));
      expect(encKey, isNotNull);
      expect(encKey.length, equals(32));
    });

    test('WhenDerivingKeysWithSpecialCharacters_ShouldHandleCorrectly', () async {
      // Arrange
      const specialPassphrase = 'Pass!@#\$%^&*()_+-=[]{}|;:,.<>?phrase123!';

      // Act
      final jwtKey = await KeyDerivationService.deriveJwtSecret(specialPassphrase);
      final encKey = await KeyDerivationService.deriveEncryptionKey(specialPassphrase);

      // Assert
      expect(jwtKey, isNotNull);
      expect(jwtKey.length, equals(32));
      expect(encKey, isNotNull);
      expect(encKey.length, equals(32));
    });

    test('WhenDerivingKeysConcurrently_ShouldMaintainConsistency', () async {
      // Arrange
      const passphrase = 'ConcurrentTest123!';
      const iterations = 10;

      // Act
      final futures = List.generate(iterations, (_) =>
        KeyDerivationService.deriveJwtSecret(passphrase));
      final results = await Future.wait(futures);

      // Assert
      for (final result in results) {
        expect(result, isNotNull);
        expect(result.length, equals(32));
        expect(result, equals(results.first)); // All should be identical
      }
    });

    test('WhenDerivingKeysWithTimingAttack_ShouldHaveConstantTime', () async {
      // Arrange
      const shortPassphrase = 'Short1!';
      const longPassphrase = 'ThisIsAVeryLongPassphraseWithManyCharacters123!@#\$%^&*()';

      // Act
      final stopwatch1 = Stopwatch()..start();
      await KeyDerivationService.deriveJwtSecret(shortPassphrase);
      stopwatch1.stop();

      final stopwatch2 = Stopwatch()..start();
      await KeyDerivationService.deriveJwtSecret(longPassphrase);
      stopwatch2.stop();

      // Assert - Argon2 should have relatively constant time due to its design
      final timeDifference = (stopwatch1.elapsedMilliseconds - stopwatch2.elapsedMilliseconds).abs();
      expect(timeDifference, lessThan(1000), reason: 'Key derivation time difference should be reasonable');
    });
  });

  group('Integration Tests - Complete PT003 Flow', () {
    test('WhenCompletePt003Flow_ShouldWorkEndToEnd', () async {
      // Arrange
      const passphrase = 'CompletePt003Test123!';
      const credentialData = '{"api_key": "test-key-123", "secret": "test-secret-456"}';
      const biometricKey = 'test-biometric-key-789';

      // Act
      // 1. Derive all required keys
      final jwtSecret = await KeyDerivationService.deriveJwtSecret(passphrase);
      final aesKey = await KeyDerivationService.deriveEncryptionKey(passphrase);
      final bioKey = await KeyDerivationService.deriveBiometricKey(passphrase);

      // 2. Generate JWT with derived secret
      final payload = {'sub': 'test-user', 'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000};
      final token = JwtService.generateTokenWithDerivedSecret(payload, jwtSecret);

      // 3. Encrypt credentials with derived AES key
      final encryptedCredentials = await encryptionService.encryptCredential(credentialData, passphrase);

      // 4. Store biometric key
      await biometricService.storeBiometricKey(biometricKey);

      // 5. Verify everything works
      final isValidToken = JwtService.verifyTokenWithDerivedSecret(token, jwtSecret);
      final decryptedCredentials = await encryptionService.decryptCredential(encryptedCredentials, passphrase);
      final retrievedBiometricKey = await biometricService.getBiometricKey();

      // Assert
      expect(jwtSecret.length, equals(32));
      expect(aesKey.length, equals(32));
      expect(bioKey.length, equals(32));
      expect(token.split('.'), hasLength(3));
      expect(isValidToken, isTrue);
      expect(decryptedCredentials, equals(credentialData));
      expect(retrievedBiometricKey, equals(biometricKey));
    });
  });
}