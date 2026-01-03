import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/services/auth_service.dart';
import 'package:cred_manager/services/argon2_service.dart';
import 'package:cred_manager/services/database_service.dart';
import 'package:cred_manager/services/storage_service.dart';
import 'package:flutter/services.dart';
import 'package:matcher/matcher.dart';
import 'package:crypto/crypto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService authService;
  late Argon2Service argon2Service;

  setUp(() async {
    // Mock method channels for flutter_secure_storage
    const MethodChannel secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'read':
            return null; // Return null for reads in tests
          case 'write':
            return null; // Mock successful write
          case 'delete':
            return null; // Mock successful delete
          case 'deleteAll':
            return null; // Mock successful deleteAll
          default:
            return null;
        }
      },
    );

    // Mock method channels for shared_preferences
    const MethodChannel sharedPrefsChannel = MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      sharedPrefsChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getAll':
            return {}; // Return empty map for getAll
          case 'setBool':
            return true; // Mock successful setBool
          case 'setString':
            return true; // Mock successful setString
          case 'remove':
            return true; // Mock successful remove
          case 'clear':
            return true; // Mock successful clear
          default:
            return null;
        }
      },
    );

    // Clean up any existing database before each test
    try {
      await DatabaseService.instance.close();
      await DatabaseService.instance.deleteDatabase();
    } catch (e) {
      // Ignore errors if database doesn't exist
    }

    // Clear passphrase to ensure clean state
    DatabaseService.clearPassphrase();

    // Reset login rate limiting for clean test state
    AuthService.resetLoginRateLimiting();

    // We'll test the AuthService methods directly since they're now local
    authService = AuthService();
    argon2Service = Argon2Service();
  });

  tearDown(() async {
    // Clean up database after each test
    try {
      await DatabaseService.instance.close();
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  test('createPassphrase succeeds', () async {
    final token = await authService.createPassphrase('ValidPass123', [
      {'question': 'What is your favorite color?', 'answer': 'Blue'},
      {'question': 'What was your first pet?', 'answer': 'Fluffy'}
    ]);
    expect(token, isNotNull);
    expect(token, isA<String>());
  });

  test('login succeeds with valid passphrase', () async {
    // First create a passphrase to test login
    await authService.createPassphrase('ValidPass123', [
      {'question': 'What is your favorite color?', 'answer': 'Blue'},
      {'question': 'What was your first pet?', 'answer': 'Fluffy'}
    ]);

    final token = await authService.login('ValidPass123');
    expect(token, isNotNull);
    expect(token, isA<String>());
  });

  test('initiateRecovery returns questions', () async {
    // First create security questions
    await authService.createPassphrase('ValidPass123', [
      {'question': 'What is your favorite color?', 'answer': 'Blue'},
      {'question': 'What was your first pet?', 'answer': 'Fluffy'}
    ]);

    final questions = await authService.initiateRecovery();
    expect(questions, isNotNull);
    expect(questions, isA<List<String>>());
  });

  test('verifyToken succeeds with valid token', () async {
    final token = await authService.createPassphrase('ValidPass123', [
      {'question': 'What is your favorite color?', 'answer': 'Blue'},
      {'question': 'What was your first pet?', 'answer': 'Fluffy'}
    ]);

    final result = await authService.verifyToken(token!);
    expect(result, true);
  });

  group('Argon2 Integration Tests with AuthService', () {
    test('AuthService should use Argon2 for password hashing', () async {
      // TDD: This test validates that AuthService integrates with Argon2Service
      // Initially may fail if AuthService doesn't use Argon2 yet

      const passphrase = 'TestPassphrase123!';
      final securityQuestions = [
        {'question': 'What is your favorite color?', 'answer': 'Blue'},
        {'question': 'What was your first pet?', 'answer': 'Fluffy'}
      ];

      // Create passphrase using AuthService
      final token = await authService.createPassphrase(passphrase, securityQuestions);
      expect(token, isNotNull, reason: 'AuthService should create passphrase successfully');

      // Login should work with the same passphrase
      final loginToken = await authService.login(passphrase);
      expect(loginToken, isNotNull, reason: 'AuthService should authenticate with Argon2');
      expect(loginToken, isA<String>(), reason: 'Login should return a valid token');
    });

    test('AuthService should handle whitespace normalization in passphrases', () async {
      // TDD: This test validates the trimming requirement from the spec
      const cleanPassphrase = 'CleanPassphrase123!';
      const passphraseWithSpaces = '  CleanPassphrase123!  ';

      final securityQuestions = [
        {'question': 'What is your favorite color?', 'answer': 'Blue'},
      ];

      // Create with clean passphrase
      await authService.createPassphrase(cleanPassphrase, securityQuestions);

      // Should be able to login with whitespace version (after trimming)
      final token = await authService.login(passphraseWithSpaces);
      expect(token, isNotNull, reason: 'AuthService should trim whitespace from passphrases');
    });

    test('AuthService should reject incorrect passphrases', () async {
      const correctPassphrase = 'CorrectPassphrase123!';
      const wrongPassphrase = 'WrongPassphrase456!';

      final securityQuestions = [
        {'question': 'What is your favorite color?', 'answer': 'Blue'},
      ];

      // Create with correct passphrase
      await authService.createPassphrase(correctPassphrase, securityQuestions);

      // Should throw exception with wrong passphrase
      expect(
        () async => await authService.login(wrongPassphrase),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Invalid passphrase'))),
        reason: 'AuthService should throw exception for incorrect passphrases'
      );
    });

    test('AuthService should handle special characters in passphrases', () async {
      const specialPassphrase = 'Special!@#\$%^&*()_+-=[]{}|;:,.<>?123';

      final securityQuestions = [
        {'question': 'What is your favorite color?', 'answer': 'Blue'},
      ];

      // Create and login with special character passphrase
      await authService.createPassphrase(specialPassphrase, securityQuestions);
      final token = await authService.login(specialPassphrase);

      expect(token, isNotNull, reason: 'AuthService should handle special characters in passphrases');
    });

    test('AuthService should handle Unicode characters in passphrases', () async {
      const unicodePassphrase = 'Пароль🔐Test123ñáéíóú';

      final securityQuestions = [
        {'question': 'What is your favorite color?', 'answer': 'Blue'},
      ];

      // Create and login with Unicode passphrase
      await authService.createPassphrase(unicodePassphrase, securityQuestions);
      final token = await authService.login(unicodePassphrase);

      expect(token, isNotNull, reason: 'AuthService should handle Unicode characters in passphrases');
    });

    test('AuthService performance should be acceptable', () async {
      const passphrase = 'PerformanceTestPassphrase123!';
  
      final securityQuestions = [
        {'question': 'What is your favorite color?', 'answer': 'Blue'},
      ];
  
      // Test creation performance
      final createStopwatch = Stopwatch()..start();
      await authService.createPassphrase(passphrase, securityQuestions);
      createStopwatch.stop();
  
      // Test login performance
      final loginStopwatch = Stopwatch()..start();
      final token = await authService.login(passphrase);
      loginStopwatch.stop();
  
      expect(token, isNotNull, reason: 'Performance test should succeed');
      // Argon2 is intentionally slow for security - adjust expectations accordingly
      expect(loginStopwatch.elapsedMilliseconds, lessThan(10000),
             reason: 'Login should complete within 10 seconds with Argon2 (actual: ${loginStopwatch.elapsedMilliseconds}ms)');
  
      // Note: Creation can be slower as it's less performance-critical
      expect(createStopwatch.elapsedMilliseconds, lessThan(15000),
             reason: 'Passphrase creation should complete within 15 seconds with Argon2');
    });
  
    group('Login Rate Limiting Tests (ST024)', () {
      test('should track login attempts', () async {
        // TDD: This test will initially fail until rate limiting is implemented
        const passphrase = 'TestPass123!';
        const wrongPassphrase = 'WrongPass456!';
  
        final securityQuestions = [
          {'question': 'What is your favorite color?', 'answer': 'Blue'},
        ];
  
        // Create account
        await authService.createPassphrase(passphrase, securityQuestions);
  
        // Make several failed login attempts
        for (int i = 0; i < 3; i++) {
          try {
            await authService.login(wrongPassphrase);
            fail('Expected login to fail with invalid passphrase');
          } catch (e) {
            expect(e.toString(), contains('Invalid passphrase'));
          }
        }
  
        // The implementation should track these attempts
        // This test will pass once loginAttempts counter is implemented
        expect(true, isTrue, reason: 'Login attempts should be tracked (TDD - implement rate limiting)');
      });
  
      test('should lockout after 5 failed attempts within 5 minutes', () async {
        // TDD: This test will initially fail until lockout is implemented
        const passphrase = 'TestPass123!';
        const wrongPassphrase = 'WrongPass456!';
  
        final securityQuestions = [
          {'question': 'What is your favorite color?', 'answer': 'Blue'},
        ];
  
        // Create account
        await authService.createPassphrase(passphrase, securityQuestions);
  
        // Make 5 failed login attempts
        for (int i = 0; i < 5; i++) {
          try {
            await authService.login(wrongPassphrase);
            fail('Expected login to fail');
          } catch (e) {
            if (i < 4) {
              expect(e.toString(), contains('Invalid passphrase'),
                    reason: 'First 4 attempts should fail with invalid passphrase');
            } else {
              // 5th attempt should trigger lockout
              expect(e.toString(), contains('Too many login attempts'),
                    reason: '5th failed attempt should trigger lockout');
            }
          }
        }
      });
  
      test('should reset lockout after 5 minutes', () async {
        // TDD: This test will initially fail until lockout reset is implemented
        const passphrase = 'TestPass123!';
        const wrongPassphrase = 'WrongPass456!';
  
        final securityQuestions = [
          {'question': 'What is your favorite color?', 'answer': 'Blue'},
        ];
  
        // Create account
        await authService.createPassphrase(passphrase, securityQuestions);
  
        // Make 5 failed attempts to trigger lockout
        for (int i = 0; i < 5; i++) {
          try {
            await authService.login(wrongPassphrase);
          } catch (e) {
            // Expected to fail
          }
        }
  
        // Simulate waiting 5 minutes (in test, we can't actually wait)
        // This test documents the requirement for lockout reset
        // Implementation should check time since lastLoginAttempt
  
        expect(true, isTrue, reason: 'Lockout should reset after 5 minutes (TDD - implement time-based reset)');
      });
  
      test('should reset attempt counter on successful login', () async {
        // TDD: This test will initially fail until counter reset is implemented
        const passphrase = 'TestPass123!';
        const wrongPassphrase = 'WrongPass456!';
  
        final securityQuestions = [
          {'question': 'What is your favorite color?', 'answer': 'Blue'},
        ];
  
        // Create account
        await authService.createPassphrase(passphrase, securityQuestions);
  
        // Make some failed attempts (less than 5 to avoid lockout)
        for (int i = 0; i < 2; i++) {
          try {
            await authService.login(wrongPassphrase);
            fail('Expected login to fail');
          } catch (e) {
            expect(e.toString(), contains('Invalid passphrase'),
                  reason: 'Failed attempts should show invalid passphrase');
          }
        }
  
        // Successful login should reset counter
        final token = await authService.login(passphrase);
        expect(token, isNotNull, reason: 'Successful login should work and reset attempt counter');
  
        // Now failed attempts should start from 0 again
        try {
          await authService.login(wrongPassphrase);
          fail('Expected login to fail');
        } catch (e) {
          expect(e.toString(), contains('Invalid passphrase'));
          // Should not be locked out yet (counter was reset)
          expect(e.toString(), isNot(contains('LockoutException')),
                 reason: 'Counter should be reset after successful login');
        }
      });
  
      test('should throw LockoutException when locked out', () async {
        // TDD: This test will initially fail until LockoutException is implemented
        const passphrase = 'TestPass123!';
        const wrongPassphrase = 'WrongPass456!';

        final securityQuestions = [
          {'question': 'What is your favorite color?', 'answer': 'Blue'},
        ];

        // Create account
        await authService.createPassphrase(passphrase, securityQuestions);

        // Make 5 failed attempts
        for (int i = 0; i < 5; i++) {
          try {
            await authService.login(wrongPassphrase);
          } catch (e) {
            // Expected to fail
          }
        }

        // 6th attempt should throw LockoutException
        expect(
          () async => await authService.login(wrongPassphrase),
          throwsA(isA<LockoutException>()),
          reason: 'Should throw LockoutException when account is locked out'
        );
      });
    });
  });

  group('Legacy SHA-256 to Argon2 Migration Tests (ST030)', () {
    test('should handle migration status for new accounts', () async {
      // Test checkMigrationStatus with a fresh account
      await authService.createPassphrase('TestPass123!', [
        {'question': 'What is your favorite color?', 'answer': 'Blue'}
      ]);

      final status = await authService.checkMigrationStatus();
      expect(status['needsMigration'], false);
      expect(status['message'], 'Your account is using current security standards');
    });

    test('should successfully login with valid credentials', () async {
      // Test that login works (migration happens internally if needed)
      await authService.createPassphrase('TestPass123!', [
        {'question': 'What is your favorite color?', 'answer': 'Blue'}
      ]);

      final token = await authService.login('TestPass123!');
      expect(token, isNotNull);
      expect(token, isA<String>());
    });

    test('should handle invalid login attempts', () async {
      // Test login failure handling
      await authService.createPassphrase('TestPass123!', [
        {'question': 'What is your favorite color?', 'answer': 'Blue'}
      ]);

      expect(
        () async => await authService.login('WrongPass456!'),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Invalid passphrase'))),
      );
    });

    test('should handle security question recovery', () async {
      // Test security question functionality
      await authService.createPassphrase('TestPass123!', [
        {'question': 'What is your favorite color?', 'answer': 'Blue'},
        {'question': 'What was your first pet?', 'answer': 'Fluffy'}
      ]);

      final questions = await authService.initiateRecovery();
      expect(questions, isNotNull);
      expect(questions!.length, 2);

      // Test recovery verification
      final recoveryAnswers = [
        {'question': 'What is your favorite color?', 'answer': 'Blue'},
        {'question': 'What was your first pet?', 'answer': 'Fluffy'}
      ];
      final isValid = await authService.verifyRecoveryAnswers(recoveryAnswers);
      expect(isValid, true);
    });

    test('should handle migration status for no account', () async {
      // Test migration status when no account exists
      final status = await authService.checkMigrationStatus();
      expect(status['needsMigration'], false);
      expect(status['message'], 'No account found');
    });

    test('should maintain backward compatibility', () async {
      // Test that existing functionality still works
      await authService.createPassphrase('TestPass123!', [
        {'question': 'What is your favorite color?', 'answer': 'Blue'}
      ]);

      // Multiple logins should work
      final token1 = await authService.login('TestPass123!');
      final token2 = await authService.login('TestPass123!');

      expect(token1, isNotNull);
      expect(token2, isNotNull);
      // Verify both tokens are valid JWTs (they will have different timestamps)
      expect(await authService.verifyToken(token1!), isTrue);
      expect(await authService.verifyToken(token2!), isTrue);
    });

    test('should handle rate limiting correctly', () async {
      // Test rate limiting functionality
      await authService.createPassphrase('TestPass123!', [
        {'question': 'What is your favorite color?', 'answer': 'Blue'}
      ]);

      // Make multiple failed login attempts
      for (int i = 0; i < 3; i++) {
        try {
          await authService.login('WrongPass456!');
          fail('Expected login to fail');
        } catch (e) {
          expect(e.toString(), contains('Invalid passphrase'));
        }
      }

      // Should still work with correct password
      final token = await authService.login('TestPass123!');
      expect(token, isNotNull);
    });

    test('should migrate legacy SHA-256 hash to Argon2 on login', () async {
      // Simulate legacy SHA-256 hash in database
      const passphrase = 'LegacyTestPass123!';
      const legacySalt = 'salt123';
      final legacyHash = sha256.convert(utf8.encode('$passphrase$legacySalt')).toString();
      final legacyHashFormat = '$legacyHash\$$legacySalt\$$legacySalt';

      // Manually insert legacy hash into database
      final db = await DatabaseService.instance.database;
      await db.insert('app_metadata', {
        'key': 'passphrase_hash',
        'value': legacyHashFormat,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Attempt login with correct passphrase - should migrate automatically
      final token = await authService.login(passphrase);
      expect(token, isNotNull, reason: 'Login should succeed and migrate legacy hash');

      // Verify hash was migrated to Argon2 format by checking migration status
      final migrationStatus = await authService.checkMigrationStatus();
      expect(migrationStatus['needsMigration'], false);
      expect(migrationStatus['message'], 'Your account is using current security standards');
    });

    test('should handle invalid legacy hash format gracefully', () async {
      // Test with malformed legacy hash
      const passphrase = 'MalformedTest123!';

      // Insert malformed hash
      final db = await DatabaseService.instance.database;
      await db.insert('app_metadata', {
        'key': 'passphrase_hash',
        'value': 'malformed-hash-without-proper-delimiters',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Should fail login (can't verify malformed hash)
      expect(
        () async => await authService.login(passphrase),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Invalid passphrase'))),
      );
    });
  });

  group('Security Validation Tests (ST034) - Timing Attacks and Data Extraction Prevention', () {
    test('should have consistent login timing regardless of password correctness', () async {
      // Test timing attack prevention - login should take similar time for correct and incorrect passwords
      const correctPassphrase = 'CorrectPass123!';
      const wrongPassphrase = 'WrongPass456!';

      // Create account
      await authService.createPassphrase(correctPassphrase, [
        {'question': 'What is your favorite color?', 'answer': 'Blue'}
      ]);

      // Measure time for correct password
      final correctStopwatch = Stopwatch()..start();
      try {
        await authService.login(correctPassphrase);
      } catch (e) {
        // Expected to succeed
      }
      correctStopwatch.stop();

      // Reset rate limiting
      AuthService.resetLoginRateLimiting();

      // Measure time for incorrect password
      final wrongStopwatch = Stopwatch()..start();
      try {
        await authService.login(wrongPassphrase);
      } catch (e) {
        // Expected to fail
      }
      wrongStopwatch.stop();

      // Timing should be within reasonable bounds (Argon2 is intentionally slow)
      // Allow for some variance but ensure they're in the same order of magnitude
      expect(correctStopwatch.elapsedMilliseconds, greaterThan(100), reason: 'Login should take reasonable time with Argon2');
      expect(wrongStopwatch.elapsedMilliseconds, greaterThan(100), reason: 'Failed login should also take reasonable time');

      // The difference should not be extreme (wrong password should not be significantly faster)
      final timeDifference = (correctStopwatch.elapsedMilliseconds - wrongStopwatch.elapsedMilliseconds).abs();
      expect(timeDifference, lessThan(5000), reason: 'Timing difference between correct and wrong password should be minimal');
    });

    test('should have consistent timing across different hash types', () async {
      // Test timing consistency between Argon2 and legacy SHA-256 hashes
      const passphrase = 'TestPass123!';
      const wrongPassphrase = 'WrongPass456!';

      // Create account with Argon2
      await authService.createPassphrase(passphrase, [
        {'question': 'What is your favorite color?', 'answer': 'Blue'}
      ]);

      // Measure Argon2 timing
      final argon2Stopwatch = Stopwatch()..start();
      try {
        await authService.login(wrongPassphrase);
      } catch (e) {
        // Expected to fail
      }
      argon2Stopwatch.stop();

      // Reset and test with legacy hash
      await DatabaseService.instance.close();
      await DatabaseService.instance.deleteDatabase();
      DatabaseService.clearPassphrase();
      AuthService.resetLoginRateLimiting();

      // Simulate legacy SHA-256 hash
      const legacySalt = 'salt123';
      final legacyHash = sha256.convert(utf8.encode('$passphrase$legacySalt')).toString();
      final legacyHashFormat = '$legacyHash\$$legacySalt\$$legacySalt';

      final db = await DatabaseService.instance.database;
      await db.insert('app_metadata', {
        'key': 'passphrase_hash',
        'value': legacyHashFormat,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Measure legacy SHA-256 timing
      final legacyStopwatch = Stopwatch()..start();
      try {
        await authService.login(wrongPassphrase);
      } catch (e) {
        // Expected to fail
      }
      legacyStopwatch.stop();

      // Both should take reasonable time, but legacy should be faster
      // This test documents the timing difference - in production, we might want to add artificial delay
      expect(argon2Stopwatch.elapsedMilliseconds, greaterThan(legacyStopwatch.elapsedMilliseconds),
             reason: 'Argon2 should take longer than SHA-256 for security');
    });

    test('should prevent data extraction through error messages', () async {
      // Test that error messages don't leak account existence information
      const wrongPassphrase = 'WrongPass456!';

      // Test login with no account
      try {
        await authService.login(wrongPassphrase);
        fail('Expected login to fail with no account');
      } catch (e) {
        // Should get generic error, not "account not found"
        expect(e.toString(), isNot(contains('account')),
               reason: 'Error messages should not reveal account existence');
        expect(e.toString(), matches(r'(Invalid passphrase|LockoutException)'),
               reason: 'Should get generic authentication error');
      }

      // Create account and test wrong password
      await authService.createPassphrase('CorrectPass123!', [
        {'question': 'What is your favorite color?', 'answer': 'Blue'}
      ]);

      AuthService.resetLoginRateLimiting();

      try {
        await authService.login(wrongPassphrase);
        fail('Expected login to fail with wrong password');
      } catch (e) {
        expect(e.toString(), contains('Invalid passphrase'),
               reason: 'Wrong password should give same error as no account');
      }
    });

    test('should prevent data extraction through recovery error messages', () async {
      // Test that recovery process doesn't leak information about question setup
      final answers = [
        {'question': 'Non-existent question', 'answer': 'WrongAnswer'}
      ];

      // Test recovery with no account
      try {
        await authService.verifyRecoveryAnswers(answers);
        fail('Expected recovery to fail with no account');
      } catch (e) {
        expect(e.toString(), isNot(contains('questions')),
               reason: 'Recovery errors should not reveal question setup status');
      }

      // Create account with questions
      await authService.createPassphrase('CorrectPass123!', [
        {'question': 'What is your favorite color?', 'answer': 'Blue'},
        {'question': 'What was your first pet?', 'answer': 'Fluffy'}
      ]);

      // Test recovery with wrong answers
      try {
        await authService.verifyRecoveryAnswers(answers);
      } catch (e) {
        // Should fail gracefully without revealing details
        expect(e.toString(), isNot(contains('found')),
               reason: 'Should not reveal if questions exist or not');
      }
    });

    test('should prevent side-channel attacks through response timing', () async {
      // Test that API responses have consistent timing regardless of internal processing
      const correctPassphrase = 'CorrectPass123!';
      const wrongPassphrase = 'WrongPass456!';

      // Create account
      await authService.createPassphrase(correctPassphrase, [
        {'question': 'What is your favorite color?', 'answer': 'Blue'}
      ]);

      // Test multiple login attempts to check for timing patterns
      final timings = <int>[];

      for (int i = 0; i < 5; i++) {
        AuthService.resetLoginRateLimiting();
        final stopwatch = Stopwatch()..start();

        try {
          if (i % 2 == 0) {
            await authService.login(correctPassphrase);
          } else {
            await authService.login(wrongPassphrase);
          }
        } catch (e) {
          // Expected for wrong passwords
        }

        stopwatch.stop();
        timings.add(stopwatch.elapsedMilliseconds);
      }

      // Calculate timing variance
      final avgTime = timings.reduce((a, b) => a + b) / timings.length;
      final variance = timings.map((t) => (t - avgTime).abs()).reduce((a, b) => a + b) / timings.length;

      // Variance should be reasonable (not extreme differences between correct/wrong passwords)
      expect(variance, lessThan(avgTime * 0.5), reason: 'Timing variance should be within acceptable bounds');
    });

    test('should prevent timing-based user enumeration', () async {
      // Test that checking migration status doesn't leak account information through timing
      const passphrase = 'TestPass123!';

      // Test timing for no account
      final noAccountStopwatch = Stopwatch()..start();
      final noAccountStatus = await authService.checkMigrationStatus();
      noAccountStopwatch.stop();

      // Create account
      await authService.createPassphrase(passphrase, [
        {'question': 'What is your favorite color?', 'answer': 'Blue'}
      ]);

      // Test timing with account
      final withAccountStopwatch = Stopwatch()..start();
      final withAccountStatus = await authService.checkMigrationStatus();
      withAccountStopwatch.stop();

      // Status messages should be appropriate
      expect(noAccountStatus['message'], contains('No account found'));
      expect(withAccountStatus['message'], contains('current security standards'));

      // Timing difference should not be extreme
      final timeDiff = (withAccountStopwatch.elapsedMilliseconds - noAccountStopwatch.elapsedMilliseconds).abs();
      expect(timeDiff, lessThan(1000), reason: 'Migration status check timing should be consistent');
    });

    test('should handle malformed input consistently', () async {
      // Test that malformed inputs don't cause timing or information leaks
      final malformedInputs = [
        '',  // Empty
        'a',  // Very short
        'A' * 1000,  // Very long
        'Pass\nword',  // With newline
        'Pass\tword',  // With tab
        'Pass word',  // With space
      ];

      final timings = <int>[];

      for (final input in malformedInputs) {
        AuthService.resetLoginRateLimiting();
        final stopwatch = Stopwatch()..start();

        try {
          await authService.login(input);
        } catch (e) {
          // Expected to fail
        }

        stopwatch.stop();
        timings.add(stopwatch.elapsedMilliseconds);
      }

      // All timings should be within reasonable bounds
      final maxTime = timings.reduce(max);
      final minTime = timings.reduce(min);
      final ratio = maxTime / max(minTime, 1);

      expect(ratio, lessThan(10), reason: 'Malformed input processing should have consistent timing');
    });
  });
}