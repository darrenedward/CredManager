import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/models/password_vault.dart';

void main() {
  group('PasswordVault Model Tests (ST056)', () {
    test('PasswordVault.fromMap creates correct instance', () {
      final now = DateTime.now();
      final map = {
        'id': 'vault-1',
        'name': 'Personal',
        'description': 'Personal passwords',
        'icon': 'folder',
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };

      final vault = PasswordVault.fromMap(map);

      expect(vault.id, 'vault-1');
      expect(vault.name, 'Personal');
      expect(vault.description, 'Personal passwords');
      expect(vault.icon, 'folder');
      expect(vault.entries, isEmpty);
    });

    test('PasswordVault.fromMap with entries parameter', () {
      final now = DateTime.now();
      final map = {
        'id': 'vault-1',
        'name': 'Personal',
        'description': null,
        'icon': null,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };

      final entries = [
        PasswordEntry(
          id: 'entry-1',
          vaultId: 'vault-1',
          name: 'Gmail',
          value: 'password123',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final vault = PasswordVault.fromMap(map, entries: entries);

      expect(vault.entries, hasLength(1));
      expect(vault.entries.first.id, 'entry-1');
      expect(vault.entries.first.name, 'Gmail');
    });

    test('PasswordVault.toMap creates correct map', () {
      final now = DateTime.now();
      final vault = PasswordVault(
        id: 'vault-1',
        name: 'Personal',
        description: 'Personal passwords',
        icon: 'folder',
        createdAt: now,
        updatedAt: now,
      );

      final map = vault.toMap();

      expect(map['id'], 'vault-1');
      expect(map['name'], 'Personal');
      expect(map['description'], 'Personal passwords');
      expect(map['icon'], 'folder');
      expect(map['created_at'], now.millisecondsSinceEpoch);
      expect(map['updated_at'], now.millisecondsSinceEpoch);
    });

    test('PasswordVault.copyWith creates updated copy', () {
      final now = DateTime.now();
      final original = PasswordVault(
        id: 'vault-1',
        name: 'Personal',
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        name: 'Work',
        description: 'Work passwords',
      );

      expect(updated.id, 'vault-1');
      expect(updated.name, 'Work');
      expect(updated.description, 'Work passwords');
      expect(original.name, 'Personal'); // Original unchanged
    });

    test('PasswordVault.toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final original = PasswordVault(
        id: 'vault-1',
        name: 'Personal',
        description: 'Personal passwords',
        icon: 'folder',
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = PasswordVault.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.icon, original.icon);
    });

    test('PasswordVault.entryCount returns correct count', () {
      final now = DateTime.now();
      final entries = [
        PasswordEntry(
          id: 'entry-1',
          vaultId: 'vault-1',
          name: 'Gmail',
          value: 'password1',
          createdAt: now,
          updatedAt: now,
        ),
        PasswordEntry(
          id: 'entry-2',
          vaultId: 'vault-1',
          name: 'Netflix',
          value: 'password2',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final vault = PasswordVault(
        id: 'vault-1',
        name: 'Personal',
        createdAt: now,
        updatedAt: now,
        entries: entries,
      );

      expect(vault.entryCount, 2);
    });

    test('PasswordVault equality works correctly', () {
      final now = DateTime.now();
      final vault1 = PasswordVault(
        id: 'vault-1',
        name: 'Personal',
        createdAt: now,
        updatedAt: now,
      );

      final vault2 = PasswordVault(
        id: 'vault-1',
        name: 'Work', // Different name but same ID
        createdAt: now,
        updatedAt: now,
      );

      final vault3 = PasswordVault(
        id: 'vault-2',
        name: 'Personal',
        createdAt: now,
        updatedAt: now,
      );

      expect(vault1, equals(vault2)); // Same ID
      expect(vault1, isNot(equals(vault3))); // Different ID
    });

    test('PasswordVault hashCode works correctly', () {
      final now = DateTime.now();
      final vault1 = PasswordVault(
        id: 'vault-1',
        name: 'Personal',
        createdAt: now,
        updatedAt: now,
      );

      final vault2 = PasswordVault(
        id: 'vault-1',
        name: 'Work',
        createdAt: now,
        updatedAt: now,
      );

      expect(vault1.hashCode, equals(vault2.hashCode));
    });

    test('PasswordVault toString returns correct format', () {
      final now = DateTime.now();
      final vault = PasswordVault(
        id: 'vault-1',
        name: 'Personal',
        createdAt: now,
        updatedAt: now,
        entries: [
          PasswordEntry(
            id: 'entry-1',
            vaultId: 'vault-1',
            name: 'Gmail',
            value: 'password',
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      expect(vault.toString(), contains('vault-1'));
      expect(vault.toString(), contains('Personal'));
      expect(vault.toString(), contains('1')); // entry count
    });
  });

  group('PasswordEntry Model Tests (ST057)', () {
    test('PasswordEntry.fromMap creates correct instance', () {
      final now = DateTime.now();
      final map = {
        'id': 'entry-1',
        'vault_id': 'vault-1',
        'name': 'Gmail',
        'value': 'password123',
        'username': 'john@gmail.com',
        'email': 'john@gmail.com',
        'url': 'https://gmail.com',
        'notes': 'My main email',
        'tags': 'email,google',
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };

      final entry = PasswordEntry.fromMap(map);

      expect(entry.id, 'entry-1');
      expect(entry.vaultId, 'vault-1');
      expect(entry.name, 'Gmail');
      expect(entry.value, 'password123');
      expect(entry.username, 'john@gmail.com');
      expect(entry.email, 'john@gmail.com');
      expect(entry.url, 'https://gmail.com');
      expect(entry.notes, 'My main email');
      expect(entry.tags, 'email,google');
    });

    test('PasswordEntry.fromMap handles null optional fields', () {
      final now = DateTime.now();
      final map = {
        'id': 'entry-1',
        'vault_id': 'vault-1',
        'name': 'Gmail',
        'value': 'password123',
        'username': null,
        'email': null,
        'url': null,
        'notes': null,
        'tags': null,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };

      final entry = PasswordEntry.fromMap(map);

      expect(entry.username, isNull);
      expect(entry.email, isNull);
      expect(entry.url, isNull);
      expect(entry.notes, isNull);
      expect(entry.tags, isNull);
    });

    test('PasswordEntry.toMap creates correct map', () {
      final now = DateTime.now();
      final entry = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-1',
        name: 'Gmail',
        value: 'password123',
        username: 'john@gmail.com',
        email: 'john@gmail.com',
        url: 'https://gmail.com',
        notes: 'My main email',
        tags: 'email,google',
        createdAt: now,
        updatedAt: now,
      );

      final map = entry.toMap();

      expect(map['id'], 'entry-1');
      expect(map['vault_id'], 'vault-1');
      expect(map['name'], 'Gmail');
      expect(map['username'], 'john@gmail.com');
      expect(map['email'], 'john@gmail.com');
      expect(map['url'], 'https://gmail.com');
      expect(map['notes'], 'My main email');
      expect(map['tags'], 'email,google');
      expect(map['created_at'], now.millisecondsSinceEpoch);
      expect(map['updated_at'], now.millisecondsSinceEpoch);
    });

    test('PasswordEntry.toMap excludes value field', () {
      final now = DateTime.now();
      final entry = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-1',
        name: 'Gmail',
        value: 'password123',
        createdAt: now,
        updatedAt: now,
      );

      final map = entry.toMap();

      expect(map.containsKey('value'), false);
      expect(map.containsKey('encrypted_value'), false);
    });

    test('PasswordEntry.copyWith creates updated copy', () {
      final now = DateTime.now();
      final original = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-1',
        name: 'Gmail',
        value: 'password123',
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        name: 'Netflix',
        value: 'newpassword456',
      );

      expect(updated.id, 'entry-1');
      expect(updated.name, 'Netflix');
      expect(updated.value, 'newpassword456');
      expect(original.name, 'Gmail'); // Original unchanged
    });

    test('PasswordEntry.tagList parses comma-separated tags', () {
      final now = DateTime.now();
      final entry = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-1',
        name: 'Gmail',
        value: 'password123',
        tags: 'email, google, personal',
        createdAt: now,
        updatedAt: now,
      );

      expect(entry.tagList, ['email', 'google', 'personal']);
    });

    test('PasswordEntry.tagList handles empty tags', () {
      final now = DateTime.now();
      final entry = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-1',
        name: 'Gmail',
        value: 'password123',
        tags: null,
        createdAt: now,
        updatedAt: now,
      );

      expect(entry.tagList, isEmpty);
    });

    test('PasswordEntry.tagList filters empty strings', () {
      final now = DateTime.now();
      final entry = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-1',
        name: 'Gmail',
        value: 'password123',
        tags: 'email,,personal,  ,work',
        createdAt: now,
        updatedAt: now,
      );

      expect(entry.tagList, ['email', 'personal', 'work']);
    });

    test('PasswordEntry.tagsToString converts list to string', () {
      expect(PasswordEntry.tagsToString(['email', 'google', 'personal']), 'email,google,personal');
    });

    test('PasswordEntry.tagsToString handles empty list', () {
      expect(PasswordEntry.tagsToString([]), isNull);
      expect(PasswordEntry.tagsToString(null), isNull);
    });

    test('PasswordEntry.toJson and fromJson roundtrip (excluding value)', () {
      final now = DateTime.now();
      final original = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-1',
        name: 'Gmail',
        value: 'password123', // This is stored encrypted separately
        username: 'john@gmail.com',
        email: 'john@gmail.com',
        url: 'https://gmail.com',
        notes: 'My main email',
        tags: 'email,google',
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      // Note: value is excluded from toMap() for security (encrypted separately)
      // So the restored entry will have a null value unless provided separately
      final restored = PasswordEntry.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.vaultId, original.vaultId);
      expect(restored.name, original.name);
      expect(restored.username, original.username);
      expect(restored.email, original.email);
      expect(restored.url, original.url);
      expect(restored.notes, original.notes);
      expect(restored.tags, original.tags);
      // value is not serialized - must be handled by encryption layer
    });

    test('PasswordEntry equality works correctly', () {
      final now = DateTime.now();
      final entry1 = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-1',
        name: 'Gmail',
        value: 'password1',
        createdAt: now,
        updatedAt: now,
      );

      final entry2 = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-2', // Different vault but same entry ID
        name: 'Netflix',
        value: 'password2',
        createdAt: now,
        updatedAt: now,
      );

      final entry3 = PasswordEntry(
        id: 'entry-2',
        vaultId: 'vault-1',
        name: 'Gmail',
        value: 'password1',
        createdAt: now,
        updatedAt: now,
      );

      expect(entry1, equals(entry2)); // Same ID
      expect(entry1, isNot(equals(entry3))); // Different ID
    });

    test('PasswordEntry hashCode works correctly', () {
      final now = DateTime.now();
      final entry1 = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-1',
        name: 'Gmail',
        value: 'password1',
        createdAt: now,
        updatedAt: now,
      );

      final entry2 = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-2',
        name: 'Netflix',
        value: 'password2',
        createdAt: now,
        updatedAt: now,
      );

      expect(entry1.hashCode, equals(entry2.hashCode));
    });

    test('PasswordEntry toString returns correct format', () {
      final now = DateTime.now();
      final entry = PasswordEntry(
        id: 'entry-1',
        vaultId: 'vault-1',
        name: 'Gmail',
        value: 'password123',
        username: 'john@gmail.com',
        createdAt: now,
        updatedAt: now,
      );

      expect(entry.toString(), contains('entry-1'));
      expect(entry.toString(), contains('Gmail'));
      expect(entry.toString(), contains('john@gmail.com'));
    });
  });

  group('PasswordVault with Entries Integration Tests', () {
    test('PasswordVault can hold multiple entries', () {
      final now = DateTime.now();
      final entries = [
        PasswordEntry(
          id: 'entry-1',
          vaultId: 'vault-1',
          name: 'Gmail',
          value: 'password1',
          createdAt: now,
          updatedAt: now,
        ),
        PasswordEntry(
          id: 'entry-2',
          vaultId: 'vault-1',
          name: 'Netflix',
          value: 'password2',
          createdAt: now,
          updatedAt: now,
        ),
        PasswordEntry(
          id: 'entry-3',
          vaultId: 'vault-1',
          name: 'Bank',
          value: 'password3',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final vault = PasswordVault(
        id: 'vault-1',
        name: 'Personal',
        createdAt: now,
        updatedAt: now,
        entries: entries,
      );

      expect(vault.entryCount, 3);
      expect(vault.entries[0].name, 'Gmail');
      expect(vault.entries[1].name, 'Netflix');
      expect(vault.entries[2].name, 'Bank');
    });

    test('PasswordVault.copyWith updates entries list', () {
      final now = DateTime.now();
      final entries1 = [
        PasswordEntry(
          id: 'entry-1',
          vaultId: 'vault-1',
          name: 'Gmail',
          value: 'password1',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final vault1 = PasswordVault(
        id: 'vault-1',
        name: 'Personal',
        createdAt: now,
        updatedAt: now,
        entries: entries1,
      );

      final entries2 = [
        PasswordEntry(
          id: 'entry-1',
          vaultId: 'vault-1',
          name: 'Gmail',
          value: 'password1',
          createdAt: now,
          updatedAt: now,
        ),
        PasswordEntry(
          id: 'entry-2',
          vaultId: 'vault-1',
          name: 'Netflix',
          value: 'password2',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final vault2 = vault1.copyWith(entries: entries2);

      expect(vault1.entryCount, 1); // Original unchanged
      expect(vault2.entryCount, 2); // Updated has 2 entries
    });
  });
}
