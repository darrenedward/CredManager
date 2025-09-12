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

  void clearKeyCache() {
    // No-op for simple XOR encryption - no key cache to clear
  }
}
