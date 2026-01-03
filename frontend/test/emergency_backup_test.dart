import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/services/emergency_backup_service.dart';
import 'package:cred_manager/services/database_service.dart';

// Unit tests for Emergency Backup Kit (PT006)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Emergency Backup Kit Tests (ST037)', () {
    late EmergencyBackupService backupService;

    setUp(() async {
      backupService = EmergencyBackupService();

      // Clean up any existing database before each test
      try {
        await DatabaseService.instance.close();
        await DatabaseService.instance.deleteDatabase();
      } catch (e) {
        // Ignore errors if database doesn't exist
      }

      // Clear passphrase to ensure clean state
      DatabaseService.clearPassphrase();
    });

    test('should generate backup code with 256-bit entropy', () async {
      // TDD: This test validates that backup codes have sufficient entropy
      final backupCode = await backupService.generateBackupCode();

      expect(backupCode, isNotNull, reason: 'Backup code should be generated');
      expect(backupCode.length, greaterThan(20), reason: 'Backup code should be sufficiently long');

      // Verify code format (either BIP39 words or base32)
      final words = backupCode.split(' ');
      if (words.length > 1) {
        // BIP39 word format - should have 24 words for 256-bit entropy
        expect(words.length, equals(24), reason: 'Should have 24 words for 256-bit entropy');
      } else {
        // Base32 or similar format
        expect(backupCode.length, greaterThanOrEqualTo(32), reason: 'Should be at least 32 characters');
      }

      // Verify uniqueness - generate multiple codes and ensure no duplicates
      final codes = await Future.wait([
        backupService.generateBackupCode(),
        backupService.generateBackupCode(),
        backupService.generateBackupCode(),
        backupService.generateBackupCode(),
        backupService.generateBackupCode(),
      ]);

      final uniqueCodes = codes.toSet();
      expect(uniqueCodes.length, equals(5), reason: 'All generated codes should be unique');
    });

    test('should hash backup code for secure storage', () async {
      // TDD: This test validates that backup codes are properly hashed
      final backupCode = await backupService.generateBackupCode();

      // Hash the code
      final hashedCode = await backupService.hashBackupCode(backupCode);

      expect(hashedCode, isNotNull, reason: 'Hashed code should not be null');
      expect(hashedCode, isNot(equals(backupCode)), reason: 'Hashed code should differ from original');

      // Verify hash format (Argon2)
      expect(hashedCode, startsWith('\$argon2id\$'), reason: 'Should use Argon2 hashing');

      // Verify same code produces DIFFERENT hashes (due to random salt - correct behavior)
      final hashedCode2 = await backupService.hashBackupCode(backupCode);
      expect(hashedCode, isNot(equals(hashedCode2)), reason: 'Same code should produce different hashes (different salts)');

      // Verify the hash can be used to verify the original code
      await backupService.storeBackupCodeHash(hashedCode);
      final isValid = await backupService.verifyBackupCode(backupCode);
      expect(isValid, isTrue, reason: 'Stored hash should verify original code');
    });

    test('should verify backup code correctly', () async {
      // TDD: This test validates backup code verification
      final backupCode = await backupService.generateBackupCode();

      // Hash and store the code
      final hashedCode = await backupService.hashBackupCode(backupCode);
      await backupService.storeBackupCodeHash(hashedCode);

      // Verify correct code
      final isValid = await backupService.verifyBackupCode(backupCode);
      expect(isValid, isTrue, reason: 'Correct backup code should verify');

      // Verify incorrect code
      final wrongCode = await backupService.generateBackupCode();
      final isInvalid = await backupService.verifyBackupCode(wrongCode);
      expect(isInvalid, isFalse, reason: 'Incorrect backup code should not verify');
    });

    test('should store and retrieve backup code metadata', () async {
      // TDD: This test validates backup code metadata storage
      final backupCode = await backupService.generateBackupCode();
      final hashedCode = await backupService.hashBackupCode(backupCode);

      // Store the hashed code
      await backupService.storeBackupCodeHash(hashedCode);

      // Check if backup code exists
      final hasBackupCode = await backupService.hasBackupCode();
      expect(hasBackupCode, isTrue, reason: 'Should have backup code after storage');

      // Get creation timestamp
      final createdAt = await backupService.getBackupCodeCreationDate();
      expect(createdAt, isNotNull, reason: 'Should have creation timestamp');

      // Verify timestamp is recent (within last minute)
      final now = DateTime.now();
      final timeDiff = now.difference(createdAt!).abs();
      expect(timeDiff.inSeconds, lessThan(60), reason: 'Creation time should be recent');
    });

    test('should remove backup code from storage', () async {
      // TDD: This test validates backup code removal
      final backupCode = await backupService.generateBackupCode();
      final hashedCode = await backupService.hashBackupCode(backupCode);

      // Store the hashed code
      await backupService.storeBackupCodeHash(hashedCode);
      expect(await backupService.hasBackupCode(), isTrue);

      // Remove the code
      await backupService.removeBackupCode();

      // Verify it's removed
      expect(await backupService.hasBackupCode(), isFalse, reason: 'Backup code should be removed');
    });

    test('should invalidate backup code after redemption', () async {
      // TDD: This test validates that backup codes are one-time use
      final backupCode = await backupService.generateBackupCode();
      final hashedCode = await backupService.hashBackupCode(backupCode);

      // Store and verify
      await backupService.storeBackupCodeHash(hashedCode);
      expect(await backupService.verifyBackupCode(backupCode), isTrue);

      // Mark as used
      await backupService.markBackupCodeAsUsed();

      // Verify code is now invalid
      expect(await backupService.verifyBackupCode(backupCode), isFalse, reason: 'Used code should be invalid');

      // Check metadata reflects usage
      final wasUsed = await backupService.wasBackupCodeUsed();
      expect(wasUsed, isTrue, reason: 'Code should be marked as used');
    });

    test('should handle edge cases gracefully', () async {
      // TDD: This test validates error handling

      // Empty code
      expect(() => backupService.hashBackupCode(''), throwsA(isA<ArgumentError>()),
          reason: 'Empty code should throw error');

      // Very short code
      final shortCode = 'abc';
      expect(() => backupService.hashBackupCode(shortCode), throwsA(isA<ArgumentError>()),
          reason: 'Short code should throw error');

      // Verify with no stored code
      final randomCode = await backupService.generateBackupCode();
      final isValid = await backupService.verifyBackupCode(randomCode);
      expect(isValid, isFalse, reason: 'Should return false when no code stored');

      // Remove non-existent code
      await backupService.removeBackupCode(); // Should not throw
    });

    test('should generate QR code data from backup code', () async {
      // TDD: This test validates QR code generation
      final backupCode = await backupService.generateBackupCode();

      // Generate QR code data
      final qrData = await backupService.generateQRCodeData(backupCode);

      expect(qrData, isNotNull, reason: 'QR data should be generated');
      expect(qrData, isNotEmpty, reason: 'QR data should not be empty');

      // QR data should contain the backup code
      expect(qrData, contains(backupCode), reason: 'QR data should encode backup code');

      // Verify QR data can be decoded back
      final decodedCode = backupService.decodeQRCodeData(qrData);
      expect(decodedCode, equals(backupCode), reason: 'Should decode back to original code');
    });

    test('should validate backup code format', () async {
      // TDD: This test validates backup code format requirements
      final backupCode = await backupService.generateBackupCode();

      // Check format validity
      final isValidFormat = backupService.isValidBackupCodeFormat(backupCode);
      expect(isValidFormat, isTrue, reason: 'Generated code should have valid format');

      // Test invalid formats
      expect(backupService.isValidBackupCodeFormat(''), isFalse, reason: 'Empty string should be invalid');
      expect(backupService.isValidBackupCodeFormat('abc'), isFalse, reason: 'Short string should be invalid');
      expect(backupService.isValidBackupCodeFormat('   '), isFalse, reason: 'Whitespace should be invalid');
      expect(backupService.isValidBackupCodeFormat('a b c'), isFalse, reason: 'Too few words should be invalid');
    });

    test('should generate word-based backup code (BIP39)', () async {
      // TDD: This test validates BIP39 word list format
      final backupCode = await backupService.generateBackupCode(format: BackupCodeFormat.bip39);

      final words = backupCode.split(' ');
      expect(words.length, equals(24), reason: 'BIP39 should have 24 words');

      // Each word should be from BIP39 word list (basic validation)
      for (final word in words) {
        expect(word, isNotEmpty, reason: 'Each word should not be empty');
        expect(word, matches(RegExp(r'^[a-zA-Z]+$')), reason: 'Each word should be alphabetic');
      }

      // Should be verifiable
      final isValidFormat = backupService.isValidBackupCodeFormat(backupCode);
      expect(isValidFormat, isTrue);
    });

    test('should generate base32 backup code', () async {
      // TDD: This test validates base32 format
      final backupCode = await backupService.generateBackupCode(format: BackupCodeFormat.base32);

      // Base32 should use specific character set
      expect(backupCode, matches(RegExp(r'^[A-Z2-7]+$')), reason: 'Should use base32 character set');

      // Should be at least 52 characters for 256 bits
      expect(backupCode.length, greaterThanOrEqualTo(52), reason: 'Should be sufficient length');

      // Should be verifiable
      final isValidFormat = backupService.isValidBackupCodeFormat(backupCode);
      expect(isValidFormat, isTrue);
    });
  });
}
