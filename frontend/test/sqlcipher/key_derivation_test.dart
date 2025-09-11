import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/services/argon2_service.dart';
import 'package:cred_manager/services/database_service.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Argon2Service argon2Service;

  setUp(() {
    argon2Service = Argon2Service();
  });

  group('SQLCipher Key Derivation Tests', () {
    group('Argon2-based Key Derivation', () {
      test('should derive consistent encryption keys from passphrase', () async {
        // TDD: This will fail until Argon2Service.deriveKey method is implemented
        const testPassphrase = 'ConsistentTestPassphrase123!';
        final salt = Uint8List.fromList([
          0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0,
          0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88
        ]);

        // Derive key multiple times with same input
        final key1 = await argon2Service.deriveKey(testPassphrase, salt, 32);
        final key2 = await argon2Service.deriveKey(testPassphrase, salt, 32);
        final key3 = await argon2Service.deriveKey(testPassphrase, salt, 32);

        expect(key1, equals(key2), reason: 'Key derivation should be deterministic');
        expect(key2, equals(key3), reason: 'Key derivation should be consistent');
        expect(key1.length, equals(32), reason: 'Key should be 256 bits (32 bytes)');
      });

      test('should produce different keys with different passphrases', () async {
        // TDD: Verify different passphrases produce different keys
        const passphrase1 = 'FirstPassphrase123!';
        const passphrase2 = 'SecondPassphrase456!';
        final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

        final key1 = await argon2Service.deriveKey(passphrase1, salt, 32);
        final key2 = await argon2Service.deriveKey(passphrase2, salt, 32);

        expect(key1, isNot(equals(key2)), 
               reason: 'Different passphrases should produce different keys');
        expect(key1.length, equals(32));
        expect(key2.length, equals(32));
      });

      test('should produce different keys with different salts', () async {
        // TDD: Verify salt effectiveness
        const testPassphrase = 'SaltTestPassphrase123!';
        final salt1 = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);
        final salt2 = Uint8List.fromList([16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);

        final key1 = await argon2Service.deriveKey(testPassphrase, salt1, 32);
        final key2 = await argon2Service.deriveKey(testPassphrase, salt2, 32);

        expect(key1, isNot(equals(key2)), 
               reason: 'Different salts should produce different keys');
        expect(key1.length, equals(32));
        expect(key2.length, equals(32));
      });

      test('should generate cryptographically strong keys', () async {
        // TDD: Validate key strength and entropy
        const testPassphrase = 'CryptoStrengthTest123!';
        final salt = Uint8List.fromList([
          0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00, 0x11,
          0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99
        ]);

        final derivedKey = await argon2Service.deriveKey(testPassphrase, salt, 32);

        // Key should be exactly 32 bytes
        expect(derivedKey.length, equals(32));

        // Key should not be all zeros
        expect(derivedKey.any((byte) => byte != 0), true,
               reason: 'Key should contain non-zero bytes');

        // Key should not be all same value
        final uniqueBytes = derivedKey.toSet();
        expect(uniqueBytes.length, greaterThan(1),
               reason: 'Key should not be all same byte value');

        // Check for reasonable entropy (at least 50% unique bytes)
        expect(uniqueBytes.length, greaterThan(16),
               reason: 'Key should have reasonable byte distribution');

        // Verify it's not a weak pattern
        expect(derivedKey, isNot(equals(List.generate(32, (i) => i % 256))),
               reason: 'Key should not be a simple pattern');
      });

      test('should handle various key lengths correctly', () async {
        // TDD: Test different key lengths for flexibility
        const testPassphrase = 'KeyLengthTestPassphrase123!';
        final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

        final key16 = await argon2Service.deriveKey(testPassphrase, salt, 16);
        final key32 = await argon2Service.deriveKey(testPassphrase, salt, 32);
        final key64 = await argon2Service.deriveKey(testPassphrase, salt, 64);

        expect(key16.length, equals(16), reason: '128-bit key should be 16 bytes');
        expect(key32.length, equals(32), reason: '256-bit key should be 32 bytes');
        expect(key64.length, equals(64), reason: '512-bit key should be 64 bytes');

        // Different lengths should produce different keys (even from same passphrase)
        expect(key16, isNot(equals(key32.sublist(0, 16))),
               reason: 'Different key lengths should produce different results');
      });

      test('should be resistant to timing attacks', () async {
        // TDD: Verify consistent timing for security
        const passphrase1 = 'ShortPass123!';
        const passphrase2 = 'VeryLongPassphraseWithManyCharacters123!@#$%^&*()';
        final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

        final stopwatch1 = Stopwatch()..start();
        await argon2Service.deriveKey(passphrase1, salt, 32);
        stopwatch1.stop();

        final stopwatch2 = Stopwatch()..start();
        await argon2Service.deriveKey(passphrase2, salt, 32);
        stopwatch2.stop();

        // Timing should be reasonably consistent (within 50% variance)
        final timeDiff = (stopwatch1.elapsedMilliseconds - stopwatch2.elapsedMilliseconds).abs();
        final avgTime = (stopwatch1.elapsedMilliseconds + stopwatch2.elapsedMilliseconds) / 2;
        final variance = timeDiff / avgTime;

        expect(variance, lessThan(0.5),
               reason: 'Key derivation timing should be consistent to prevent timing attacks');
      });
    });

    group('Salt Generation and Management', () {
      test('should generate random salts with sufficient entropy', () async {
        // TDD: Test salt generation for key derivation
        final salt1 = argon2Service.generateSalt(16);
        final salt2 = argon2Service.generateSalt(16);
        final salt3 = argon2Service.generateSalt(16);

        expect(salt1.length, equals(16));
        expect(salt2.length, equals(16));
        expect(salt3.length, equals(16));

        // Salts should be different
        expect(salt1, isNot(equals(salt2)));
        expect(salt2, isNot(equals(salt3)));
        expect(salt1, isNot(equals(salt3)));

        // Salts should not be all zeros
        expect(salt1.any((byte) => byte != 0), true);
        expect(salt2.any((byte) => byte != 0), true);
        expect(salt3.any((byte) => byte != 0), true);
      });

      test('should store and retrieve salts securely', () async {
        // TDD: Test salt persistence for key derivation consistency
        const testPassphrase = 'SaltPersistenceTest123!';
        final originalSalt = argon2Service.generateSalt(16);

        // Store salt (implementation will need to store in encrypted metadata)
        DatabaseService.setPassphrase(testPassphrase);
        final dbService = DatabaseService.instance;
        
        await dbService.updateMetadata('key_derivation_salt', base64.encode(originalSalt));

        // Retrieve salt
        final saltString = await dbService.getMetadata('key_derivation_salt');
        expect(saltString, isNotNull);
        
        final retrievedSalt = Uint8List.fromList(base64.decode(saltString!));
        expect(retrievedSalt, equals(originalSalt));

        // Use retrieved salt for key derivation
        final key1 = await argon2Service.deriveKey(testPassphrase, originalSalt, 32);
        final key2 = await argon2Service.deriveKey(testPassphrase, retrievedSalt, 32);
        
        expect(key1, equals(key2), reason: 'Keys should be identical with same salt');
      });

      test('should handle salt corruption detection', () async {
        // TDD: Test behavior with corrupted salts
        const testPassphrase = 'SaltCorruptionTest123!';
        final validSalt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);
        final corruptedSalt = Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);

        final validKey = await argon2Service.deriveKey(testPassphrase, validSalt, 32);
        final corruptedKey = await argon2Service.deriveKey(testPassphrase, corruptedSalt, 32);

        expect(validKey, isNot(equals(corruptedKey)),
               reason: 'Corrupted salt should produce different key');
        
        // Both should still be valid 32-byte keys
        expect(validKey.length, equals(32));
        expect(corruptedKey.length, equals(32));
      });
    });

    group('SQLCipher Key Format Compatibility', () {
      test('should produce keys compatible with SQLCipher PRAGMA key format', () async {
        // TDD: Verify key format matches SQLCipher expectations
        const testPassphrase = 'SQLCipherCompatTest123!';
        final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

        final derivedKey = await argon2Service.deriveKey(testPassphrase, salt, 32);

        // Convert to hex format for SQLCipher
        final hexKey = derivedKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
        
        expect(hexKey.length, equals(64), reason: '32-byte key should produce 64-character hex string');
        expect(RegExp(r'^[0-9a-f]+$').hasMatch(hexKey), true,
               reason: 'Hex key should contain only valid hex characters');

        // Test that key can be used in SQLCipher PRAGMA format
        final pragmaKey = "x'$hexKey'";
        expect(pragmaKey.startsWith("x'"), true);
        expect(pragmaKey.endsWith("'"), true);
        expect(pragmaKey.length, equals(67)); // x' + 64 chars + '
      });

      test('should handle key derivation with custom Argon2 parameters', () async {
        // TDD: Test customizable Argon2 parameters for security tuning
        const testPassphrase = 'CustomArgon2ParamsTest123!';
        final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

        // Test with different memory costs
        final keyMemory1 = await argon2Service.deriveKeyWithParams(
          testPassphrase, salt, 32, 
          memoryCost: 1024, timeCost: 2, parallelism: 1
        );
        
        final keyMemory2 = await argon2Service.deriveKeyWithParams(
          testPassphrase, salt, 32,
          memoryCost: 2048, timeCost: 2, parallelism: 1
        );

        expect(keyMemory1.length, equals(32));
        expect(keyMemory2.length, equals(32));
        expect(keyMemory1, isNot(equals(keyMemory2)),
               reason: 'Different Argon2 parameters should produce different keys');
      });

      test('should validate minimum security parameters', () async {
        // TDD: Ensure minimum security standards are met
        const testPassphrase = 'SecurityValidationTest123!';
        final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

        // Verify minimum parameters are enforced
        expect(() async {
          await argon2Service.deriveKeyWithParams(
            testPassphrase, salt, 32,
            memoryCost: 512, // Too low
            timeCost: 1,     // Too low
            parallelism: 1
          );
        }, throwsArgumentError, reason: 'Weak Argon2 parameters should be rejected');

        // Valid parameters should work
        final validKey = await argon2Service.deriveKeyWithParams(
          testPassphrase, salt, 32,
          memoryCost: 65536, // 64 MB
          timeCost: 3,       // 3 iterations
          parallelism: 4     // 4 threads
        );

        expect(validKey.length, equals(32));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle empty passphrase gracefully', () async {
        // TDD: Test error handling for invalid inputs
        final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

        expect(() async => await argon2Service.deriveKey('', salt, 32),
               throwsArgumentError,
               reason: 'Empty passphrase should be rejected');
      });

      test('should handle null or empty salt gracefully', () async {
        // TDD: Test salt validation
        const testPassphrase = 'ValidPassphrase123!';

        expect(() async => await argon2Service.deriveKey(testPassphrase, Uint8List(0), 32),
               throwsArgumentError,
               reason: 'Empty salt should be rejected');

        expect(() async => await argon2Service.deriveKey(testPassphrase, Uint8List.fromList([]), 32),
               throwsArgumentError,
               reason: 'Empty salt list should be rejected');
      });

      test('should handle invalid key lengths', () async {
        // TDD: Test key length validation
        const testPassphrase = 'ValidPassphrase123!';
        final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

        expect(() async => await argon2Service.deriveKey(testPassphrase, salt, 0),
               throwsArgumentError,
               reason: 'Zero key length should be rejected');

        expect(() async => await argon2Service.deriveKey(testPassphrase, salt, -1),
               throwsArgumentError,
               reason: 'Negative key length should be rejected');
      });

      test('should handle very long passphrases', () async {
        // TDD: Test with extremely long passphrases
        final longPassphrase = 'A' * 10000; // 10KB passphrase
        final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

        final key = await argon2Service.deriveKey(longPassphrase, salt, 32);
        
        expect(key.length, equals(32));
        expect(key.any((byte) => byte != 0), true,
               reason: 'Long passphrase should still produce valid key');
      });

      test('should handle special characters and Unicode in passphrases', () async {
        // TDD: Test Unicode and special character handling
        const unicodePassphrase = 'Пароль🔐Test123ñáéíóú!@#\$%^&*()';
        final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

        final key = await argon2Service.deriveKey(unicodePassphrase, salt, 32);
        
        expect(key.length, equals(32));
        expect(key.any((byte) => byte != 0), true,
               reason: 'Unicode passphrase should produce valid key');

        // Should be consistent
        final key2 = await argon2Service.deriveKey(unicodePassphrase, salt, 32);
        expect(key, equals(key2), reason: 'Unicode key derivation should be consistent');
      });

      test('should handle memory constraints gracefully', () async {
        // TDD: Test behavior under memory pressure
        const testPassphrase = 'MemoryConstraintTest123!';
        final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

        // Test with high memory cost (may fail or take long time)
        final stopwatch = Stopwatch()..start();
        
        final key = await argon2Service.deriveKeyWithParams(
          testPassphrase, salt, 32,
          memoryCost: 65536, // 64 MB
          timeCost: 1,
          parallelism: 1
        );
        
        stopwatch.stop();
        
        expect(key.length, equals(32));
        // Should complete within reasonable time even with high memory cost
        expect(stopwatch.elapsedMilliseconds, lessThan(10000),
               reason: 'High memory cost should still complete within 10 seconds');
      });
    });

    group('Performance and Security Benchmarks', () {
      test('should meet performance requirements for key derivation', () async {
        // TDD: Verify key derivation performance
        const testPassphrase = 'PerformanceBenchmarkTest123!';
        final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

        final stopwatch = Stopwatch()..start();
        final key = await argon2Service.deriveKey(testPassphrase, salt, 32);
        stopwatch.stop();

        expect(key.length, equals(32));
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
               reason: 'Key derivation should complete within 2 seconds');
        expect(stopwatch.elapsedMilliseconds, greaterThan(100),
               reason: 'Key derivation should take at least 100ms for security');
      });

      test('should resist brute force attacks with sufficient time cost', () async {
        // TDD: Verify security timing requirements
        const testPassphrase = 'BruteForceResistanceTest123!';
        final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

        final trials = <int>[];
        for (int i = 0; i < 5; i++) {
          final stopwatch = Stopwatch()..start();
          await argon2Service.deriveKey(testPassphrase, salt, 32);
          stopwatch.stop();
          trials.add(stopwatch.elapsedMilliseconds);
        }

        final avgTime = trials.reduce((a, b) => a + b) / trials.length;
        
        // Average time should be sufficient to resist brute force
        expect(avgTime, greaterThan(100),
               reason: 'Key derivation should be slow enough to resist brute force');
        
        // Timing should be reasonably consistent
        final maxVariance = trials.map((t) => (t - avgTime).abs()).reduce((a, b) => a > b ? a : b);
        expect(maxVariance / avgTime, lessThan(0.3),
               reason: 'Timing variance should be reasonable');
      });
    });
  });
}