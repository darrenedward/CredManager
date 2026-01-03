import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/models/password_vault.dart';
import 'package:cred_manager/services/encryption_service.dart';

/// Password Vault Encryption Validation Tests (ST063)
///
/// These tests verify that password values can be encrypted and decrypted.
/// Tests are kept simple due to limitations in the encryption service.
void main() {
  group('Password Vault Encryption/Decryption Tests (ST063)', () {
    const testPassphrase = 'TestPassphrase123!';

    test('Encrypt and decrypt password value', () async {
      final encryptionService = EncryptionService();
      const originalPassword = 'MySecurePassword123!';

      final encrypted = await encryptionService.encryptCredential(originalPassword, testPassphrase);
      expect(encrypted, isNotNull);
      expect(encrypted, isNot(equals(originalPassword)));

      final decrypted = await encryptionService.decryptCredential(encrypted, testPassphrase);
      expect(decrypted, equals(originalPassword));
    });

    test('Different passwords produce different encrypted values', () async {
      final encryptionService = EncryptionService();
      const password1 = 'Password1!';
      const password2 = 'Password2!';

      final encrypted1 = await encryptionService.encryptCredential(password1, testPassphrase);
      final encrypted2 = await encryptionService.encryptCredential(password2, testPassphrase);

      expect(encrypted1, isNot(equals(encrypted2)));
    });

    test('Encrypt and decrypt password with special characters', () async {
      final encryptionService = EncryptionService();
      const specialPasswords = [
        'p@ssw0rd!#\$%',
        'ñáéíóú',
        '<script>alert("xss")</script>',
        "O'Brien",
        'A"B\\C`D',
        '🔒🔑💻',
      ];

      for (final password in specialPasswords) {
        final encrypted = await encryptionService.encryptCredential(password, testPassphrase);
        final decrypted = await encryptionService.decryptCredential(encrypted, testPassphrase);
        expect(decrypted, equals(password), reason: 'Password "$password"');
      }
    });

    test('Encrypt and decrypt long password', () async {
      final encryptionService = EncryptionService();
      final longPassword = 'a' * 100 + '123!';

      final encrypted = await encryptionService.encryptCredential(longPassword, testPassphrase);
      final decrypted = await encryptionService.decryptCredential(encrypted, testPassphrase);

      expect(decrypted, equals(longPassword));
      expect(decrypted.length, equals(104));
    });

    test('Encrypt and decrypt empty password', () async {
      final encryptionService = EncryptionService();
      const emptyPassword = '';

      final encrypted = await encryptionService.encryptCredential(emptyPassword, testPassphrase);
      final decrypted = await encryptionService.decryptCredential(encrypted, testPassphrase);

      expect(decrypted, equals(emptyPassword));
    });

    test('Password entry roundtrip through encryption', () async {
      final encryptionService = EncryptionService();
      const originalPassword = 'VaultEntryPassword789!';

      final entry = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-1',
        name: 'Test Entry',
        value: originalPassword,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final encryptedValue = await encryptionService.encryptCredential(entry.value, testPassphrase);
      expect(encryptedValue, isNot(equals(originalPassword)));

      final decryptedValue = await encryptionService.decryptCredential(encryptedValue, testPassphrase);
      expect(decryptedValue, equals(originalPassword));

      final restoredEntry = entry.copyWith(value: decryptedValue);
      expect(restoredEntry.value, equals(originalPassword));
    });

    test('Encrypted password is not human-readable', () async {
      final encryptionService = EncryptionService();
      const humanReadablePassword = 'HumanReadablePassword123!';

      final encrypted = await encryptionService.encryptCredential(humanReadablePassword, testPassphrase);

      expect(encrypted, isNot(contains(humanReadablePassword)));
      expect(encrypted, matches(RegExp(r'[A-Za-z0-9+/=]')));
    });

    test('Vault entry maintains encryption integrity', () async {
      final encryptionService = EncryptionService();
      final entry = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-1',
        name: 'Gmail',
        value: 'password1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final encrypted = await encryptionService.encryptCredential(entry.value, testPassphrase);
      final decrypted = await encryptionService.decryptCredential(encrypted, testPassphrase);
      expect(decrypted, equals(entry.value));
    });
  });
}
