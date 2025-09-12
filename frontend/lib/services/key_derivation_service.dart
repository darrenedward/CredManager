import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'argon2_service.dart';

/// Service for deriving cryptographic keys from passphrases using Argon2
/// Implements dynamic key derivation for JWT secrets and encryption keys
class KeyDerivationService {
  /// Salt for JWT secret derivation (different from encryption key salt)
  static const String _jwtSalt = 'jwt_secret_salt_v1';

  /// Salt for encryption key derivation
  static const String _encryptionSalt = 'encryption_key_salt_v1';

  /// Derives a JWT secret key from the user's passphrase
  /// Uses Argon2id with specific parameters for JWT signing
  static Future<Uint8List> deriveJwtSecret(String passphrase) async {
    try {
      final argon2Service = Argon2Service();
      // Use Argon2 to derive a 32-byte key for JWT HMAC-SHA256
      final salt = utf8.encode(_jwtSalt);
      final key = await argon2Service.deriveKey(
        passphrase,
        Uint8List.fromList(salt),
        32, // 256 bits for HMAC-SHA256
      );

      return key;
    } catch (e) {
      throw Exception('Failed to derive JWT secret: $e');
    }
  }

  /// Derives an AES encryption key from the user's passphrase
  /// Uses Argon2id with specific parameters for AES-256 encryption
  static Future<Uint8List> deriveEncryptionKey(String passphrase) async {
    try {
      final argon2Service = Argon2Service();
      // Use Argon2 to derive a 32-byte key for AES-256
      final salt = utf8.encode(_encryptionSalt);
      final key = await argon2Service.deriveKey(
        passphrase,
        Uint8List.fromList(salt),
        32, // 256 bits for AES-256
      );

      return key;
    } catch (e) {
      throw Exception('Failed to derive encryption key: $e');
    }
  }

  /// Derives a biometric key from the user's passphrase
  /// Uses a different salt to ensure uniqueness from other keys
  static Future<Uint8List> deriveBiometricKey(String passphrase) async {
    try {
      final argon2Service = Argon2Service();
      const biometricSalt = 'biometric_key_salt_v1';
      final salt = utf8.encode(biometricSalt);
      final key = await argon2Service.deriveKey(
        passphrase,
        Uint8List.fromList(salt),
        32, // 256 bits for AES-256
      );

      return key;
    } catch (e) {
      throw Exception('Failed to derive biometric key: $e');
    }
  }

  /// Validates that derived keys are consistent for the same passphrase
  /// This is a security check to ensure key derivation is deterministic
  static Future<bool> validateKeyDerivation(String passphrase) async {
    try {
      // Derive keys twice and verify they are identical
      final jwtKey1 = await deriveJwtSecret(passphrase);
      final jwtKey2 = await deriveJwtSecret(passphrase);
      final encKey1 = await deriveEncryptionKey(passphrase);
      final encKey2 = await deriveEncryptionKey(passphrase);

      // Keys should be identical for the same passphrase
      if (!_areKeysEqual(jwtKey1, jwtKey2)) {
        return false;
      }

      if (!_areKeysEqual(encKey1, encKey2)) {
        return false;
      }

      // JWT and encryption keys should be different (different salts)
      if (_areKeysEqual(jwtKey1, encKey1)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Helper method to compare two Uint8List keys
  static bool _areKeysEqual(Uint8List key1, Uint8List key2) {
    if (key1.length != key2.length) {
      return false;
    }

    for (int i = 0; i < key1.length; i++) {
      if (key1[i] != key2[i]) {
        return false;
      }
    }

    return true;
  }
}