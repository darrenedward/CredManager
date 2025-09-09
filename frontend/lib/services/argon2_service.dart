import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart';

class Argon2Service {
  static const int _saltLength = 32;
  static const int _keyLength = 32;
  static const int _timeCost = 1;
  static const int _memoryCost = 65536; // 64MB
  static const int _parallelism = 4;

  final Argon2id _argon2 = Argon2id(
    memory: _memoryCost,
    parallelism: _parallelism,
    iterations: _timeCost,
    hashLength: _keyLength,
  );

  /// Generates a cryptographically secure random salt
  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_saltLength, (i) => random.nextInt(256))
    );
  }

  /// Hashes a password using Argon2id (matching backend implementation)
  Future<String> hashPassword(String password) async {
    final salt = _generateSalt();

    final secretKey = SecretKey(utf8.encode(password));
    final nonce = salt;

    final hash = await _argon2.deriveKey(
      secretKey: secretKey,
      nonce: nonce,
    );

    final hashBytes = await hash.extractBytes();

    // Encode salt and hash as base64
    final saltB64 = base64.encode(salt);
    final hashB64 = base64.encode(hashBytes);

    // Format: $argon2id$v=19$m=65536,t=1,p=4$salt$hash
    return '\$argon2id\$v=19\$m=$_memoryCost,t=$_timeCost,p=$_parallelism\$$saltB64\$$hashB64';
  }

  /// Verifies a password against a stored Argon2 hash
  Future<bool> verifyPassword(String password, String encodedHash) async {
    try {
      // Parse the encoded hash
      final parts = encodedHash.split('\$');
      if (parts.length != 6) {
        return false;
      }

      // Extract salt and hash
      final saltB64 = parts[4];
      final hashB64 = parts[5];

      final salt = base64.decode(saltB64);
      final storedHash = base64.decode(hashB64);

      // Hash the provided password with the same parameters
      final secretKey = SecretKey(utf8.encode(password));
      final nonce = Uint8List.fromList(salt);

      final computedHash = await _argon2.deriveKey(
        secretKey: secretKey,
        nonce: nonce,
      );

      final computedHashBytes = await computedHash.extractBytes();

      // Use constant-time comparison to prevent timing attacks
      return _constantTimeEquals(storedHash, computedHashBytes);
    } catch (e) {
      return false;
    }
  }

  /// Constant-time comparison to prevent timing attacks
  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }

    return result == 0;
  }

  /// Migrates from SHA-256 hash to Argon2 hash
  Future<String?> migrateFromSha256(String password, String oldSha256Hash) async {
    // Extract salt from old SHA-256 hash format: hash$salt:salt
    if (!oldSha256Hash.contains('\$salt:')) {
      return null;
    }

    final parts = oldSha256Hash.split('\$salt:');
    final salt = parts[1];

    // Verify the password matches the old hash
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    final computedHash = '${digest.toString()}\$salt:$salt';

    if (computedHash == oldSha256Hash) {
      // Password is correct, create new Argon2 hash
      return await hashPassword(password);
    }

    return null;
  }
}
