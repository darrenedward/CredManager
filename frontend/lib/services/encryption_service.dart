// EncryptionService: Derives SQLCipher-compatible encryption key from passphrase using Argon2id

import 'dart:typed_data';
import 'dart:convert';
import 'package:cred_manager/services/argon2_service.dart';

class EncryptionService {
  final Argon2Service _argon2Service = Argon2Service();

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
}
