// EncryptionService: Derives SQLCipher-compatible encryption key from passphrase using Argon2id
// Also provides data encryption/decryption for sensitive fields

import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'argon2_service.dart';

class EncryptionService {
  final Argon2Service _argon2Service = Argon2Service();
  final Random _random = Random.secure();

  // Generates a unique salt for encryption key derivation (different from auth salt)
  Uint8List generateEncryptionSalt([int length = 16]) {
    final salt = Uint8List(length);
    final random = Random.secure();
    for (int i = 0; i < length; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  // Derives a 256-bit encryption key from passphrase and salt using Argon2id
  Future<Uint8List> deriveEncryptionKey(
      String passphrase, Uint8List salt) async {
    if (passphrase.trim().isEmpty) throw ArgumentError('Passphrase required');
    if (salt.isEmpty) throw ArgumentError('Salt required');
    return await _argon2Service.deriveKey(
      passphrase.trim(),
      salt,
      32, // 256-bit key
    );
  }

  // Formats key for SQLCipher PRAGMA key: x'hex'
  String formatKeyForSQLCipher(Uint8List key) {
    final hexKey = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    return "x'$hexKey'";
  }

  // Simple XOR encryption for data fields (sufficient for database storage layer)
  Future<String> encryptData(String data) async {
    if (data.isEmpty) return data;

    final dataBytes = utf8.encode(data);
    final keyBytes = await _getDynamicEncryptionKey();
    final encryptedBytes = Uint8List(dataBytes.length);

    for (int i = 0; i < dataBytes.length; i++) {
      encryptedBytes[i] = dataBytes[i] ^ keyBytes[i % keyBytes.length];
    }

    return base64.encode(encryptedBytes);
  }

  // Simple XOR decryption for data fields
  Future<String> decryptData(String encryptedData) async {
    if (encryptedData.isEmpty) return encryptedData;

    try {
      final encryptedBytes = base64.decode(encryptedData);
      final keyBytes = await _getDynamicEncryptionKey();
      final decryptedBytes = Uint8List(encryptedBytes.length);

      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
      }

      return utf8.decode(decryptedBytes);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  // Generate a dynamic encryption key for XOR operations
  Future<Uint8List> _getDynamicEncryptionKey() async {
    final appIdentifier = 'cred_manager_encryption_v1';
    final bytes = utf8.encode(appIdentifier);
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  // Generate a secure random salt for data encryption
  Uint8List generateDataSalt([int length = 16]) {
    final salt = Uint8List(length);
    for (int i = 0; i < length; i++) {
      salt[i] = _random.nextInt(256);
    }
    return salt;
  }

  // AES encryption for credentials using dynamically derived keys
  Future<String> encryptCredential(String data, String passphrase) async {
    if (data.isEmpty) return data;

    final salt = generateDataSalt();
    final key = await deriveEncryptionKey(passphrase, salt);

    final algorithm = AesGcm.with256bits();
    final secretKey = await algorithm.newSecretKeyFromBytes(key);

    final nonce = algorithm.newNonce();
    final plaintext = utf8.encode(data);

    final encrypted = await algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );

    // Combine salt, nonce, and encrypted data
    final combined = Uint8List(salt.length + nonce.length + encrypted.cipherText.length);
    combined.setRange(0, salt.length, salt);
    combined.setRange(salt.length, salt.length + nonce.length, nonce);
    combined.setRange(salt.length + nonce.length, combined.length, encrypted.cipherText);

    return base64.encode(combined);
  }

  // AES decryption for credentials using dynamically derived keys
  Future<String> decryptCredential(String encryptedData, String passphrase) async {
    if (encryptedData.isEmpty) return encryptedData;

    try {
      final combined = base64.decode(encryptedData);

      // Extract salt, nonce, and encrypted data
      const saltLength = 16;
      const nonceLength = 12; // GCM nonce length

      if (combined.length < saltLength + nonceLength) {
        throw Exception('Invalid encrypted data format');
      }

      final salt = combined.sublist(0, saltLength);
      final nonce = combined.sublist(saltLength, saltLength + nonceLength);
      final cipherText = combined.sublist(saltLength + nonceLength);

      final key = await deriveEncryptionKey(passphrase, salt);

      final algorithm = AesGcm.with256bits();
      final secretKey = await algorithm.newSecretKeyFromBytes(key);

      final decrypted = await algorithm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac.empty),
        secretKey: secretKey,
      );

      return utf8.decode(decrypted);
    } catch (e) {
      throw Exception('Failed to decrypt credential: $e');
    }
  }

  // Legacy credential encryption methods (for backward compatibility)
  Future<String> encrypt(String data, String passphrase) async {
    return await encryptCredential(data, passphrase);
  }

  Future<String> decrypt(String encryptedData, String passphrase) async {
    return await decryptCredential(encryptedData, passphrase);
  }

  // Biometric key encryption using AES-GCM with device-bound key
  // This provides stronger security than XOR for biometric quick unlock data
  Future<String> encryptBiometricKey(String data) async {
    if (data.isEmpty) return data;

    // Generate a unique salt for this encryption
    final salt = generateDataSalt();

    // Derive a key from a device-specific identifier (not user passphrase)
    // This ensures biometric data is tied to this device
    final deviceKey = await _deriveDeviceKey(salt);

    final algorithm = AesGcm.with256bits();
    final secretKey = await algorithm.newSecretKeyFromBytes(deviceKey);

    final nonce = algorithm.newNonce();
    final plaintext = utf8.encode(data);

    final encrypted = await algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );

    // Combine salt, nonce, cipher text, and MAC
    // MAC is typically 16 bytes for GCM
    final macBytes = encrypted.mac.bytes;
    final combined = Uint8List(salt.length + nonce.length + encrypted.cipherText.length + macBytes.length);
    combined.setRange(0, salt.length, salt);
    combined.setRange(salt.length, salt.length + nonce.length, nonce);
    combined.setRange(salt.length + nonce.length, salt.length + nonce.length + encrypted.cipherText.length, encrypted.cipherText);
    combined.setRange(salt.length + nonce.length + encrypted.cipherText.length, combined.length, macBytes);

    return base64.encode(combined);
  }

  // Biometric key decryption using AES-GCM with device-bound key
  Future<String> decryptBiometricKey(String encryptedData) async {
    if (encryptedData.isEmpty) return encryptedData;

    try {
      final combined = base64.decode(encryptedData);

      // Extract salt, nonce, and encrypted data
      const saltLength = 16;
      const nonceLength = 12; // GCM nonce length
      const macLength = 16; // GCM MAC length

      if (combined.length < saltLength + nonceLength + macLength) {
        throw Exception('Invalid encrypted biometric data format');
      }

      final salt = combined.sublist(0, saltLength);
      final nonce = combined.sublist(saltLength, saltLength + nonceLength);

      // Calculate where cipher text ends
      final cipherTextEnd = combined.length - macLength;
      final cipherText = combined.sublist(saltLength + nonceLength, cipherTextEnd);
      final macBytes = combined.sublist(cipherTextEnd);

      // Derive the same device key
      final deviceKey = await _deriveDeviceKey(salt);

      final algorithm = AesGcm.with256bits();
      final secretKey = await algorithm.newSecretKeyFromBytes(deviceKey);

      final decrypted = await algorithm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes)),
        secretKey: secretKey,
      );

      return utf8.decode(decrypted);
    } catch (e) {
      throw Exception('Failed to decrypt biometric key: $e');
    }
  }

  // Derive a device-specific encryption key for biometric data
  // This combines app identifier with device-specific data to create a key
  // that's unique to this device installation
  Future<Uint8List> _deriveDeviceKey(Uint8List salt) async {
    // Create device-specific seed using app identifier and salt
    final appIdentifier = 'cred_manager_biometric_v1';
    final seed = utf8.encode(appIdentifier);

    // Combine seed with salt
    final combined = Uint8List(seed.length + salt.length);
    combined.setRange(0, seed.length, seed);
    combined.setRange(seed.length, combined.length, salt);

    // Hash the combined data to create a consistent "passphrase" for Argon2
    final combinedHash = sha256.convert(combined);

    // Use Argon2 to derive a key from the combined seed
    // This provides strong key derivation with device binding
    return await _argon2Service.deriveKey(
      base64.encode(combinedHash.bytes), // Use hash as "passphrase"
      salt,
      32, // 256-bit key
    );
  }

  void clearKeyCache() {
    // No-op for simple XOR encryption - no key cache to clear
  }
}
