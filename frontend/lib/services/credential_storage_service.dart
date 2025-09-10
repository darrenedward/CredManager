import '../models/project.dart';
import '../models/ai_service.dart';
import 'database_service.dart';
import 'encryption_service.dart';

class CredentialStorageService {
  final DatabaseService _db = DatabaseService.instance;
  final EncryptionService _encryption = EncryptionService();
  
  String? _currentPassphrase;
  
  /// Sets the current user's passphrase for encryption/decryption
  void setPassphrase(String passphrase) {
    _currentPassphrase = passphrase;
  }
  
  /// Clears the current passphrase and encryption cache
  void clearPassphrase() {
    _currentPassphrase = null;
    _encryption.clearKeyCache();
  }
  
  /// Validates that a passphrase is set
  void _validatePassphrase() {
    if (_currentPassphrase == null) {
      throw StateError('Passphrase not set. Call setPassphrase() first.');
    }
  }
  
  // ==================== PROJECT OPERATIONS ====================
  
  /// Creates a new project
  Future<Project> createProject({
    required String name,
    String? description,
  }) async {
    final now = DateTime.now();
    final project = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
    
    await _db.insert('projects', project.toMap());
    return project;
  }
  
  /// Gets all projects with their credentials
  Future<List<Project>> getAllProjects() async {
    _validatePassphrase();
    
    final projectMaps = await _db.query(
      'projects',
      orderBy: 'updated_at DESC',
    );
    
    final projects = <Project>[];
    
    for (final projectMap in projectMaps) {
      final credentials = await _getCredentialsForProject(projectMap['id'] as String);
      projects.add(Project.fromMap(projectMap, credentials: credentials));
    }
    
    return projects;
  }
  
  /// Gets a specific project by ID
  Future<Project?> getProject(String id) async {
    _validatePassphrase();
    
    final projectMaps = await _db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (projectMaps.isEmpty) return null;
    
    final credentials = await _getCredentialsForProject(id);
    return Project.fromMap(projectMaps.first, credentials: credentials);
  }
  
  /// Updates a project
  Future<Project> updateProject(Project project) async {
    final updatedProject = project.copyWith(updatedAt: DateTime.now());
    
    await _db.update(
      'projects',
      updatedProject.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
    
    return updatedProject;
  }
  
  /// Deletes a project and all its credentials
  Future<void> deleteProject(String id) async {
    await _db.delete('projects', where: 'id = ?', whereArgs: [id]);
    // Credentials are automatically deleted due to foreign key constraint
  }
  
  // ==================== CREDENTIAL OPERATIONS ====================
  
  /// Gets all credentials for a specific project (with decryption)
  Future<List<Credential>> _getCredentialsForProject(String projectId) async {
    _validatePassphrase();
    
    final credentialMaps = await _db.query(
      'credentials',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'updated_at DESC',
    );
    
    final credentials = <Credential>[];
    
    for (final credentialMap in credentialMaps) {
      try {
        final encryptedValue = credentialMap['encrypted_value'] as String;
        final decryptedValue = await _encryption.decrypt(encryptedValue, _currentPassphrase!);
        
        credentials.add(Credential.fromMap(credentialMap, decryptedValue: decryptedValue));
      } catch (e) {
        print('Failed to decrypt credential ${credentialMap['id']}: $e');
        // Skip corrupted credentials
      }
    }
    
    return credentials;
  }
  
  /// Creates a new credential
  Future<Credential> createCredential({
    required String projectId,
    required String name,
    required String value,
    required CredentialType type,
  }) async {
    _validatePassphrase();
    
    final now = DateTime.now();
    final credential = Credential(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: projectId,
      name: name,
      value: value,
      type: type,
      createdAt: now,
      updatedAt: now,
    );
    
    // Encrypt the value before storing
    final encryptedValue = await _encryption.encrypt(value, _currentPassphrase!);
    
    await _db.insert('credentials', credential.toMap(encryptedValue: encryptedValue));
    
    // Update project's updated_at timestamp
    await _db.update(
      'projects',
      {'updated_at': now.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [projectId],
    );
    
    return credential;
  }
  
  /// Updates a credential
  Future<Credential> updateCredential(Credential credential) async {
    _validatePassphrase();
    
    final updatedCredential = credential.copyWith(updatedAt: DateTime.now());
    
    // Encrypt the value before storing
    final encryptedValue = await _encryption.encrypt(updatedCredential.value, _currentPassphrase!);
    
    await _db.update(
      'credentials',
      updatedCredential.toMap(encryptedValue: encryptedValue),
      where: 'id = ?',
      whereArgs: [credential.id],
    );
    
    // Update project's updated_at timestamp
    await _db.update(
      'projects',
      {'updated_at': updatedCredential.updatedAt.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [credential.projectId],
    );
    
    return updatedCredential;
  }
  
  /// Deletes a credential
  Future<void> deleteCredential(String id, String projectId) async {
    await _db.delete('credentials', where: 'id = ?', whereArgs: [id]);
    
    // Update project's updated_at timestamp
    await _db.update(
      'projects',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }
  
  // ==================== AI SERVICE OPERATIONS ====================
  
  /// Creates a new AI service
  Future<AiService> createAiService({
    required String name,
    String? description,
  }) async {
    final now = DateTime.now();
    final service = AiService(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
    
    await _db.insert('ai_services', service.toMap());
    return service;
  }
  
  /// Gets all AI services with their keys
  Future<List<AiService>> getAllAiServices() async {
    _validatePassphrase();
    
    final serviceMaps = await _db.query(
      'ai_services',
      orderBy: 'updated_at DESC',
    );
    
    final services = <AiService>[];
    
    for (final serviceMap in serviceMaps) {
      final keys = await _getKeysForAiService(serviceMap['id'] as String);
      services.add(AiService.fromMap(serviceMap, keys: keys));
    }
    
    return services;
  }
  
  /// Gets a specific AI service by ID
  Future<AiService?> getAiService(String id) async {
    _validatePassphrase();
    
    final serviceMaps = await _db.query(
      'ai_services',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (serviceMaps.isEmpty) return null;
    
    final keys = await _getKeysForAiService(id);
    return AiService.fromMap(serviceMaps.first, keys: keys);
  }
  
  /// Updates an AI service
  Future<AiService> updateAiService(AiService service) async {
    final updatedService = service.copyWith(updatedAt: DateTime.now());
    
    await _db.update(
      'ai_services',
      updatedService.toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
    
    return updatedService;
  }
  
  /// Deletes an AI service and all its keys
  Future<void> deleteAiService(String id) async {
    await _db.delete('ai_services', where: 'id = ?', whereArgs: [id]);
    // Keys are automatically deleted due to foreign key constraint
  }

  // ==================== AI SERVICE KEY OPERATIONS ====================

  /// Gets all keys for a specific AI service (with decryption)
  Future<List<AiServiceKey>> _getKeysForAiService(String serviceId) async {
    _validatePassphrase();

    final keyMaps = await _db.query(
      'ai_service_keys',
      where: 'service_id = ?',
      whereArgs: [serviceId],
      orderBy: 'updated_at DESC',
    );

    final keys = <AiServiceKey>[];

    for (final keyMap in keyMaps) {
      try {
        final encryptedValue = keyMap['encrypted_value'] as String;
        final decryptedValue = await _encryption.decrypt(encryptedValue, _currentPassphrase!);

        keys.add(AiServiceKey.fromMap(keyMap, decryptedValue: decryptedValue));
      } catch (e) {
        print('Failed to decrypt AI service key ${keyMap['id']}: $e');
        // Skip corrupted keys
      }
    }

    return keys;
  }

  /// Creates a new AI service key
  Future<AiServiceKey> createAiServiceKey({
    required String serviceId,
    required String name,
    required String value,
    required AiKeyType type,
  }) async {
    _validatePassphrase();

    final now = DateTime.now();
    final key = AiServiceKey(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      serviceId: serviceId,
      name: name,
      value: value,
      type: type,
      createdAt: now,
      updatedAt: now,
    );

    // Encrypt the value before storing
    final encryptedValue = await _encryption.encrypt(value, _currentPassphrase!);

    await _db.insert('ai_service_keys', key.toMap(encryptedValue: encryptedValue));

    // Update service's updated_at timestamp
    await _db.update(
      'ai_services',
      {'updated_at': now.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [serviceId],
    );

    return key;
  }

  /// Updates an AI service key
  Future<AiServiceKey> updateAiServiceKey(AiServiceKey key) async {
    _validatePassphrase();

    final updatedKey = key.copyWith(updatedAt: DateTime.now());

    // Encrypt the value before storing
    final encryptedValue = await _encryption.encrypt(updatedKey.value, _currentPassphrase!);

    await _db.update(
      'ai_service_keys',
      updatedKey.toMap(encryptedValue: encryptedValue),
      where: 'id = ?',
      whereArgs: [key.id],
    );

    // Update service's updated_at timestamp
    await _db.update(
      'ai_services',
      {'updated_at': updatedKey.updatedAt.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [key.serviceId],
    );

    return updatedKey;
  }

  /// Deletes an AI service key
  Future<void> deleteAiServiceKey(String id, String serviceId) async {
    await _db.delete('ai_service_keys', where: 'id = ?', whereArgs: [id]);

    // Update service's updated_at timestamp
    await _db.update(
      'ai_services',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [serviceId],
    );
  }

  // ==================== SEARCH AND UTILITY OPERATIONS ====================

  /// Searches for projects and credentials by name
  Future<List<Project>> searchProjects(String query) async {
    _validatePassphrase();

    final projectMaps = await _db.query(
      'projects',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'updated_at DESC',
    );

    final projects = <Project>[];

    for (final projectMap in projectMaps) {
      final credentials = await _getCredentialsForProject(projectMap['id'] as String);
      projects.add(Project.fromMap(projectMap, credentials: credentials));
    }

    return projects;
  }

  /// Searches for AI services by name
  Future<List<AiService>> searchAiServices(String query) async {
    _validatePassphrase();

    final serviceMaps = await _db.query(
      'ai_services',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'updated_at DESC',
    );

    final services = <AiService>[];

    for (final serviceMap in serviceMaps) {
      final keys = await _getKeysForAiService(serviceMap['id'] as String);
      services.add(AiService.fromMap(serviceMap, keys: keys));
    }

    return services;
  }

  /// Gets database statistics
  Future<Map<String, int>> getStatistics() async {
    final projectCount = await _db.rawQuery('SELECT COUNT(*) as count FROM projects');
    final credentialCount = await _db.rawQuery('SELECT COUNT(*) as count FROM credentials');
    final serviceCount = await _db.rawQuery('SELECT COUNT(*) as count FROM ai_services');
    final keyCount = await _db.rawQuery('SELECT COUNT(*) as count FROM ai_service_keys');

    return {
      'projects': projectCount.first['count'] as int,
      'credentials': credentialCount.first['count'] as int,
      'ai_services': serviceCount.first['count'] as int,
      'ai_service_keys': keyCount.first['count'] as int,
    };
  }

  /// Re-encrypts all data with a new passphrase
  Future<void> changePassphrase(String oldPassphrase, String newPassphrase) async {
    if (_currentPassphrase != oldPassphrase) {
      throw ArgumentError('Old passphrase does not match current passphrase');
    }

    await _db.transaction((txn) async {
      // Re-encrypt all credentials
      final credentials = await txn.query('credentials');
      for (final credential in credentials) {
        final encryptedValue = credential['encrypted_value'] as String;
        final decryptedValue = await _encryption.decrypt(encryptedValue, oldPassphrase);
        final newEncryptedValue = await _encryption.encrypt(decryptedValue, newPassphrase);

        await txn.update(
          'credentials',
          {'encrypted_value': newEncryptedValue},
          where: 'id = ?',
          whereArgs: [credential['id']],
        );
      }

      // Re-encrypt all AI service keys
      final keys = await txn.query('ai_service_keys');
      for (final key in keys) {
        final encryptedValue = key['encrypted_value'] as String;
        final decryptedValue = await _encryption.decrypt(encryptedValue, oldPassphrase);
        final newEncryptedValue = await _encryption.encrypt(decryptedValue, newPassphrase);

        await txn.update(
          'ai_service_keys',
          {'encrypted_value': newEncryptedValue},
          where: 'id = ?',
          whereArgs: [key['id']],
        );
      }
    });

    // Update current passphrase
    _currentPassphrase = newPassphrase;
    _encryption.clearKeyCache();
  }
}
