import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/services/argon2_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Argon2Service argon2Service;

  setUp(() {
    argon2Service = Argon2Service();
  });

  group('Argon2 Password Verification - Core Functionality', () {
    test('verifyPassword returns true for correct password', () async {
      // TDD: This test will initially fail until proper implementation
      const password = 'SecurePassword123!';
      
      // First hash the password to get a known good hash
      final hash = await argon2Service.hashPassword(password);
      
      // Verify the same password against the hash
      final result = await argon2Service.verifyPassword(password, hash);
      
      expect(result, isTrue, reason: 'Correct password should verify successfully');
    });

    test('verifyPassword returns false for incorrect password', () async {
      // TDD: This test will initially fail until proper implementation
      const correctPassword = 'SecurePassword123!';
      const wrongPassword = 'WrongPassword456!';
      
      final hash = await argon2Service.hashPassword(correctPassword);
      final result = await argon2Service.verifyPassword(wrongPassword, hash);
      
      expect(result, isFalse, reason: 'Incorrect password should fail verification');
    });

    test('verifyPassword is case-sensitive', () async {
      const password = 'CaseSensitive123!';
      const wrongCasePassword = 'casesensitive123!';
      
      final hash = await argon2Service.hashPassword(password);
      final result = await argon2Service.verifyPassword(wrongCasePassword, hash);
      
      expect(result, isFalse, reason: 'Password verification should be case-sensitive');
    });

    test('verifyPassword handles empty password', () async {
      const emptyPassword = '';
      
      final hash = await argon2Service.hashPassword(emptyPassword);
      final result = await argon2Service.verifyPassword(emptyPassword, hash);
      
      expect(result, isTrue, reason: 'Empty password should verify against its own hash');
    });

    test('verifyPassword returns false for empty password against non-empty hash', () async {
      const password = 'NonEmptyPassword123!';
      const emptyPassword = '';
      
      final hash = await argon2Service.hashPassword(password);
      final result = await argon2Service.verifyPassword(emptyPassword, hash);
      
      expect(result, isFalse, reason: 'Empty password should not verify against non-empty hash');
    });
  });

  group('Argon2 Password Verification - Input Normalization', () {
    test('verifyPassword handles leading whitespace - SHOULD TRIM', () async {
      // TDD: This tests the trimming requirement from the spec
      const cleanPassword = 'TestPassword123!';
      const passwordWithLeadingSpace = '  TestPassword123!';
      
      final hash = await argon2Service.hashPassword(cleanPassword);
      final result = await argon2Service.verifyPassword(passwordWithLeadingSpace, hash);
      
      // This should PASS after implementing trim normalization (currently may fail)
      expect(result, isTrue, reason: 'Leading whitespace should be trimmed before verification');
    });

    test('verifyPassword handles trailing whitespace - SHOULD TRIM', () async {
      // TDD: This tests the trimming requirement from the spec
      const cleanPassword = 'TestPassword123!';
      const passwordWithTrailingSpace = 'TestPassword123!  ';
      
      final hash = await argon2Service.hashPassword(cleanPassword);
      final result = await argon2Service.verifyPassword(passwordWithTrailingSpace, hash);
      
      // This should PASS after implementing trim normalization (currently may fail)
      expect(result, isTrue, reason: 'Trailing whitespace should be trimmed before verification');
    });

    test('verifyPassword handles mixed whitespace - SHOULD TRIM', () async {
      const cleanPassword = 'TestPassword123!';
      const passwordWithMixedSpace = '  TestPassword123!  ';
      
      final hash = await argon2Service.hashPassword(cleanPassword);
      final result = await argon2Service.verifyPassword(passwordWithMixedSpace, hash);
      
      expect(result, isTrue, reason: 'Mixed leading/trailing whitespace should be trimmed');
    });

    test('verifyPassword preserves internal whitespace', () async {
      const passwordWithInternalSpace = 'Test Password 123!';
      
      final hash = await argon2Service.hashPassword(passwordWithInternalSpace);
      final result = await argon2Service.verifyPassword(passwordWithInternalSpace, hash);
      
      expect(result, isTrue, reason: 'Internal whitespace should be preserved');
    });

    test('verifyPassword handles tab and newline characters', () async {
      const cleanPassword = 'TestPassword123!';
      const passwordWithTabs = '\tTestPassword123!\n';
      
      final hash = await argon2Service.hashPassword(cleanPassword);
      final result = await argon2Service.verifyPassword(passwordWithTabs, hash);
      
      expect(result, isTrue, reason: 'Tab and newline characters should be trimmed');
    });
  });

  group('Argon2 Password Verification - Edge Cases and Special Characters', () {
    test('verifyPassword handles special characters', () async {
      const passwordWithSpecialChars = 'Test!@#\$%^&*()_+-=[]{}|;:,.<>?';
      
      final hash = await argon2Service.hashPassword(passwordWithSpecialChars);
      final result = await argon2Service.verifyPassword(passwordWithSpecialChars, hash);
      
      expect(result, isTrue, reason: 'Special characters should be handled correctly');
    });

    test('verifyPassword handles Unicode characters', () async {
      const passwordWithUnicode = 'Test🔐Пароль123ñáéíóú';
      
      final hash = await argon2Service.hashPassword(passwordWithUnicode);
      final result = await argon2Service.verifyPassword(passwordWithUnicode, hash);
      
      expect(result, isTrue, reason: 'Unicode characters should be handled correctly');
    });

    test('verifyPassword handles very long passwords', () async {
      final longPassword = 'A' * 1000 + '!'; // 1001 character password
      
      final hash = await argon2Service.hashPassword(longPassword);
      final result = await argon2Service.verifyPassword(longPassword, hash);
      
      expect(result, isTrue, reason: 'Very long passwords should be handled correctly');
    });

    test('verifyPassword handles password with only whitespace', () async {
      const whitespacePassword = '   ';
      const emptyPassword = '';
      
      final hash = await argon2Service.hashPassword(emptyPassword);
      final result = await argon2Service.verifyPassword(whitespacePassword, hash);
      
      expect(result, isTrue, reason: 'Whitespace-only password should trim to empty and match empty hash');
    });

    test('verifyPassword handles numeric-only passwords', () async {
      const numericPassword = '1234567890';
      
      final hash = await argon2Service.hashPassword(numericPassword);
      final result = await argon2Service.verifyPassword(numericPassword, hash);
      
      expect(result, isTrue, reason: 'Numeric-only passwords should be handled correctly');
    });
  });

  group('Argon2 Password Verification - Error Handling', () {
    test('verifyPassword handles malformed hash format', () async {
      const password = 'TestPassword123!';
      const malformedHash = 'not-a-valid-argon2-hash';
      
      final result = await argon2Service.verifyPassword(password, malformedHash);
      
      expect(result, isFalse, reason: 'Malformed hash should return false, not throw exception');
    });

    test('verifyPassword handles hash with wrong number of parts', () async {
      const password = 'TestPassword123!';
      const invalidHash = '\$argon2id\$v=19\$m=65536,t=1,p=4'; // Missing salt and hash parts
      
      final result = await argon2Service.verifyPassword(password, invalidHash);
      
      expect(result, isFalse, reason: 'Hash with missing parts should return false');
    });

    test('verifyPassword handles hash with invalid algorithm', () async {
      const password = 'TestPassword123!';
      const invalidHash = '\$argon2i\$v=19\$m=65536,t=1,p=4\$c2FsdA==\$aGFzaA=='; // argon2i instead of argon2id
      
      final result = await argon2Service.verifyPassword(password, invalidHash);
      
      expect(result, isFalse, reason: 'Hash with wrong algorithm should return false');
    });

    test('verifyPassword handles hash with invalid version', () async {
      const password = 'TestPassword123!';
      const invalidHash = '\$argon2id\$v=18\$m=65536,t=1,p=4\$c2FsdA==\$aGFzaA=='; // Wrong version
      
      final result = await argon2Service.verifyPassword(password, invalidHash);
      
      expect(result, isFalse, reason: 'Hash with wrong version should return false');
    });

    test('verifyPassword handles invalid base64 in salt', () async {
      const password = 'TestPassword123!';
      const invalidHash = '\$argon2id\$v=19\$m=65536,t=1,p=4\$invalid-base64!\$aGFzaA==';
      
      final result = await argon2Service.verifyPassword(password, invalidHash);
      
      expect(result, isFalse, reason: 'Invalid base64 salt should return false');
    });

    test('verifyPassword handles invalid base64 in hash', () async {
      const password = 'TestPassword123!';
      const invalidHash = '\$argon2id\$v=19\$m=65536,t=1,p=4\$c2FsdA==\$invalid-base64!';
      
      final result = await argon2Service.verifyPassword(password, invalidHash);
      
      expect(result, isFalse, reason: 'Invalid base64 hash should return false');
    });

    test('verifyPassword handles corrupted parameters', () async {
      const password = 'TestPassword123!';
      const invalidHash = '\$argon2id\$v=19\$m=invalid,t=abc,p=xyz\$c2FsdA==\$aGFzaA==';
      
      final result = await argon2Service.verifyPassword(password, invalidHash);
      
      expect(result, isFalse, reason: 'Corrupted parameters should return false');
    });
  });

  group('Argon2 Password Verification - Performance and Security', () {
    test('verifyPassword completes within 500ms', () async {
      const password = 'PerformanceTestPassword123!';
      
      final hash = await argon2Service.hashPassword(password);
      
      final stopwatch = Stopwatch()..start();
      final result = await argon2Service.verifyPassword(password, hash);
      stopwatch.stop();
      
      expect(result, isTrue, reason: 'Verification should succeed');
      expect(stopwatch.elapsedMilliseconds, lessThan(500), 
             reason: 'Verification should complete within 500ms (actual: ${stopwatch.elapsedMilliseconds}ms)');
    });

    test('verifyPassword timing is consistent for different passwords', () async {
      const shortPassword = 'Short1!';
      const longPassword = 'ThisIsAVeryLongPasswordWithManyCharacters123!@#';
      
      final shortHash = await argon2Service.hashPassword(shortPassword);
      final longHash = await argon2Service.hashPassword(longPassword);
      
      // Measure timing for short password
      final stopwatch1 = Stopwatch()..start();
      await argon2Service.verifyPassword(shortPassword, shortHash);
      stopwatch1.stop();
      
      // Measure timing for long password
      final stopwatch2 = Stopwatch()..start();
      await argon2Service.verifyPassword(longPassword, longHash);
      stopwatch2.stop();
      
      // Timing should be relatively consistent (within 50ms difference)
      final timeDifference = (stopwatch1.elapsedMilliseconds - stopwatch2.elapsedMilliseconds).abs();
      expect(timeDifference, lessThan(50), 
             reason: 'Verification timing should be consistent across different password lengths');
    });

    test('verifyPassword handles concurrent verification requests', () async {
      const password1 = 'ConcurrentTest1!';
      const password2 = 'ConcurrentTest2!';
      const password3 = 'ConcurrentTest3!';
      
      final hash1 = await argon2Service.hashPassword(password1);
      final hash2 = await argon2Service.hashPassword(password2);
      final hash3 = await argon2Service.hashPassword(password3);
      
      // Run multiple verifications concurrently
      final futures = <Future<bool>>[
        argon2Service.verifyPassword(password1, hash1),
        argon2Service.verifyPassword(password2, hash2),
        argon2Service.verifyPassword(password3, hash3),
        argon2Service.verifyPassword('wrong', hash1), // Should fail
      ];
      
      final results = await Future.wait(futures);
      
      expect(results[0], isTrue, reason: 'First verification should succeed');
      expect(results[1], isTrue, reason: 'Second verification should succeed');
      expect(results[2], isTrue, reason: 'Third verification should succeed');
      expect(results[3], isFalse, reason: 'Wrong password verification should fail');
    });

    test('constant-time comparison prevents timing attacks', () async {
      const password = 'TimingAttackTest123!';
      final hash = await argon2Service.hashPassword(password);
      
      // Test with passwords that differ at the beginning vs end
      const wrongPasswordStart = 'WrongAttackTest123!'; // Differs at start
      const wrongPasswordEnd = 'TimingAttackTest456!';   // Differs at end
      
      final stopwatch1 = Stopwatch()..start();
      await argon2Service.verifyPassword(wrongPasswordStart, hash);
      stopwatch1.stop();
      
      final stopwatch2 = Stopwatch()..start();
      await argon2Service.verifyPassword(wrongPasswordEnd, hash);
      stopwatch2.stop();
      
      // The timing difference should be minimal (within 50ms) for constant-time comparison
      final timeDifference = (stopwatch1.elapsedMilliseconds - stopwatch2.elapsedMilliseconds).abs();
      expect(timeDifference, lessThan(50),
             reason: 'Timing should be consistent regardless of where passwords differ (timing attack prevention)');
    });
  });

  group('Argon2 Password Verification - Hash Format Validation', () {
    test('verifyPassword works with different Argon2 parameter combinations', () async {
      // This test validates that the service can handle different valid Argon2 parameters
      // if they were to be stored in the hash (future-proofing)
      const password = 'ParameterTest123!';
      
      final hash = await argon2Service.hashPassword(password);
      
      // Ensure the hash contains expected Argon2id format
      expect(hash, startsWith('\$argon2id\$v=19\$'), reason: 'Hash should use Argon2id format');
      expect(hash, contains('m=65536'), reason: 'Hash should contain memory parameter');
      expect(hash, contains('t=1'), reason: 'Hash should contain time parameter');
      expect(hash, contains('p=4'), reason: 'Hash should contain parallelism parameter');
      
      final result = await argon2Service.verifyPassword(password, hash);
      expect(result, isTrue, reason: 'Generated hash should verify correctly');
    });

    test('verifyPassword rejects non-Argon2id hashes', () async {
      const password = 'TestPassword123!';
      
      // Test with various non-Argon2id hash formats
      final invalidHashes = [
        'plaintext_password', // Plain text
        '\$2b\$10\$N9qo8uLOickgx2ZMRZoMye', // BCrypt
        'sha256hash', // SHA-256 style
        '\$argon2i\$v=19\$m=65536,t=1,p=4\$c2FsdA==\$aGFzaA==', // Argon2i (not Argon2id)
      ];
      
      for (final invalidHash in invalidHashes) {
        final result = await argon2Service.verifyPassword(password, invalidHash);
        expect(result, isFalse, reason: 'Non-Argon2id hash should be rejected: $invalidHash');
      }
    });
  });
}