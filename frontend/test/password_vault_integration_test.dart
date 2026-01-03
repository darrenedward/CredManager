import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/models/password_vault.dart';
import 'package:cred_manager/services/password_generator_service.dart';

/// Integration tests for Password Vault feature (ST062)
///
/// These tests verify the integration between different components:
/// - PasswordVault and PasswordEntry models working together
/// - PasswordGeneratorService integration with entry creation
/// - Tag parsing and serialization
/// - Model copyWith operations preserving data integrity
void main() {
  group('Password Vault Integration Tests (ST062)', () {
    late PasswordGeneratorService generator;

    setUp(() {
      generator = PasswordGeneratorService();
    });

    test('Full workflow: Create vault with entries, update, search, and delete', () {
      // Step 1: Create a vault
      final vault = PasswordVault(
        id: 'vault-1',
        name: 'Personal Accounts',
        description: 'My personal login credentials',
        icon: 'person',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(vault.entries, isEmpty);
      expect(vault.entryCount, 0);

      // Step 2: Add entries to the vault
      final gmailEntry = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-1',
        name: 'Gmail',
        value: 'MyGmailPassword123!',
        username: 'user@gmail.com',
        email: 'user@gmail.com',
        url: 'https://gmail.com',
        notes: 'Main email account',
        tags: 'email,google,personal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final netflixEntry = PasswordEntry(
        id: 'entry-2',
        vaultId: 'vault-1',
        name: 'Netflix',
        value: 'NetflixPassword456!',
        username: 'moviebuff',
        url: 'https://netflix.com',
        tags: 'entertainment,streaming',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create a new vault with entries
      final vaultWithEntries = vault.copyWith(entries: [gmailEntry, netflixEntry]);

      expect(vaultWithEntries.entryCount, 2);
      expect(vaultWithEntries.entries[0].name, 'Gmail');
      expect(vaultWithEntries.entries[1].name, 'Netflix');

      // Step 3: Update an entry
      final updatedGmail = gmailEntry.copyWith(
        value: 'NewSecurePassword789!',
        notes: 'Updated password on 2025-01-04',
      );

      final vaultAfterUpdate = vaultWithEntries.copyWith(
        entries: [updatedGmail, netflixEntry],
      );

      expect(vaultAfterUpdate.entries[0].value, 'NewSecurePassword789!');
      expect(vaultAfterUpdate.entries[0].notes, 'Updated password on 2025-01-04');

      // Step 4: Simulate search functionality
      final searchResults = vaultAfterUpdate.entries
          .where((e) =>
              e.name.toLowerCase().contains('gmail') ||
              (e.username?.toLowerCase().contains('gmail') ?? false))
          .toList();

      expect(searchResults, hasLength(1));
      expect(searchResults.first.name, 'Gmail');

      // Step 5: Filter by tags
      final emailEntries = vaultAfterUpdate.entries
          .where((e) => e.tagList.contains('email'))
          .toList();

      expect(emailEntries, hasLength(1));
      expect(emailEntries.first.name, 'Gmail');

      // Step 6: Remove an entry (simulating delete)
      final vaultAfterDelete = PasswordVault(
        id: vaultAfterUpdate.id,
        name: vaultAfterUpdate.name,
        description: vaultAfterUpdate.description,
        icon: vaultAfterUpdate.icon,
        createdAt: vaultAfterUpdate.createdAt,
        updatedAt: DateTime.now(),
        entries: [netflixEntry], // Only Netflix remains
      );

      expect(vaultAfterDelete.entryCount, 1);
      expect(vaultAfterDelete.entries.first.name, 'Netflix');
    });

    test('Password generator integration with entry creation', () {
      // Generate a strong password
      final generatedPassword = generator.generatePassword(
        length: 20,
        includeUppercase: true,
        includeLowercase: true,
        includeNumbers: true,
        includeSymbols: true,
      );

      final strength = generator.calculateStrength(generatedPassword);
      expect(strength, greaterThan(70));

      // Create an entry with the generated password
      final entry = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-1',
        name: 'Secure Site',
        value: generatedPassword,
        username: 'secureuser',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Verify the entry has the generated password
      expect(entry.value, generatedPassword);
      expect(entry.value.length, 20);

      // Verify strength calculation
      final entryStrength = generator.calculateStrength(entry.value);
      expect(entryStrength, strength);
    });

    test('Tag parsing and filtering integration', () {
      final entries = [
        PasswordEntry(
          id: 'entry-1',
          vaultId: 'vault-1',
          name: 'Gmail',
          value: 'pass1',
          tags: 'email,google,personal',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PasswordEntry(
          id: 'entry-2',
          vaultId: 'vault-1',
          name: 'Outlook',
          value: 'pass2',
          tags: 'email,microsoft,work',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PasswordEntry(
          id: 'entry-3',
          vaultId: 'vault-1',
          name: 'Netflix',
          value: 'pass3',
          tags: 'entertainment,streaming',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PasswordEntry(
          id: 'entry-4',
          vaultId: 'vault-1',
          name: 'GitHub',
          value: 'pass4',
          tags: 'development,code,work',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Filter by single tag
      final emailEntries = entries
          .where((e) => e.tagList.contains('email'))
          .toList();

      expect(emailEntries, hasLength(2));

      // Filter by multiple tags (work)
      final workEntries = entries
          .where((e) => e.tagList.contains('work'))
          .toList();

      expect(workEntries, hasLength(2));

      // Find entries with multiple matching tags
      final multiTagEntries = entries
          .where((e) => e.tagList.length > 2)
          .toList();

      expect(multiTagEntries, hasLength(3));
    });

    test('Vault and entry serialization roundtrip', () {
      final vault = PasswordVault(
        id: 'vault-1',
        name: 'Test Vault',
        description: 'Test Description',
        icon: 'folder',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        entries: [
          PasswordEntry(
            id: 'entry-1',
            vaultId: 'vault-1',
            name: 'Test Entry',
            value: 'TestPassword123!',
            username: 'testuser',
            email: 'test@example.com',
            url: 'https://example.com',
            notes: 'Test notes',
            tags: 'test,sample',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      // Serialize to map
      final vaultMap = vault.toMap();
      final entryMap = vault.entries.first.toMap();

      // Verify vault serialization
      expect(vaultMap['id'], 'vault-1');
      expect(vaultMap['name'], 'Test Vault');
      expect(vaultMap['description'], 'Test Description');

      // Verify entry serialization (value excluded for security)
      expect(entryMap['id'], 'entry-1');
      expect(entryMap['name'], 'Test Entry');
      expect(entryMap.containsKey('value'), false);

      // Deserialize vault from map
      final restoredVault = PasswordVault.fromMap(vaultMap);
      expect(restoredVault.id, vault.id);
      expect(restoredVault.name, vault.name);
      expect(restoredVault.description, vault.description);

      // Deserialize entry from map (with separate value)
      final restoredEntry = PasswordEntry.fromMap({
        ...entryMap,
        'value': 'TestPassword123!', // Value comes from encrypted storage
      });

      expect(restoredEntry.id, vault.entries.first.id);
      expect(restoredEntry.name, vault.entries.first.name);
      expect(restoredEntry.value, 'TestPassword123!');
    });

    test('Multiple vaults management workflow', () {
      // Create multiple vaults
      final personalVault = PasswordVault(
        id: 'vault-personal',
        name: 'Personal',
        icon: 'person',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final workVault = PasswordVault(
        id: 'vault-work',
        name: 'Work',
        icon: 'work',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final financeVault = PasswordVault(
        id: 'vault-finance',
        name: 'Finance',
        icon: 'account_balance',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add entries to different vaults
      final personalVaultWithEntries = personalVault.copyWith(
        entries: [
          PasswordEntry(
            id: 'entry-1',
            vaultId: 'vault-personal',
            name: 'Gmail',
            value: 'pass1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          PasswordEntry(
            id: 'entry-2',
            vaultId: 'vault-personal',
            name: 'Facebook',
            value: 'pass2',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      final workVaultWithEntries = workVault.copyWith(
        entries: [
          PasswordEntry(
            id: 'entry-3',
            vaultId: 'vault-work',
            name: 'Slack',
            value: 'pass3',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      // Create a collection of vaults
      final allVaults = [personalVaultWithEntries, workVaultWithEntries, financeVault];

      // Calculate total entries across all vaults
      final totalEntries = allVaults.fold<int>(
        0,
        (sum, vault) => sum + vault.entryCount,
      );

      expect(totalEntries, 3);

      // Find vaults with specific entry counts
      final vaultsWithEntries = allVaults
          .where((v) => v.entryCount > 0)
          .toList();

      expect(vaultsWithEntries, hasLength(2));
      expect(vaultsWithEntries[0].name, 'Personal');
      expect(vaultsWithEntries[1].name, 'Work');
    });

    test('Entry update integrity across vault copy', () {
      final vault = PasswordVault(
        id: 'vault-1',
        name: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        entries: [
          PasswordEntry(
            id: 'entry-1',
            vaultId: 'vault-1',
            name: 'Gmail',
            value: 'oldpassword',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      // Update the entry
      final updatedEntry = vault.entries.first.copyWith(
        value: 'newpassword',
        notes: 'Updated',
      );

      // Create new vault with updated entry
      final updatedVault = vault.copyWith(
        entries: [updatedEntry],
        updatedAt: DateTime.now(),
      );

      // Verify original vault unchanged
      expect(vault.entries.first.value, 'oldpassword');
      expect(vault.entries.first.notes, isNull);

      // Verify updated vault has new values
      expect(updatedVault.entries.first.value, 'newpassword');
      expect(updatedVault.entries.first.notes, 'Updated');
      expect(updatedVault.updatedAt.isAfter(vault.updatedAt), isTrue);
    });

    test('Passphrase generation integration', () {
      // Generate a passphrase
      final passphrase = generator.generatePassphrase(
        wordCount: 5,
        capitalize: true,
        includeNumber: true,
        separator: '-',
      );

      // Create entry with passphrase
      final entry = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-1',
        name: 'Secure Account',
        value: passphrase,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Verify passphrase format
      expect(entry.value, contains('-'));
      expect(entry.value, contains(RegExp(r'\d')));

      // Calculate strength
      final strength = generator.calculateStrength(entry.value);
      expect(strength, greaterThan(50));
    });
  });
}
