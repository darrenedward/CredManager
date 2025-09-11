import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

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
    password = password.trim();
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
    password = password.trim();
    try {
      // Parse Argon2 hash format: $argon2id$v=19$m=...,t=...,p=...$saltB64$hashB64
      final parts = encodedHash.split(r'$');
      if (parts.length != 6) {
        return false;
      }

      if (parts[1] != 'argon2id' || parts[2] != 'v=19') {
        return false;
      }

      final paramSection = parts[3];
      final saltB64 = parts[4];
      final hashB64 = parts[5];

      // Parse parameters dynamically from m=...,t=...,p=...
      int m = _memoryCost;
      int t = _timeCost;
      int p = _parallelism;
      try {
        for (final segment in paramSection.split(',')) {
          final kv = segment.split('=');
          if (kv.length == 2) {
            switch (kv[0]) {
              case 'm':
                m = int.tryParse(kv[1]) ?? m;
                break;
              case 't':
                t = int.tryParse(kv[1]) ?? t;
                break;
              case 'p':
                p = int.tryParse(kv[1]) ?? p;
                break;
            }
          }
        }
      } catch (e) {
        return false;
      }

      final salt = base64.decode(saltB64);
      final storedHash = base64.decode(hashB64);

      // Create Argon2id instance with parsed params
      final argon2dyn = Argon2id(memory: m, parallelism: p, iterations: t, hashLength: storedHash.length);

      final secretKey = SecretKey(utf8.encode(password));
      final derived = await argon2dyn.deriveKey(secretKey: secretKey, nonce: salt);
      final computed = await derived.extractBytes();

      return _constantTimeEquals(storedHash, computed);
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

}
