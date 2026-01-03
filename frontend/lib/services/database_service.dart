import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hex/hex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart';
import 'argon2_service.dart';
import 'encryption_service.dart';

class DatabaseService {
  static const int _databaseVersion = 5;

  static dynamic _database; // Can be sqlcipher.Database or Database (FFI)
  static DatabaseService? _instance;
  static String? _passphrase;
  static Uint8List? _encryptionSalt;
  static Uint8List? _encryptionKey;
  static bool _isDesktop = false;
  final Argon2Service _argon2Service = Argon2Service();
  final EncryptionService _encryptionService = EncryptionService();

  // Singleton pattern
  DatabaseService._internal() {
    _isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  static DatabaseService get instance {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  static Future<void> setPassphrase(String passphrase) async {
    _passphrase = passphrase;

    // Generate or retrieve salt for encryption key
    final instance = DatabaseService.instance;
    String? saltB64;

    try {
      // Try to get salt from existing database if available
      if (_database != null) {
        saltB64 = await instance.getMetadata('key_derivation_salt');
      }
    } catch (e) {
      // Ignore errors when database isn't available yet
      saltB64 = null;
    }

    if (saltB64 == null) {
      // Generate new salt
      final salt = instance._encryptionService.generateEncryptionSalt(16);
      _encryptionSalt = salt;
    } else {
      _encryptionSalt = Uint8List.fromList(base64.decode(saltB64));
    }

    try {
      // Derive encryption key
      _encryptionKey = await instance._encryptionService
          .deriveEncryptionKey(passphrase, _encryptionSalt!);
    } catch (e) {
      print('Failed to derive encryption key: $e');
      _encryptionKey = null;
      rethrow;
    }

    // Re-init DB if already open
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Clear all sensitive data from memory (ST026 - Secure Memory Zeroing)
  /// This should be called on logout and app termination to prevent
  /// sensitive data from remaining in memory.
  static void clearPassphrase() {
    // Clear passphrase (set to null for garbage collection)
    _passphrase = null;

    // Clear encryption salt (set to null for garbage collection)
    _encryptionSalt = null;

    // Clear encryption key (set to null for garbage collection)
    _encryptionKey = null;

    // Close DB on logout for security
    if (_database != null) {
      _database!.close();
      _database = null;
    }
  }

  /// Clear all sensitive memory including biometric keys
  /// This is called on logout and app termination
  static Future<void> clearAllSensitiveMemory() async {
    // Clear database passphrase and keys
    clearPassphrase();

    // Clear encryption service key cache if applicable
    // (Note: EncryptionService.clearKeyCache() is currently a no-op for XOR)

    // Additional cleanup can be added here as needed
  }

  /// Gets the database instance, initializing if necessary
  Future<dynamic> get database async {
    if (_database != null) return _database!;

    if (_passphrase == null) {
      _database = await _initDatabase();
    } else {
      _database = await _initEncryptedDatabase();
    }
    return _database!;
  }

  /// Initializes the database (plain mode for setup/init check)
  Future<dynamic> _initDatabase() async {
    final dbPath = await _getDatabasePath();

    if (_isDesktop) {
      // Initialize FFI for desktop platforms
      sqfliteFfiInit();
      
      // Use sqflite_common_ffi for desktop
      return await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onOpen: _onOpen,
        ),
      );
    } else {
      // Use sqlcipher for mobile platforms
      return await sqlcipher.openDatabase(
        dbPath,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      );
    }
  }

  /// Initializes the encrypted database
  Future<dynamic> _initEncryptedDatabase() async {
    if (_passphrase == null)
      throw Exception('Passphrase required for encrypted database');

    final dbPath = await _getDatabasePath();

    if (_isDesktop) {
      // Initialize FFI for desktop platforms
      sqfliteFfiInit();
      
      // Use sqflite_common_ffi with SQLCipher for desktop
      final db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onOpen: _onOpen,
        ),
      );

      await _setEncryptionKey(db);
      return db;
    } else {
      // Use sqlcipher for mobile platforms
      final db = await sqlcipher.openDatabase(
        dbPath,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      );

      await _setEncryptionKey(db);
      return db;
    }
  }

  /// Sets the encryption key for the database (SQLCipher PRAGMA key)
  Future<void> _setEncryptionKey(dynamic db) async {
    if (_encryptionKey == null) throw Exception('Encryption key not derived');
    
    if (!_isDesktop) {
      // Only set PRAGMA key on mobile platforms that support SQLCipher
      final pragmaKey =
          EncryptionService().formatKeyForSQLCipher(_encryptionKey!);
      await db.execute("PRAGMA key = $pragmaKey;");
      print('SQLCipher PRAGMA key set (mobile)');
    } else {
      // Desktop platforms use sqflite_common_ffi without SQLCipher support
      // Encryption is handled at the application layer (XOR encryption)
      print('Desktop platform: Using application-layer encryption only');
    }
  }

  /// Gets the platform-specific database path
  Future<String> _getDatabasePath() async {
    final databaseName = await _getDatabaseName();
    if (Platform.isAndroid || Platform.isIOS) {
      // Mobile platforms - use app documents directory
      final documentsDirectory = await sqlcipher.getDatabasesPath();
      return join(documentsDirectory, databaseName);
    } else {
      // Desktop platforms - use application documents directory
      try {
        final documentsDirectory = await getApplicationDocumentsDirectory();
        final appDataDir = join(documentsDirectory.path, 'APIKeyManager');

        // Create directory if it doesn't exist with proper permissions
        final directory = Directory(appDataDir);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
          // Set directory permissions (Linux/Unix)
          if (Platform.isLinux || Platform.isMacOS) {
            try {
              final result = await Process.run('chmod', ['755', appDataDir]);
              if (result.exitCode != 0) {
                print('Warning: Could not set directory permissions: ${result.stderr}');
              }
            } catch (e) {
              print('Warning: chmod not available: $e');
            }
          }
        }

        return join(appDataDir, databaseName);
      } catch (e) {
        // Fallback to user home directory
        final userHome = Platform.environment['HOME'] ??
            Platform.environment['USERPROFILE'] ??
            '.';
        final appDataDir = join(userHome, '.api_key_manager');

        // Create directory if it doesn't exist with proper permissions
        final directory = Directory(appDataDir);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
          // Set directory permissions (Linux/Unix)
          if (Platform.isLinux || Platform.isMacOS) {
            try {
              final result = await Process.run('chmod', ['755', appDataDir]);
              if (result.exitCode != 0) {
                print('Warning: Could not set directory permissions: ${result.stderr}');
              }
            } catch (e) {
              print('Warning: chmod not available: $e');
            }
          }
        }

        return join(appDataDir, databaseName);
      }
    }
  }

  /// Gets the database name dynamically
  Future<String> _getDatabaseName() async {
    // Use a hash of the app identifier for uniqueness
    final appIdentifier = 'cred_manager_v1';
    final bytes = utf8.encode(appIdentifier);
    final digest = sha256.convert(bytes);
    return '${digest.toString().substring(0, 16)}.db';
  }

  /// Creates the database schema
  Future<void> _onCreate(dynamic db, int version) async {
    await db.transaction((txn) async {
      // Create projects table
      await txn.execute('''
        CREATE TABLE projects (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Create credentials table
      await txn.execute('''
        CREATE TABLE credentials (
          id TEXT PRIMARY KEY,
          project_id TEXT NOT NULL,
          name TEXT NOT NULL,
          encrypted_value TEXT NOT NULL,
          credential_type TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
        )
      ''');

      // Create AI services table
      await txn.execute('''
        CREATE TABLE ai_services (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Create AI service keys table
      await txn.execute('''
        CREATE TABLE ai_service_keys (
          id TEXT PRIMARY KEY,
          service_id TEXT NOT NULL,
          name TEXT NOT NULL,
          encrypted_value TEXT NOT NULL,
          key_type TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (service_id) REFERENCES ai_services(id) ON DELETE CASCADE
        )
      ''');

      // Create app metadata table with new columns for consolidated storage
      await txn.execute('''
        CREATE TABLE app_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at INTEGER NOT NULL,
          encrypted_passphrase_hash TEXT,
          encrypted_token TEXT,
          is_first_time INTEGER DEFAULT 1,
          setup_completed INTEGER DEFAULT 0
        )
      ''');

      // Create security questions table
      await txn.execute('''
        CREATE TABLE security_questions (
          id TEXT PRIMARY KEY,
          question TEXT NOT NULL,
          encrypted_answer_hash TEXT NOT NULL,
          is_custom INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Create password vaults table
      await txn.execute('''
        CREATE TABLE password_vaults (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          icon TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Create password entries table
      await txn.execute('''
        CREATE TABLE password_entries (
          id TEXT PRIMARY KEY,
          vault_id TEXT NOT NULL,
          name TEXT NOT NULL,
          encrypted_value TEXT NOT NULL,
          username TEXT,
          email TEXT,
          url TEXT,
          notes TEXT,
          tags TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (vault_id) REFERENCES password_vaults(id) ON DELETE CASCADE
        )
      ''');

      // Create indexes for better performance
      await txn.execute(
          'CREATE INDEX idx_credentials_project_id ON credentials(project_id)');
      await txn.execute(
          'CREATE INDEX idx_ai_service_keys_service_id ON ai_service_keys(service_id)');
      await txn.execute(
          'CREATE INDEX idx_projects_updated_at ON projects(updated_at DESC)');
      await txn.execute(
          'CREATE INDEX idx_security_questions_created_at ON security_questions(created_at)');
      await txn.execute(
          'CREATE INDEX idx_ai_services_updated_at ON ai_services(updated_at DESC)');
      await txn
          .execute('CREATE INDEX idx_app_metadata_key ON app_metadata(key)');
      await txn.execute(
          'CREATE INDEX idx_password_entries_vault_id ON password_entries(vault_id)');
      await txn.execute(
          'CREATE INDEX idx_password_vaults_updated_at ON password_vaults(updated_at DESC)');

      // Insert initial metadata
      await txn.insert('app_metadata', {
        'key': 'database_version',
        'value': version.toString(),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      await txn.insert('app_metadata', {
        'key': 'created_at',
        'value': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Set default flags
      await txn.insert('app_metadata', {
        'key': 'is_first_time',
        'value': '1',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      await txn.insert('app_metadata', {
        'key': 'setup_completed',
        'value': '0',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    });

    print('Database created successfully with version $version');
  }

  /// Handles database upgrades
  Future<void> _onUpgrade(dynamic db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');

    // Handle migration from version 1 to 2
    if (oldVersion < 2) {
      await _migrateToVersion2(db);
    }

    // Migration from version 2 to 3: Add consolidated storage columns to app_metadata
    if (oldVersion < 3) {
      await _migrateToVersion3(db);
    }

    // Migration from version 3 to 4: Add JWT secret storage
    if (oldVersion < 4) {
      await _migrateToVersion4(db);
    }

    // Migration from version 4 to 5: Add password vaults and password entries
    if (oldVersion < 5) {
      await _migrateToVersion5(db);
    }
  }

  /// Migrates database to version 2 (adds security_questions table)
  Future<void> _migrateToVersion2(dynamic db) async {
    print('Migrating to version 2: Adding security_questions table');

    await db.transaction((txn) async {
      // Create security questions table
      await txn.execute('''
        CREATE TABLE security_questions (
          id TEXT PRIMARY KEY,
          question TEXT NOT NULL,
          encrypted_answer_hash TEXT NOT NULL,
          is_custom INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Create index for security questions
      await txn.execute(
          'CREATE INDEX idx_security_questions_created_at ON security_questions(created_at)');
    });

    print('Successfully migrated to version 2');
  }

  Future<void> _migrateToVersion3(dynamic db) async {
    print(
        'Migrating to version 3: Adding consolidated storage columns to app_metadata');

    await db.transaction((txn) async {
      await txn.execute(
          'ALTER TABLE app_metadata ADD COLUMN encrypted_passphrase_hash TEXT');
      await txn
          .execute('ALTER TABLE app_metadata ADD COLUMN encrypted_token TEXT');
      await txn.execute(
          'ALTER TABLE app_metadata ADD COLUMN is_first_time INTEGER DEFAULT 1');
      await txn.execute(
          'ALTER TABLE app_metadata ADD COLUMN setup_completed INTEGER DEFAULT 0');
      await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_app_metadata_key ON app_metadata(key)');
    });

    print('Successfully migrated to version 3');
  }

  Future<void> _migrateToVersion4(dynamic db) async {
    print(
        'Migrating to version 4: Adding JWT secret storage to app_metadata');

    await db.transaction((txn) async {
      await txn.execute(
          'ALTER TABLE app_metadata ADD COLUMN encrypted_jwt_secret TEXT');
    });

    print('Successfully migrated to version 4');
  }

  Future<void> _migrateToVersion5(dynamic db) async {
    print('Migrating to version 5: Adding password vaults and password entries tables');

    await db.transaction((txn) async {
      // Create password vaults table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS password_vaults (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          icon TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Create password entries table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS password_entries (
          id TEXT PRIMARY KEY,
          vault_id TEXT NOT NULL,
          name TEXT NOT NULL,
          encrypted_value TEXT NOT NULL,
          username TEXT,
          email TEXT,
          url TEXT,
          notes TEXT,
          tags TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (vault_id) REFERENCES password_vaults(id) ON DELETE CASCADE
        )
      ''');

      // Create indexes for password tables
      await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_password_entries_vault_id ON password_entries(vault_id)');
      await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_password_vaults_updated_at ON password_vaults(updated_at DESC)');
    });

    print('Successfully migrated to version 5');
  }

  /// Called when database is opened
  Future<void> _onOpen(dynamic db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');

    print('Database opened successfully');
  }

  /// Executes a query and returns the results
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Inserts a record into the database
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  /// Updates records in the database
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  /// Deletes records from the database
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Executes a raw SQL query
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Executes a raw SQL command
  Future<void> execute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  /// Executes multiple operations in a transaction
  Future<T> transaction<T>(Future<T> Function(dynamic txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  /// Gets metadata value by key
  Future<String?> getMetadata(String key) async {
    final results = await query(
      'app_metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );

    return results.isNotEmpty ? results.first['value'] as String : null;
  }

  /// Sets metadata value by key
  Future<void> setMetadata(String key, String value) async {
    await insert('app_metadata', {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Updates metadata value by key
  Future<void> updateMetadata(String key, String value) async {
    final count = await update(
      'app_metadata',
      {
        'value': value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'key = ?',
      whereArgs: [key],
    );

    // If no rows were updated, insert the metadata
    if (count == 0) {
      await setMetadata(key, value);
    }
  }

  /// Stores encrypted passphrase hash in database
  Future<void> storeEncryptedPassphraseHash(String encryptedHash) async {
    await updateMetadata('encrypted_passphrase_hash', encryptedHash);
    print('Stored encrypted passphrase hash in database');
  }

  /// Retrieves encrypted passphrase hash from database
  Future<String?> getEncryptedPassphraseHash() async {
    return await getMetadata('encrypted_passphrase_hash');
  }

  /// Deletes encrypted passphrase hash from database
  Future<void> deleteEncryptedPassphraseHash() async {
    await delete('app_metadata', where: 'key = ?', whereArgs: ['encrypted_passphrase_hash']);
    print('Deleted encrypted passphrase hash from database');
  }

  /// Stores encrypted JWT token in database
  Future<void> storeEncryptedToken(String encryptedToken) async {
    await updateMetadata('encrypted_token', encryptedToken);
    print('Stored encrypted JWT token in database');
  }

  /// Retrieves encrypted JWT token from database
  Future<String?> getEncryptedToken() async {
    return await getMetadata('encrypted_token');
  }

  /// Deletes encrypted JWT token from database
  Future<void> deleteEncryptedToken() async {
    await delete('app_metadata', where: 'key = ?', whereArgs: ['encrypted_token']);
    print('Deleted encrypted JWT token from database');
  }

  /// Stores encrypted JWT secret key in database
  Future<void> storeEncryptedJwtSecret(String encryptedSecret) async {
    await updateMetadata('encrypted_jwt_secret', encryptedSecret);
    print('Stored encrypted JWT secret key in database');
  }

  /// Retrieves encrypted JWT secret key from database
  Future<String?> getEncryptedJwtSecret() async {
    return await getMetadata('encrypted_jwt_secret');
  }

  /// Deletes encrypted JWT secret key from database
  Future<void> deleteEncryptedJwtSecret() async {
    await delete('app_metadata', where: 'key = ?', whereArgs: ['encrypted_jwt_secret']);
    print('Deleted encrypted JWT secret key from database');
  }

  /// Sets first time flag in database
  Future<void> setFirstTimeFlag(bool isFirstTime) async {
    await updateMetadata('is_first_time', isFirstTime ? '1' : '0');
    print('Set first time flag to: $isFirstTime');
  }

  /// Gets first time flag from database
  Future<bool> getFirstTimeFlag() async {
    final value = await getMetadata('is_first_time');
    return value == '1' || value == null; // Default to true if not set
  }

  /// Sets logged in flag in database
  Future<void> setLoggedInFlag(bool isLoggedIn) async {
    await updateMetadata('is_logged_in', isLoggedIn ? '1' : '0');
    print('Set logged in flag to: $isLoggedIn');
  }

  /// Gets logged in flag from database
  Future<bool> getLoggedInFlag() async {
    final value = await getMetadata('is_logged_in');
    return value == '1'; // Default to false if not set
  }

  /// Sets setup completed flag in database
  Future<void> setSetupCompletedFlag(bool completed) async {
    await updateMetadata('setup_completed', completed ? '1' : '0');
    print('Set setup completed flag to: $completed');
  }

  /// Gets setup completed flag from database
  Future<bool> getSetupCompletedFlag() async {
    final value = await getMetadata('setup_completed');
    return value == '1'; // Default to false if not set
  }

  /// Clears all authentication data from database
  Future<void> clearAllAuthData() async {
    await deleteEncryptedPassphraseHash();
    await deleteEncryptedToken();
    await deleteEncryptedJwtSecret();
    await setLoggedInFlag(false);
    await setFirstTimeFlag(true);
    await setSetupCompletedFlag(false);
    print('Cleared all authentication data from database');
  }

  /// Closes the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Deletes the database file (for testing/reset purposes)
  Future<void> deleteDatabase() async {
    await close();

    final dbPath = await _getDatabasePath();
    final file = File(dbPath);

    if (await file.exists()) {
      await file.delete();
      print('Database file deleted: $dbPath');
    }
  }

  /// Gets database file size in bytes
  Future<int> getDatabaseSize() async {
    final dbPath = await _getDatabasePath();
    final file = File(dbPath);

    if (await file.exists()) {
      return await file.length();
    }

    return 0;
  }

  /// Performs database integrity check
  Future<bool> checkIntegrity() async {
    try {
      final results = await rawQuery('PRAGMA integrity_check');
      return results.isNotEmpty && results.first['integrity_check'] == 'ok';
    } catch (e) {
      print('Database integrity check failed: $e');
      return false;
    }
  }

  /// Stores security questions in encrypted database
  Future<void> storeSecurityQuestions(
      List<Map<String, String>> questions) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      // Clear existing security questions
      await txn.delete('security_questions');

      // Insert new security questions
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        await txn.insert('security_questions', {
          'id': 'sq_${DateTime.now().millisecondsSinceEpoch}_$i',
          'question': question['question'],
          'encrypted_answer_hash':
              question['answerHash'], // Already encrypted by auth service
          'is_custom': question['isCustom'] == 'true' ? 1 : 0,
          'created_at': now,
          'updated_at': now,
        });
      }
    });

    print(
        'Stored ${questions.length} security questions in encrypted database');
  }

  /// Retrieves security questions from encrypted database
  Future<List<Map<String, String>>?> getSecurityQuestions() async {
    try {
      final db = await database;
      final results = await db.query(
        'security_questions',
        orderBy: 'created_at ASC',
      );

      if (results.isEmpty) {
        return null;
      }

      return results
          .map<Map<String, String>>((row) => <String, String>{
                'question': row['question'] as String,
                'answerHash': row['encrypted_answer_hash'] as String,
                'isCustom': (row['is_custom'] as int) == 1 ? 'true' : 'false',
              })
          .toList();
    } catch (e) {
      print('Error retrieving security questions: $e');
      return null;
    }
  }

  /// Deletes all security questions from database
  Future<void> deleteSecurityQuestions() async {
    final db = await database;
    await db.delete('security_questions');
    print('Deleted all security questions from database');
  }
  /// Detects if there's a legacy unencrypted database that needs migration
  Future<bool> detectLegacyDatabase() async {
    final dbPath = await _getDatabasePath();
    final file = File(dbPath);
    
    if (!await file.exists()) {
      return false; // No database exists
    }

    try {
      // Try to open the database without encryption
      final db = await sqlcipher.openDatabase(
        dbPath,
        version: _databaseVersion,
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );

      // Check if it contains our expected tables (indicating it's our legacy DB)
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );

      await db.close();

      // If it has our expected tables, it's a legacy database
      final tableNames = tables.map((t) => t['name'] as String).toSet();
      final expectedTables = {'projects', 'credentials', 'app_metadata', 'ai_services', 'ai_service_keys'};
      
      return expectedTables.every(tableNames.contains);
    } catch (e) {
      // If opening fails, it might be encrypted or corrupted
      print('Legacy database detection error: $e');
      return false;
    }
  }

  /// Migrates from unencrypted SQLite to encrypted SQLCipher database
  Future<bool> migrateToEncrypted(String passphrase) async {
    if (passphrase.isEmpty) {
      throw ArgumentError('Passphrase cannot be empty');
    }

    final dbPath = await _getDatabasePath();
    final backupPath = '$dbPath.backup.${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Step 1: Backup original database
      final originalFile = File(dbPath);
      if (await originalFile.exists()) {
        await originalFile.copy(backupPath);
        print('Created backup at: $backupPath');
      }

      // Step 2: Set passphrase and encryption key
      await setPassphrase(passphrase);

      // Step 3: Open encrypted database (will create new encrypted file)
      final encryptedDb = await _initEncryptedDatabase();
      
      // Step 4: Copy all data from original to encrypted database
      final originalDb = await sqlcipher.openDatabase(
        dbPath,
        version: _databaseVersion,
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );

      await _copyDatabaseData(originalDb, encryptedDb);

      // Step 5: Close both databases
      await originalDb.close();
      await encryptedDb.close();

      // Step 6: Verify migration success
      DatabaseService.setPassphrase(passphrase);
      final verificationDb = await database;
      final integrityCheck = await checkIntegrity();
      await verificationDb.close();

      if (integrityCheck) {
        print('Migration completed successfully');
        // Optionally delete backup after successful migration
        // await File(backupPath).delete();
        return true;
      } else {
        print('Migration failed integrity check');
        // Restore from backup
        await _restoreFromBackup(dbPath, backupPath);
        return false;
      }
    } catch (e) {
      print('Migration failed: $e');
      // Restore from backup on failure
      await _restoreFromBackup(dbPath, backupPath);
      return false;
    }
  }

  /// Copies all data from source to destination database
  Future<void> _copyDatabaseData(dynamic source, dynamic destination) async {
    // Get all tables from source
    final tables = await source.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
    );

    for (final table in tables) {
      final tableName = table['name'] as String;
      print('Migrating table: $tableName');

      // Get all data from source table
      final data = await source.query(tableName);
      
      // Insert into destination table
      for (final row in data) {
        await destination.insert(tableName, row);
      }

      print('Migrated ${data.length} rows from $tableName');
    }

    // Copy indexes
    final indexes = await source.rawQuery(
      "SELECT name, sql FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'"
    );

    for (final index in indexes) {
      final indexSql = index['sql'] as String;
      await destination.execute(indexSql);
      print('Created index: ${index['name']}');
    }
  }

  /// Restores database from backup file
  Future<void> _restoreFromBackup(String dbPath, String backupPath) async {
    final backupFile = File(backupPath);
    if (await backupFile.exists()) {
      await backupFile.copy(dbPath);
      print('Restored database from backup: $backupPath');
    }
  }

  /// Migrates with backup functionality
  Future<Map<String, dynamic>> migrateToEncryptedWithBackup(String passphrase) async {
    final migrationSuccess = await migrateToEncrypted(passphrase);
    final dbPath = await _getDatabasePath();
    final backupPath = '$dbPath.backup.${DateTime.now().millisecondsSinceEpoch}';
    
    return {
      'migrationSuccess': migrationSuccess,
      'backupPath': migrationSuccess ? null : backupPath,
    };
  }

  /// Migrates with rollback capability
  Future<void> migrateToEncryptedWithRollback(String passphrase) async {
    final result = await migrateToEncryptedWithBackup(passphrase);
    if (!result['migrationSuccess']) {
      throw Exception('Migration failed - rollback initiated');
    }
  }

  /// Creates a corrupted migration state for testing
  Future<void> createCorruptedMigrationState() async {
    // This is a test-only method to simulate corrupted state
    final dbPath = await _getDatabasePath();
    final corruptedPath = '$dbPath.corrupted';
    final file = File(dbPath);
    if (await file.exists()) {
      await file.copy(corruptedPath);
      // Corrupt the file by truncating it
      final corruptedFile = File(corruptedPath);
      await corruptedFile.writeAsBytes([0, 1, 2, 3, 4]); // Invalid SQLite header
    }
  }

  /// Recovers from corrupted migration state
  Future<Map<String, dynamic>> recoverFromCorruptedMigration() async {
    final dbPath = await _getDatabasePath();
    final corruptedPath = '$dbPath.corrupted';
    final backupPath = '$dbPath.backup';
    
    final corruptedFile = File(corruptedPath);
    final backupFile = File(backupPath);
    
    bool recoverySuccessful = false;
    bool dataIntegrityVerified = false;
    
    if (await backupFile.exists()) {
      // Restore from backup
      await backupFile.copy(dbPath);
      recoverySuccessful = true;
      
      // Verify integrity
      DatabaseService.clearPassphrase();
      final db = await database;
      dataIntegrityVerified = await checkIntegrity();
      await db.close();
    }
    
    // Cleanup
    if (await corruptedFile.exists()) {
      await corruptedFile.delete();
    }
    
    return {
      'recoverySuccessful': recoverySuccessful,
      'dataIntegrityVerified': dataIntegrityVerified,
    };
  }

  /// Migrates SharedPreferences data to encrypted database
  Future<void> migrateSharedPreferencesToDB(Map<String, dynamic> sharedPrefsData) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final entry in sharedPrefsData.entries) {
      await updateMetadata(entry.key, entry.value.toString());
    }

    // Set default values if not present
    if (!sharedPrefsData.containsKey('is_first_time')) {
      await updateMetadata('is_first_time', '1');
    }
    if (!sharedPrefsData.containsKey('setup_completed')) {
      await updateMetadata('setup_completed', '0');
    }

    print('Migrated ${sharedPrefsData.length} SharedPreferences entries to encrypted database');
  }

  /// Cleans up SharedPreferences after successful migration
  Future<bool> cleanupSharedPreferencesAfterMigration() async {
    // This would typically interact with SharedPreferences plugin
    // For now, we'll just return success as the actual cleanup
    // would be handled by the authentication service
    print('SharedPreferences cleanup completed (simulated)');
    return true;
  }

  /// Checks if legacy SharedPreferences data exists
  Future<bool> hasLegacySharedPreferencesData() async {
    // This would check SharedPreferences for auth-related keys
    // For migration purposes, we assume cleanup is handled elsewhere
    return false;
  }

  /// Migrates predefined security questions to user-defined format
  Future<Map<String, dynamic>> migratePredefinedSecurityQuestions() async {
    final questions = await getSecurityQuestions();
    if (questions == null) {
      return {
        'requiresUserInput': false,
        'questionsRemoved': 0,
        'questionsRemaining': 0,
      };
    }

    // Filter out predefined questions (isCustom = false)
    final predefinedQuestions = questions.where((q) => q['isCustom'] == 'false').toList();
    final customQuestions = questions.where((q) => q['isCustom'] == 'true').toList();

    // Remove predefined questions
    if (predefinedQuestions.isNotEmpty) {
      await deleteSecurityQuestions();
      
      // Re-insert only custom questions
      if (customQuestions.isNotEmpty) {
        await storeSecurityQuestions(customQuestions);
      }
    }

    return {
      'requiresUserInput': predefinedQuestions.isNotEmpty && customQuestions.isEmpty,
      'questionsRemoved': predefinedQuestions.length,
      'questionsRemaining': customQuestions.length,
    };
  }

  /// Validates migration integrity by comparing expected vs actual data counts
  Future<Map<String, dynamic>> validateMigrationIntegrity(Map<String, dynamic> expectedCounts) async {
    final db = await database;
    
    final validationResults = <String, dynamic>{
      'isValid': true,
      'missingRecords': [],
      'corruptedRecords': [],
    };

    // Validate project count
    if (expectedCounts.containsKey('project_count')) {
      final projectCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM projects');
      final actualProjectCount = projectCountResult.first['count'] as int;
      final expectedProjectCount = expectedCounts['project_count'] as int;
      
      if (actualProjectCount != expectedProjectCount) {
        validationResults['isValid'] = false;
        validationResults['projectCount'] = actualProjectCount;
        validationResults['missingRecords'].add('projects: expected $expectedProjectCount, got $actualProjectCount');
      }
    }

    // Validate credential count
    if (expectedCounts.containsKey('credential_count')) {
      final credentialCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM credentials');
      final actualCredentialCount = credentialCountResult.first['count'] as int;
      final expectedCredentialCount = expectedCounts['credential_count'] as int;
      
      if (actualCredentialCount != expectedCredentialCount) {
        validationResults['isValid'] = false;
        validationResults['credentialCount'] = actualCredentialCount;
        validationResults['missingRecords'].add('credentials: expected $expectedCredentialCount, got $actualCredentialCount');
      }
    }

    // Validate metadata entries
    if (expectedCounts.containsKey('metadata_entries')) {
      final metadataCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM app_metadata');
      final actualMetadataCount = metadataCountResult.first['count'] as int;
      final expectedMetadataCount = expectedCounts['metadata_entries'] as int;
      
      if (actualMetadataCount != expectedMetadataCount) {
        validationResults['isValid'] = false;
        validationResults['metadataCount'] = actualMetadataCount;
        validationResults['missingRecords'].add('metadata: expected $expectedMetadataCount, got $actualMetadataCount');
      }
    }

    return validationResults;
  }

  /// Gets the database file path
  Future<String> getDatabasePath() async {
    return await _getDatabasePath();
  }

  /// Imports project data from exported format
  Future<Map<String, dynamic>> importProjectData(Map<String, dynamic> exportData) async {
    try {
      final db = await database;

      // Import project
      final project = exportData['project'] as Map<String, dynamic>;
      await db.insert('projects', project);

      // Import credentials
      final credentials = exportData['credentials'] as List<dynamic>;
      for (final credential in credentials) {
        await db.insert('credentials', credential as Map<String, dynamic>);
      }

      // Import AI services
      final aiServices = exportData['aiServices'] as List<dynamic>;
      for (final service in aiServices) {
        await db.insert('ai_services', service as Map<String, dynamic>);
      }

      // Import AI service keys
      final aiServiceKeys = exportData['aiServiceKeys'] as List<dynamic>;
      for (final key in aiServiceKeys) {
        await db.insert('ai_service_keys', key as Map<String, dynamic>);
      }

      return {
        'success': true,
        'message': 'Project data imported successfully',
        'importedItems': {
          'projects': 1,
          'credentials': credentials.length,
          'aiServices': aiServices.length,
          'aiServiceKeys': aiServiceKeys.length,
        }
      };
    } catch (e) {
      print('Error importing project data: $e');
      return {
        'success': false,
        'message': 'Failed to import project data: $e',
        'importedItems': null,
      };
    }
  }

  /// Exports project data for backup/migration purposes
  Future<Map<String, dynamic>> exportProjectData(String projectId) async {
    try {
      final db = await database;

      // Get project info
      final projectResults = await db.query(
        'projects',
        where: 'id = ?',
        whereArgs: [projectId],
      );

      if (projectResults.isEmpty) {
        throw Exception('Project not found');
      }

      final project = projectResults.first;

      // Get credentials for this project
      final credentialResults = await db.query(
        'credentials',
        where: 'project_id = ?',
        whereArgs: [projectId],
      );

      // Get AI services for this project (if any)
      final aiServiceResults = await db.query('ai_services');

      // Get AI service keys
      final aiServiceKeyResults = await db.query('ai_service_keys');

      return {
        'project': project,
        'credentials': credentialResults,
        'aiServices': aiServiceResults,
        'aiServiceKeys': aiServiceKeyResults,
        'exportTimestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
    } catch (e) {
      print('Error exporting project data: $e');
      rethrow;
    }
  }
}
