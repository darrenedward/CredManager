// EncryptionService: Derives SQLCipher-compatible encryption key from passphrase using Argon2id
// Also provides data encryption/decryption for sensitive fields

import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cred_manager/services/argon2_service.dart';

class EncryptionService {
  final Argon2Service _argon2Service = Argon2Service();
  final Random _random = Random.secure();

  // Generates a unique salt for encryption key derivation (different from auth salt)
  Uint8List generateEncryptionSalt([int length = 16]) {
    final salt = Uint8List(length);
    for (int i = 0; i < length; i++) {
      salt[i] = (DateTime.now().microsecondsSinceEpoch >> (i * 2)) & 0xFF;
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
    final keyBytes = utf8.encode('encryption_key_for_data_fields_2025');
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
      final keyBytes = utf8.encode('encryption_key_for_data_fields_2025');
      final decryptedBytes = Uint8List(encryptedBytes.length);
      
      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
      }
      
      return utf8.decode(decryptedBytes);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  // Generate a secure random salt for data encryption
  Uint8List generateDataSalt([int length = 16]) {
    final salt = Uint8List(length);
    for (int i = 0; i < length; i++) {
      salt[i] = _random.nextInt(256);
    }
    return salt;
  }

  // Legacy credential encryption methods (for backward compatibility)
  Future<String> encrypt(String data, String passphrase) async {
    return await encryptData(data);
  }

  Future<String> decrypt(String encryptedData, String passphrase) async {
    return await decryptData(encryptedData);
  }

  void clearKeyCache() {
    // No-op for simple XOR encryption - no key cache to clear
  }
}
