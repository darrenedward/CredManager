import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static const String _databaseName = 'api_key_manager.db';
  static const int _databaseVersion = 1;
  
  static Database? _database;
  static DatabaseService? _instance;
  
  // Singleton pattern
  DatabaseService._internal();
  
  static DatabaseService get instance {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }
  
  /// Gets the database instance, initializing if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await _initDatabase();
    return _database!;
  }
  
  /// Initializes the database
  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    // Get the database path
    final dbPath = await _getDatabasePath();
    
    // Open the database
    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
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
        final userHome = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
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
      
      // Create app metadata table
      await txn.execute('''
        CREATE TABLE app_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      
      // Create indexes for better performance
      await txn.execute('CREATE INDEX idx_credentials_project_id ON credentials(project_id)');
      await txn.execute('CREATE INDEX idx_ai_service_keys_service_id ON ai_service_keys(service_id)');
      await txn.execute('CREATE INDEX idx_projects_updated_at ON projects(updated_at DESC)');
      await txn.execute('CREATE INDEX idx_ai_services_updated_at ON ai_services(updated_at DESC)');
      
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
    });
    
    print('Database created successfully with version $version');
  }
  
  /// Handles database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    // Future migrations will be handled here
    // For now, we only have version 1
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
}
