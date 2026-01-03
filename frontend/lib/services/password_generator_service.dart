import 'dart:math';
import 'package:crypto/crypto.dart';

/// Service for generating secure passwords and calculating password strength
class PasswordGeneratorService {
  final Random _random = Random.secure();

  // Character sets for password generation
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  // Common weak passwords to check against
  static const List<String> _commonPasswords = [
    'password', '123456', '12345678', '123456789', '12345',
    '1234567', '1234567890', 'qwerty', 'abc123', 'password1',
    'admin', 'welcome', 'monkey', 'letmein', 'dragon',
    '111111', 'baseball', 'iloveyou', 'trustno1', 'sunshine',
    'master', 'hello', 'freedom', 'whatever', 'qazwsx',
    'trustno1', '000000', 'login', 'passw0rd', 'password123',
  ];

  // Character patterns that indicate weak passwords
  static const List<String> _weakPatterns = [
    '123', 'abc', 'xyz', 'qwe', 'asd', 'zxc', // keyboard patterns
    '111', '222', '333', '444', '555', '666', '777', '888', '999', '000', // repeated digits
  ];

  /// Generates a secure random password
  ///
  /// [length] - desired password length (default 16, min 4)
  /// [includeUppercase] - include uppercase letters (default true)
  /// [includeLowercase] - include lowercase letters (default true)
  /// [includeNumbers] - include numbers (default true)
  /// [includeSymbols] - include symbols (default true)
  String generatePassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
  }) {
    // Validate length
    if (length < 4) {
      throw ArgumentError('Password length must be at least 4 characters');
    }

    // Build character pool
    String pool = '';
    if (includeLowercase) pool += _lowercase;
    if (includeUppercase) pool += _uppercase;
    if (includeNumbers) pool += _numbers;
    if (includeSymbols) pool += _symbols;

    if (pool.isEmpty) {
      throw ArgumentError('At least one character type must be selected');
    }

    // Generate password ensuring at least one character from each selected type
    String password = '';
    List<String> requiredChars = [];

    if (includeLowercase) {
      requiredChars.add(_lowercase[_random.nextInt(_lowercase.length)]);
    }
    if (includeUppercase) {
      requiredChars.add(_uppercase[_random.nextInt(_uppercase.length)]);
    }
    if (includeNumbers) {
      requiredChars.add(_numbers[_random.nextInt(_numbers.length)]);
    }
    if (includeSymbols) {
      requiredChars.add(_symbols[_random.nextInt(_symbols.length)]);
    }

    // Fill remaining length with random characters from pool
    for (int i = requiredChars.length; i < length; i++) {
      password += pool[_random.nextInt(pool.length)];
    }

    // Add required characters and shuffle
    password += requiredChars.join();
    password = _shuffleString(password);

    return password;
  }

  /// Shuffles a string randomly
  String _shuffleString(String input) {
    final characters = input.split('');
    for (int i = characters.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = characters[i];
      characters[i] = characters[j];
      characters[j] = temp;
    }
    return characters.join('');
  }

  /// Calculates password strength (0-100)
  ///
  /// Returns a score where:
  /// - 0-20: Very Weak
  /// - 21-40: Weak
  /// - 41-60: Fair
  /// - 61-80: Good
  /// - 81-100: Strong
  int calculateStrength(String password) {
    if (password.isEmpty) return 0;

    int score = 0;

    // Check for common passwords (immediate 0-10 score)
    if (_commonPasswords.contains(password.toLowerCase())) {
      return 5; // Very weak - common password
    }

    // Length score (up to 40 points)
    int lengthScore = 0;
    if (password.length >= 8) lengthScore += 10;
    if (password.length >= 10) lengthScore += 10;
    if (password.length >= 12) lengthScore += 10;
    if (password.length >= 16) lengthScore += 10;
    score += lengthScore;

    // Character variety score (up to 30 points)
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    bool hasSymbol = password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'));

    int varietyScore = 0;
    if (hasLower) varietyScore += 5;
    if (hasUpper) varietyScore += 5;
    if (hasNumber) varietyScore += 5;
    if (hasSymbol) varietyScore += 15; // Symbols are most valuable

    // Bonus for having all types
    if (hasLower && hasUpper && hasNumber && hasSymbol) {
      varietyScore += 10;
    }

    score += varietyScore;

    // Complexity bonus (up to 20 points)
    int complexityScore = 0;

    // Check for repeated characters (penalty)
    int repeatedChars = 0;
    for (int i = 0; i < password.length - 1; i++) {
      if (password[i] == password[i + 1]) repeatedChars++;
    }
    if (repeatedChars > password.length / 4) {
      complexityScore -= 10;
    }

    // Check for sequential characters
    int sequentialChars = 0;
    for (int i = 0; i < password.length - 2; i++) {
      int current = password.codeUnitAt(i);
      int next = password.codeUnitAt(i + 1);
      int nextNext = password.codeUnitAt(i + 2);
      if ((next == current + 1 && nextNext == current + 2) ||
          (next == current - 1 && nextNext == current - 2)) {
        sequentialChars++;
      }
    }
    if (sequentialChars > 0) {
      complexityScore -= (sequentialChars * 5);
    }

    // Check for keyboard patterns
    for (final pattern in _weakPatterns) {
      if (password.toLowerCase().contains(pattern)) {
        complexityScore -= 10;
        break;
      }
    }

    // Unique character ratio
    int uniqueChars = password.split('').toSet().length;
    double uniqueRatio = uniqueChars / password.length;
    if (uniqueRatio > 0.7) {
      complexityScore += 10;
    } else if (uniqueRatio > 0.5) {
      complexityScore += 5;
    }

    score += complexityScore;

    // Entropy bonus (up to 10 points)
    int entropyScore = 0;
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    String hash = digest.toString();

    // Check if hash has good character distribution
    int uniqueInHash = hash.split('').toSet().length;
    if (uniqueInHash > 15) entropyScore += 10;
    else if (uniqueInHash > 10) entropyScore += 5;

    score += entropyScore;

    // Ensure score is within bounds
    return score.clamp(0, 100);
  }

  /// Gets the strength label for a given score
  String getStrengthLabel(int score) {
    if (score <= 20) return 'Very Weak';
    if (score <= 40) return 'Weak';
    if (score <= 60) return 'Fair';
    if (score <= 80) return 'Good';
    return 'Strong';
  }

  /// Gets the color code for a given strength score
  /// Returns a hex color string
  String getStrengthColor(int score) {
    if (score <= 20) return '#D32F2F'; // Red
    if (score <= 40) return '#F57C00'; // Orange
    if (score <= 60) return '#FBC02D'; // Yellow
    if (score <= 80) return '#388E3C'; // Light Green
    return '#1B5E20'; // Dark Green
  }

  /// Checks if a password is in the common passwords list
  bool isCommonPassword(String password) {
    return _commonPasswords.contains(password.toLowerCase());
  }

  /// Generates a passphrase using word-based approach
  ///
  /// [wordCount] - number of words in passphrase (default 4)
  /// [separator] - separator between words (default '-')
  /// [capitalize] - capitalize first letter of each word (default false)
  /// [includeNumber] - add a random number at the end (default false)
  String generatePassphrase({
    int wordCount = 4,
    String separator = '-',
    bool capitalize = false,
    bool includeNumber = false,
  }) {
    // Simple word list for passphrase generation
    const words = [
      'correct', 'horse', 'battery', 'staple', 'cloud', 'Mountain', 'river',
      'forest', 'ocean', 'thunder', 'breeze', 'sunset', 'meadow', 'crystal',
      'velvet', 'whisper', 'shadow', 'starlight', 'moonbeam', 'dawn',
      'autumn', 'winter', 'spring', 'summer', 'harmony', 'rhythm', 'melody',
      'adventure', 'journey', 'quest', 'champion', 'victory', 'legend',
      'phoenix', 'dragon', 'castle', 'knight', 'wonder', 'magic', 'dream',
    ];

    if (wordCount < 2) {
      throw ArgumentError('Passphrase must have at least 2 words');
    }

    final selectedWords = <String>[];
    for (int i = 0; i < wordCount; i++) {
      String word = words[_random.nextInt(words.length)];
      if (capitalize) {
        word = word[0].toUpperCase() + word.substring(1);
      }
      selectedWords.add(word);
    }

    String passphrase = selectedWords.join(separator);

    if (includeNumber) {
      passphrase += _random.nextInt(1000).toString();
    }

    return passphrase;
  }
}
