import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hex/hex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cryptography/cryptography.dart';
import 'argon2_service.dart';
import 'encryption_service.dart';

class DatabaseService {
  static const String _databaseName = 'api_key_manager.db';
  static const int _databaseVersion = 3;

  static Database? _database;
  static DatabaseService? _instance;
  static String? _passphrase;
  static Uint8List? _encryptionSalt;
  static Uint8List? _encryptionKey;
  final Argon2Service _argon2Service = Argon2Service();
  final EncryptionService _encryptionService = EncryptionService();

  // Singleton pattern
  DatabaseService._internal();

  static DatabaseService get instance {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  static Future<void> setPassphrase(String passphrase) async {
    _passphrase = passphrase;
    // Generate or retrieve salt for encryption key
    final instance = DatabaseService.instance;
    String? saltB64 = await instance.getMetadata('key_derivation_salt');
    if (saltB64 == null) {
      // Generate new salt and store
      final salt = instance._encryptionService.generateEncryptionSalt(16);
      await instance.setMetadata('key_derivation_salt', base64.encode(salt));
      _encryptionSalt = salt;
    } else {
      _encryptionSalt = Uint8List.fromList(base64.decode(saltB64));
    }
    // Derive encryption key
    _encryptionKey = await instance._encryptionService
        .deriveEncryptionKey(passphrase, _encryptionSalt!);
    // Re-init DB if already open
    if (_database != null) {
      _database = null;
    }
  }

  static void clearPassphrase() {
    _passphrase = null;
    // Close DB on logout for security
    if (_database != null) {
      _database!.close();
      _database = null;
    }
  }

  /// Gets the database instance, initializing if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;

    if (_passphrase == null) {
      _database = await _initDatabase();
    } else {
      _database = await _initEncryptedDatabase();
    }
    return _database!;
  }

  /// Initializes the database (plain mode for setup/init check)
  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Get the database path
    final dbPath = await _getDatabasePath();

    // Open the database in plain mode
    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  /// Initializes the encrypted database
  Future<Database> _initEncryptedDatabase() async {
    if (_passphrase == null)
      throw Exception('Passphrase required for encrypted database');

    // Initialize FFI for desktop platforms (using regular SQLite for now)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await _getDatabasePath();

    final db = await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );

    await _setEncryptionKey(db);

    return db;
  }

  /// Sets the encryption key for the database (SQLCipher PRAGMA key)
  Future<void> _setEncryptionKey(Database db) async {
    if (_encryptionKey == null) throw Exception('Encryption key not derived');
    final pragmaKey =
        EncryptionService().formatKeyForSQLCipher(_encryptionKey!);
    await db.execute("PRAGMA key = $pragmaKey;");
    print('SQLCipher PRAGMA key set');
  }

  /// Gets the platform-specific database path
  Future<String> _getDatabasePath() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Mobile platforms - use app documents directory
      final documentsDirectory = await getDatabasesPath();
      return join(documentsDirectory, _databaseName);
    } else {
      // Desktop platforms - use application documents directory
      try {
        final documentsDirectory = await getApplicationDocumentsDirectory();
        final appDataDir = join(documentsDirectory.path, 'APIKeyManager');

        // Create directory if it doesn't exist
        final directory = Directory(appDataDir);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        return join(appDataDir, _databaseName);
      } catch (e) {
        // Fallback to user home directory
        final userHome = Platform.environment['HOME'] ??
            Platform.environment['USERPROFILE'] ??
            '.';
        final appDataDir = join(userHome, '.api_key_manager');

        // Create directory if it doesn't exist
        final directory = Directory(appDataDir);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        return join(appDataDir, _databaseName);
      }
    }
  }

  /// Creates the database schema
  Future<void> _onCreate(Database db, int version) async {
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
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');

    // Handle migration from version 1 to 2
    if (oldVersion < 2) {
      await _migrateToVersion2(db);
    }

    // Migration from version 2 to 3: Add consolidated storage columns to app_metadata
    if (oldVersion < 3) {
      await _migrateToVersion3(db);
    }
  }

  /// Migrates database to version 2 (adds security_questions table)
  Future<void> _migrateToVersion2(Database db) async {
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

  Future<void> _migrateToVersion3(Database db) async {
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

  /// Called when database is opened
  Future<void> _onOpen(Database db) async {
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
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
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
          .map((row) => {
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
}
