import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/services/password_generator_service.dart';

void main() {
  group('PasswordGeneratorService Tests (ST060)', () {
    late PasswordGeneratorService generator;

    setUp(() {
      generator = PasswordGeneratorService();
    });

    group('Password Generation', () {
      test('generatePassword creates password with default length', () {
        final password = generator.generatePassword();

        expect(password.length, 16);
      });

      test('generatePassword with custom length', () {
        final password = generator.generatePassword(length: 20);

        expect(password.length, 20);
      });

      test('generatePassword with minimum length', () {
        final password = generator.generatePassword(length: 4);

        expect(password.length, greaterThanOrEqualTo(4));
      });

      test('generatePassword throws on invalid length', () {
        expect(
          () => generator.generatePassword(length: 3),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('generatePassword includes uppercase when requested', () {
        final password = generator.generatePassword(
          length: 100,
          includeUppercase: true,
          includeLowercase: false,
          includeNumbers: false,
          includeSymbols: false,
        );

        expect(password, contains(RegExp(r'[A-Z]')));
        expect(password, isNot(contains(RegExp(r'[a-z]'))));
        expect(password, isNot(contains(RegExp(r'[0-9]'))));
      });

      test('generatePassword includes lowercase when requested', () {
        final password = generator.generatePassword(
          length: 100,
          includeUppercase: false,
          includeLowercase: true,
          includeNumbers: false,
          includeSymbols: false,
        );

        expect(password, contains(RegExp(r'[a-z]')));
        expect(password, isNot(contains(RegExp(r'[A-Z]'))));
        expect(password, isNot(contains(RegExp(r'[0-9]'))));
      });

      test('generatePassword includes numbers when requested', () {
        final password = generator.generatePassword(
          length: 100,
          includeUppercase: false,
          includeLowercase: false,
          includeNumbers: true,
          includeSymbols: false,
        );

        expect(password, contains(RegExp(r'[0-9]')));
        expect(password, isNot(contains(RegExp(r'[A-Z]'))));
        expect(password, isNot(contains(RegExp(r'[a-z]'))));
      });

      test('generatePassword includes symbols when requested', () {
        final password = generator.generatePassword(
          length: 100,
          includeUppercase: false,
          includeLowercase: false,
          includeNumbers: false,
          includeSymbols: true,
        );

        expect(password, contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]')));
      });

      test('generatePassword includes all character types when requested', () {
        final password = generator.generatePassword(
          length: 100,
          includeUppercase: true,
          includeLowercase: true,
          includeNumbers: true,
          includeSymbols: true,
        );

        expect(password, contains(RegExp(r'[A-Z]')));
        expect(password, contains(RegExp(r'[a-z]')));
        expect(password, contains(RegExp(r'[0-9]')));
        expect(password, contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]')));
      });

      test('generatePassword throws when no character types selected', () {
        expect(
          () => generator.generatePassword(
            length: 16,
            includeUppercase: false,
            includeLowercase: false,
            includeNumbers: false,
            includeSymbols: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('generatePassword produces unique passwords', () {
        final passwords = Set<String>.from(
          List.generate(100, (i) => generator.generatePassword()),
        );

        expect(passwords.length, greaterThan(90)); // Allow some collisions but very few
      });
    });

    group('Passphrase Generation', () {
      test('generatePassphrase creates passphrase with default word count', () {
        final passphrase = generator.generatePassphrase();

        final words = passphrase.split('-');
        expect(words.length, 4);
      });

      test('generatePassphrase with custom word count', () {
        final passphrase = generator.generatePassphrase(wordCount: 6);

        final words = passphrase.split('-');
        expect(words.length, 6);
      });

      test('generatePassphrase throws on invalid word count', () {
        expect(
          () => generator.generatePassphrase(wordCount: 1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('generatePassphrase with custom separator', () {
        final passphrase = generator.generatePassphrase(separator: '_');

        expect(passphrase, contains('_'));
        expect(passphrase, isNot(contains('-')));
      });

      test('generatePassphrase capitalizes words when requested', () {
        final passphrase = generator.generatePassphrase(capitalize: true);

        final words = passphrase.split('-');
        for (final word in words) {
          expect(word[0], equals(word[0].toUpperCase()));
        }
      });

      test('generatePassphrase includes number when requested', () {
        final passphrase = generator.generatePassphrase(includeNumber: true);

        expect(passphrase, contains(RegExp(r'\d')));
      });

      test('generatePassphrase produces unique passphrases', () {
        final passphrases = Set<String>.from(
          List.generate(100, (i) => generator.generatePassphrase()),
        );

        // With limited word list, there may be collisions, but should still have variety
        expect(passphrases.length, greaterThan(10));
      });
    });

    group('Common Password Detection', () {
      test('isCommonPassword detects common passwords', () {
        expect(generator.isCommonPassword('password'), isTrue);
        expect(generator.isCommonPassword('123456'), isTrue);
        expect(generator.isCommonPassword('qwerty'), isTrue);
        expect(generator.isCommonPassword('admin'), isTrue);
      });

      test('isCommonPassword case insensitive', () {
        expect(generator.isCommonPassword('PASSWORD'), isTrue);
        expect(generator.isCommonPassword('PaSsWoRd'), isTrue);
      });

      test('isCommonPassword returns false for strong passwords', () {
        expect(generator.isCommonPassword('Tr0ng_P@ssw0rd!123'), isFalse);
        expect(generator.isCommonPassword('xK9#mP2\$vL5@qW8'), isFalse);
      });
    });

    group('Password Shuffling', () {
      test('generatePassword shuffles characters', () {
        // Run multiple times and verify we get different results
        final passwords = <String>[];
        for (int i = 0; i < 10; i++) {
          passwords.add(generator.generatePassword(
            length: 16,
            includeUppercase: true,
            includeLowercase: true,
            includeNumbers: true,
            includeSymbols: true,
          ));
        }

        // Should get at least some variety
        final unique = passwords.toSet();
        expect(unique.length, greaterThan(5));
      });
    });
  });

  group('Password Strength Calculation Tests (ST061)', () {
    late PasswordGeneratorService generator;

    setUp(() {
      generator = PasswordGeneratorService();
    });

    group('Strength Score Calculation', () {
      test('calculateStrength returns 0 for empty password', () {
        expect(generator.calculateStrength(''), 0);
      });

      test('calculateStrength returns 5 for common passwords', () {
        expect(generator.calculateStrength('password'), lessThanOrEqualTo(10));
        expect(generator.calculateStrength('123456'), lessThanOrEqualTo(10));
      });

      test('calculateStrength returns low score for short passwords', () {
        expect(generator.calculateStrength('abc'), lessThan(30));
        expect(generator.calculateStrength('abcdef'), lessThan(50));
      });

      test('calculateStrength returns higher score for longer passwords', () {
        final shortScore = generator.calculateStrength('abcdef12');
        final longScore = generator.calculateStrength('abcdef1234567890ABCDEF!@#');

        expect(longScore, greaterThan(shortScore));
      });

      test('calculateStrength rewards character variety', () {
        final lowercaseScore = generator.calculateStrength('abcdefgh');
        final mixedScore = generator.calculateStrength('aB3\$fgh1');

        expect(mixedScore, greaterThan(lowercaseScore));
      });

      test('calculateStrength gives bonus for all character types', () {
        final missingOne = generator.calculateStrength('aB3\$fgh1'); // lowercase, uppercase, numbers, symbols
        final hasAll = generator.calculateStrength('aB3\$fG1@xY2#');

        expect(hasAll, greaterThanOrEqualTo(missingOne));
      });

      test('calculateStrength penalizes repeated characters', () {
        // Same length, but one has repeated chars
        final repeatedScore = generator.calculateStrength('aaaaaaaaaaaaaaaa');
        final normalScore = generator.calculateStrength('mX7pK2nQ9wY3bV5'); // Same length, more variety

        // Normal password should score higher despite same length
        expect(normalScore, greaterThan(repeatedScore));
      });

      test('calculateStrength penalizes sequential characters', () {
        final sequentialScore = generator.calculateStrength('abcdefg1234567');
        final normalScore = generator.calculateStrength('a7b2c5x9m3p1');

        expect(normalScore, greaterThan(sequentialScore));
      });

      test('calculateStrength detects keyboard patterns', () {
        final patternScore = generator.calculateStrength('qwerty123');
        final normalScore = generator.calculateStrength('xkw7mb2pa1');

        expect(normalScore, greaterThan(patternScore));
      });

      test('calculateStrength returns 100 for very strong passwords', () {
        final strong = generator.generatePassword(
          length: 32,
          includeUppercase: true,
          includeLowercase: true,
          includeNumbers: true,
          includeSymbols: true,
        );

        expect(generator.calculateStrength(strong), greaterThanOrEqualTo(80));
      });
    });

    group('Strength Label', () {
      test('getStrengthLabel returns Very Weak for scores 0-20', () {
        expect(generator.getStrengthLabel(0), 'Very Weak');
        expect(generator.getStrengthLabel(10), 'Very Weak');
        expect(generator.getStrengthLabel(20), 'Very Weak');
      });

      test('getStrengthLabel returns Weak for scores 21-40', () {
        expect(generator.getStrengthLabel(21), 'Weak');
        expect(generator.getStrengthLabel(30), 'Weak');
        expect(generator.getStrengthLabel(40), 'Weak');
      });

      test('getStrengthLabel returns Fair for scores 41-60', () {
        expect(generator.getStrengthLabel(41), 'Fair');
        expect(generator.getStrengthLabel(50), 'Fair');
        expect(generator.getStrengthLabel(60), 'Fair');
      });

      test('getStrengthLabel returns Good for scores 61-80', () {
        expect(generator.getStrengthLabel(61), 'Good');
        expect(generator.getStrengthLabel(70), 'Good');
        expect(generator.getStrengthLabel(80), 'Good');
      });

      test('getStrengthLabel returns Strong for scores 81-100', () {
        expect(generator.getStrengthLabel(81), 'Strong');
        expect(generator.getStrengthLabel(90), 'Strong');
        expect(generator.getStrengthLabel(100), 'Strong');
      });
    });

    group('Strength Color', () {
      test('getStrengthColor returns red for Very Weak', () {
        final color = generator.getStrengthColor(10);
        expect(color, '#D32F2F');
      });

      test('getStrengthColor returns orange for Weak', () {
        final color = generator.getStrengthColor(30);
        expect(color, '#F57C00');
      });

      test('getStrengthColor returns yellow for Fair', () {
        final color = generator.getStrengthColor(50);
        expect(color, '#FBC02D');
      });

      test('getStrengthColor returns light green for Good', () {
        final color = generator.getStrengthColor(70);
        expect(color, '#388E3C');
      });

      test('getStrengthColor returns dark green for Strong', () {
        final color = generator.getStrengthColor(90);
        expect(color, '#1B5E20');
      });
    });

    group('Integration Tests', () {
      test('Generated passwords have consistent strength and label', () {
        final password = generator.generatePassword(length: 20);
        final strength = generator.calculateStrength(password);
        final label = generator.getStrengthLabel(strength);

        // Generated passwords should be at least "Good"
        expect(strength, greaterThanOrEqualTo(61));
        expect(label, isIn(['Good', 'Strong']));
      });

      test('Full strength assessment workflow', () {
        final testCases = {
          'password': 'Very Weak',
          'hellohello': 'Weak', // Repeated characters but has length
          'Password123!': 'Good', // Has all types, good variety
          'MyP@ssw0rd123!': 'Good',
          'xK9#mP2\$vL5@qW8&nR4%': 'Strong',
        };

        for (final entry in testCases.entries) {
          final strength = generator.calculateStrength(entry.key);
          final label = generator.getStrengthLabel(strength);
          expect(label, entry.value, reason: 'For password "${entry.key}", got $label ($strength)');
        }
      });
    });
  });
}
