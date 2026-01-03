import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/ai_service.dart';
import '../models/password_vault.dart';
import '../services/credential_storage_service.dart';

class DashboardState extends ChangeNotifier {
  final CredentialStorageService _credentialStorage;
  
  // UI State
  String _currentView = 'overview';
  String _currentSection = 'projects';
  String? _currentSelectedItem;
  bool _isLoading = false;
  String? _error;
  
  // Data State
  List<Project> _projects = [];
  List<AiService> _aiServices = [];
  List<PasswordVault> _passwordVaults = [];

  // Getters
  String get currentView => _currentView;
  String get currentSection => _currentSection;
  String? get currentSelectedItem => _currentSelectedItem;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Project> get projects => _projects;
  List<AiService> get aiServices => _aiServices;
  List<PasswordVault> get passwordVaults => _passwordVaults;
  
  DashboardState(this._credentialStorage);
  
  /// Sets loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Sets error state
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  /// Clears error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Navigation methods
  void showOverview() {
    _currentView = 'overview';
    _currentSelectedItem = null;
    notifyListeners();
  }

  void showProjectsOverview() {
    _currentView = 'projects_overview';
    _currentSelectedItem = null;
    notifyListeners();
  }

  void showAiServicesOverview() {
    _currentView = 'ai_overview';
    _currentSelectedItem = null;
    notifyListeners();
  }

  void showSettings() {
    _currentView = 'settings';
    _currentSelectedItem = null;
    notifyListeners();
  }

  void showSupport() {
    _currentView = 'support';
    _currentSelectedItem = null;
    notifyListeners();
  }

  void showProjectManagement() {
    _currentView = 'project_management';
    _currentSelectedItem = null;
    notifyListeners();
  }

  void showAiServiceManagement() {
    _currentView = 'ai_service_management';
    _currentSelectedItem = null;
    notifyListeners();
  }

  void selectProject(String projectId) {
    _currentView = 'project_detail';
    _currentSection = 'projects';
    _currentSelectedItem = projectId;
    notifyListeners();
  }

  void selectAiService(String serviceId) {
    _currentView = 'ai_service_detail';
    _currentSection = 'ai';
    _currentSelectedItem = serviceId;
    notifyListeners();
  }

  void showPasswordVaultManagement() {
    _currentView = 'password_vault_management';
    _currentSelectedItem = null;
    notifyListeners();
  }

  void selectPasswordVault(String vaultId) {
    _currentView = 'password_vault_detail';
    _currentSection = 'passwords';
    _currentSelectedItem = vaultId;
    notifyListeners();
  }

  /// Sets the current view
  void setCurrentView(String view) {
    _currentView = view;
    notifyListeners();
  }
  
  /// Sets the current section
  void setCurrentSection(String section) {
    _currentSection = section;
    notifyListeners();
  }
  
  /// Sets the currently selected item
  void setCurrentSelectedItem(String? itemId) {
    _currentSelectedItem = itemId;
    notifyListeners();
  }
  
  /// Navigates to a specific project
  void navigateToProject(String projectId) {
    _currentView = 'projects';
    _currentSection = 'projects';
    _currentSelectedItem = projectId;
    notifyListeners();
  }
  
  /// Navigates to a specific AI service
  void navigateToAiService(String serviceId) {
    _currentView = 'ai';
    _currentSection = 'ai';
    _currentSelectedItem = serviceId;
    notifyListeners();
  }

  /// Navigates to a specific password vault
  void navigateToPasswordVault(String vaultId) {
    _currentView = 'password_vault_detail';
    _currentSection = 'passwords';
    _currentSelectedItem = vaultId;
    notifyListeners();
  }

  // ==================== DATA OPERATIONS ====================
  
  /// Loads all data from the database
  Future<void> loadData() async {
    try {
      setLoading(true);
      clearError();

      // Load projects, AI services, and password vaults in parallel
      final results = await Future.wait([
        _credentialStorage.getAllProjects(),
        _credentialStorage.getAllAiServices(),
        _credentialStorage.getAllPasswordVaults(),
      ]);

      _projects = results[0] as List<Project>;
      _aiServices = results[1] as List<AiService>;
      _passwordVaults = results[2] as List<PasswordVault>;

    } catch (e) {
      setError('Failed to load data: $e');
      print('Error loading dashboard data: $e');
    } finally {
      setLoading(false);
    }
  }
  
  /// Refreshes all data
  Future<void> refreshData() async {
    await loadData();
  }
  
  // ==================== PROJECT OPERATIONS ====================
  
  /// Creates a new project
  Future<Project?> createProject(String name, {String? description}) async {
    try {
      setLoading(true);
      clearError();
      
      final project = await _credentialStorage.createProject(
        name: name,
        description: description,
      );
      
      // Add to local list
      _projects.insert(0, project);
      
      // Navigate to the new project
      navigateToProject(project.id);
      
      return project;
    } catch (e) {
      setError('Failed to create project: $e');
      print('Error creating project: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }
  
  /// Updates a project
  Future<bool> updateProject(Project project) async {
    try {
      setLoading(true);
      clearError();
      
      final updatedProject = await _credentialStorage.updateProject(project);
      
      // Update in local list
      final index = _projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        _projects[index] = updatedProject;
      }
      
      return true;
    } catch (e) {
      setError('Failed to update project: $e');
      print('Error updating project: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
  
  /// Deletes a project
  Future<bool> deleteProject(String projectId) async {
    try {
      setLoading(true);
      clearError();
      
      await _credentialStorage.deleteProject(projectId);
      
      // Remove from local list
      _projects.removeWhere((p) => p.id == projectId);
      
      // Navigate away if we were viewing this project
      if (_currentSelectedItem == projectId) {
        setCurrentView('overview');
        setCurrentSelectedItem(null);
      }
      
      return true;
    } catch (e) {
      setError('Failed to delete project: $e');
      print('Error deleting project: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
  
  /// Gets a specific project by ID
  Project? getProject(String id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Adds a credential to a project (legacy method)
  Future<bool> addCredentialToProject({
    required String projectId,
    required String name,
    required String value,
    required CredentialType type,
  }) async {
    try {
      setLoading(true);
      clearError();

      final credential = await _credentialStorage.createCredential(
        projectId: projectId,
        name: name,
        value: value,
        type: type,
      );

      // Update the project in local list
      final projectIndex = _projects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        final project = _projects[projectIndex];
        final updatedCredentials = List<Credential>.from(project.credentials);
        updatedCredentials.insert(0, credential);

        _projects[projectIndex] = project.copyWith(
          credentials: updatedCredentials,
          updatedAt: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      setError('Failed to add credential: $e');
      print('Error adding credential: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Adds a credential to a project with detailed parameters
  Future<void> addDetailedCredentialToProject(
    String projectId,
    String name,
    String username,
    String password, {
    String? url,
    String? notes,
  }) async {
    try {
      setLoading(true);
      clearError();

      // Create a structured value that includes all the information
      final structuredValue = {
        'password': password,
        'username': username,
        if (url != null && url.isNotEmpty) 'url': url,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      // Convert to JSON string for storage
      final valueToStore = structuredValue.length == 1
        ? password // If only password, store it directly
        : '${structuredValue['password']}|||${structuredValue['username']}|||${url ?? ''}|||${notes ?? ''}';

      final credential = await _credentialStorage.createCredential(
        projectId: projectId,
        name: name,
        value: valueToStore,
        type: CredentialType.password,
      );

      // Update the project in local list
      final projectIndex = _projects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        final project = _projects[projectIndex];
        final updatedCredentials = List<Credential>.from(project.credentials);
        updatedCredentials.insert(0, credential);

        _projects[projectIndex] = project.copyWith(
          credentials: updatedCredentials,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
    } catch (e) {
      setError('Failed to add credential: $e');
      print('Error adding credential: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  /// Updates a credential
  Future<bool> updateCredential(Credential credential) async {
    try {
      setLoading(true);
      clearError();
      
      final updatedCredential = await _credentialStorage.updateCredential(credential);
      
      // Update in local project
      final projectIndex = _projects.indexWhere((p) => p.id == credential.projectId);
      if (projectIndex != -1) {
        final project = _projects[projectIndex];
        final updatedCredentials = project.credentials.map((c) {
          return c.id == credential.id ? updatedCredential : c;
        }).toList();
        
        _projects[projectIndex] = project.copyWith(
          credentials: updatedCredentials,
          updatedAt: DateTime.now(),
        );
      }
      
      return true;
    } catch (e) {
      setError('Failed to update credential: $e');
      print('Error updating credential: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
  
  /// Deletes a credential
  Future<bool> deleteCredential(String credentialId, String projectId) async {
    try {
      setLoading(true);
      clearError();
      
      await _credentialStorage.deleteCredential(credentialId, projectId);
      
      // Remove from local project
      final projectIndex = _projects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        final project = _projects[projectIndex];
        final updatedCredentials = project.credentials.where((c) => c.id != credentialId).toList();
        
        _projects[projectIndex] = project.copyWith(
          credentials: updatedCredentials,
          updatedAt: DateTime.now(),
        );
      }
      
      return true;
    } catch (e) {
      setError('Failed to delete credential: $e');
      print('Error deleting credential: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // ==================== AI SERVICE OPERATIONS ====================

  /// Creates a new AI service
  Future<AiService?> createAiService(String name, {String? description}) async {
    try {
      setLoading(true);
      clearError();

      final service = await _credentialStorage.createAiService(
        name: name,
        description: description,
      );

      // Add to local list
      _aiServices.insert(0, service);

      // Navigate to the new service
      navigateToAiService(service.id);

      return service;
    } catch (e) {
      setError('Failed to create AI service: $e');
      print('Error creating AI service: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// Gets a specific AI service by ID
  AiService? getAiService(String id) {
    try {
      return _aiServices.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Adds a key to an AI service
  Future<bool> addKeyToAiService({
    required String serviceId,
    required String name,
    required String value,
    required AiKeyType type,
  }) async {
    try {
      setLoading(true);
      clearError();

      final key = await _credentialStorage.createAiServiceKey(
        serviceId: serviceId,
        name: name,
        value: value,
        type: type,
      );

      // Update the service in local list
      final serviceIndex = _aiServices.indexWhere((s) => s.id == serviceId);
      if (serviceIndex != -1) {
        final service = _aiServices[serviceIndex];
        final updatedKeys = List<AiServiceKey>.from(service.keys);
        updatedKeys.insert(0, key);

        _aiServices[serviceIndex] = service.copyWith(
          keys: updatedKeys,
          updatedAt: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      setError('Failed to add AI service key: $e');
      print('Error adding AI service key: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Updates an AI service
  Future<bool> updateAiService(AiService service) async {
    try {
      setLoading(true);
      clearError();

      final updatedService = await _credentialStorage.updateAiService(service);

      // Update in local list
      final serviceIndex = _aiServices.indexWhere((s) => s.id == service.id);
      if (serviceIndex != -1) {
        _aiServices[serviceIndex] = updatedService;
      }

      return true;
    } catch (e) {
      setError('Failed to update AI service: $e');
      print('Error updating AI service: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Creates a new credential for a project
  Future<bool> createCredential({
    required String projectId,
    required String name,
    required String value,
    required CredentialType type,
  }) async {
    try {
      setLoading(true);
      clearError();

      final credential = await _credentialStorage.createCredential(
        projectId: projectId,
        name: name,
        value: value,
        type: type,
      );

      // Update the project in local list
      final projectIndex = _projects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        final project = _projects[projectIndex];
        final updatedCredentials = List<Credential>.from(project.credentials);
        updatedCredentials.insert(0, credential);

        _projects[projectIndex] = project.copyWith(
          credentials: updatedCredentials,
          updatedAt: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      setError('Failed to add credential: $e');
      print('Error adding credential: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }




  /// Updates an AI service key
  Future<bool> updateAiServiceKey(AiServiceKey key) async {
    try {
      setLoading(true);
      clearError();

      final updatedKey = await _credentialStorage.updateAiServiceKey(key);

      // Update the key in local list
      for (int i = 0; i < _aiServices.length; i++) {
        final service = _aiServices[i];
        final keyIndex = service.keys.indexWhere((k) => k.id == key.id);
        if (keyIndex != -1) {
          final updatedKeys = List<AiServiceKey>.from(service.keys);
          updatedKeys[keyIndex] = updatedKey;

          _aiServices[i] = service.copyWith(
            keys: updatedKeys,
            updatedAt: DateTime.now(),
          );
          break;
        }
      }

      return true;
    } catch (e) {
      setError('Failed to update AI service key: $e');
      print('Error updating AI service key: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Deletes an AI service key
  Future<bool> deleteAiServiceKey(String keyId, String serviceId) async {
    try {
      setLoading(true);
      clearError();

      await _credentialStorage.deleteAiServiceKey(keyId, serviceId);

      // Remove the key from local list
      for (int i = 0; i < _aiServices.length; i++) {
        final service = _aiServices[i];
        final updatedKeys = service.keys.where((k) => k.id != keyId).toList();

        if (updatedKeys.length != service.keys.length) {
          _aiServices[i] = service.copyWith(
            keys: updatedKeys,
            updatedAt: DateTime.now(),
          );
          break;
        }
      }

      return true;
    } catch (e) {
      setError('Failed to delete AI service key: $e');
      print('Error deleting AI service key: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Creates a new AI service key
  Future<bool> createAiServiceKey({
    required String serviceId,
    required String name,
    required String value,
    required AiKeyType type,
  }) async {
    try {
      setLoading(true);
      clearError();

      final key = await _credentialStorage.createAiServiceKey(
        serviceId: serviceId,
        name: name,
        value: value,
        type: type,
      );

      // Update the service in local list
      final serviceIndex = _aiServices.indexWhere((s) => s.id == serviceId);
      if (serviceIndex != -1) {
        final service = _aiServices[serviceIndex];
        final updatedKeys = List<AiServiceKey>.from(service.keys);
        updatedKeys.insert(0, key);

        _aiServices[serviceIndex] = service.copyWith(
          keys: updatedKeys,
          updatedAt: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      setError('Failed to add AI service key: $e');
      print('Error adding AI service key: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Clears all data from storage and resets the state
  Future<void> clearAllData() async {
    try {
      setLoading(true);
      clearError();

      // Clear all projects and their credentials from storage
      for (final project in _projects) {
        await _credentialStorage.deleteProject(project.id);
      }

      // Clear all AI services from storage
      for (final service in _aiServices) {
        await _credentialStorage.deleteAiService(service.id);
      }

      // Clear all password vaults from storage
      for (final vault in _passwordVaults) {
        await _credentialStorage.deletePasswordVault(vault.id);
      }

      // Clear local state
      _projects.clear();
      _aiServices.clear();
      _passwordVaults.clear();
      _currentView = 'overview';

      notifyListeners();
    } catch (e) {
      setError('Failed to clear all data: $e');
      print('Error clearing all data: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // ==================== PASSWORD VAULT OPERATIONS ====================

  /// Creates a new password vault
  Future<PasswordVault?> createPasswordVault(String name, {String? description}) async {
    try {
      setLoading(true);
      clearError();

      final vault = await _credentialStorage.createPasswordVault(
        name: name,
        description: description,
      );

      // Add to local list
      _passwordVaults.insert(0, vault);

      // Navigate to the new vault
      navigateToPasswordVault(vault.id);

      return vault;
    } catch (e) {
      setError('Failed to create password vault: $e');
      print('Error creating password vault: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// Updates a password vault
  Future<bool> updatePasswordVault(PasswordVault vault) async {
    try {
      setLoading(true);
      clearError();

      final updatedVault = await _credentialStorage.updatePasswordVault(vault);

      // Update in local list
      final index = _passwordVaults.indexWhere((v) => v.id == vault.id);
      if (index != -1) {
        _passwordVaults[index] = updatedVault;
      }

      return true;
    } catch (e) {
      setError('Failed to update password vault: $e');
      print('Error updating password vault: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Deletes a password vault
  Future<bool> deletePasswordVault(String vaultId) async {
    try {
      setLoading(true);
      clearError();

      await _credentialStorage.deletePasswordVault(vaultId);

      // Remove from local list
      _passwordVaults.removeWhere((v) => v.id == vaultId);

      // Navigate away if we were viewing this vault
      if (_currentSelectedItem == vaultId) {
        setCurrentView('overview');
        setCurrentSelectedItem(null);
      }

      return true;
    } catch (e) {
      setError('Failed to delete password vault: $e');
      print('Error deleting password vault: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Gets a specific password vault by ID
  PasswordVault? getPasswordVault(String id) {
    try {
      return _passwordVaults.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Creates a new password entry in a vault
  Future<bool> createPasswordEntry({
    required String vaultId,
    required String name,
    required String value,
    String? username,
    String? email,
    String? url,
    String? notes,
    String? tags,
  }) async {
    try {
      setLoading(true);
      clearError();

      final entry = await _credentialStorage.createPasswordEntry(
        vaultId: vaultId,
        name: name,
        value: value,
        username: username,
        email: email,
        url: url,
        notes: notes,
        tags: tags,
      );

      // Update the vault in local list
      final vaultIndex = _passwordVaults.indexWhere((v) => v.id == vaultId);
      if (vaultIndex != -1) {
        final vault = _passwordVaults[vaultIndex];
        final updatedEntries = List<PasswordEntry>.from(vault.entries);
        updatedEntries.insert(0, entry);

        _passwordVaults[vaultIndex] = vault.copyWith(
          entries: updatedEntries,
          updatedAt: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      setError('Failed to create password entry: $e');
      print('Error creating password entry: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Updates a password entry
  Future<bool> updatePasswordEntry(PasswordEntry entry) async {
    try {
      setLoading(true);
      clearError();

      final updatedEntry = await _credentialStorage.updatePasswordEntry(entry);

      // Update the vault in local list
      final vaultIndex = _passwordVaults.indexWhere((v) => v.id == entry.vaultId);
      if (vaultIndex != -1) {
        final vault = _passwordVaults[vaultIndex];
        final entryIndex = vault.entries.indexWhere((e) => e.id == entry.id);
        if (entryIndex != -1) {
          final updatedEntries = List<PasswordEntry>.from(vault.entries);
          updatedEntries[entryIndex] = updatedEntry;

          _passwordVaults[vaultIndex] = vault.copyWith(
            entries: updatedEntries,
            updatedAt: DateTime.now(),
          );
        }
      }

      return true;
    } catch (e) {
      setError('Failed to update password entry: $e');
      print('Error updating password entry: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Deletes a password entry
  Future<bool> deletePasswordEntry(String entryId, String vaultId) async {
    try {
      setLoading(true);
      clearError();

      await _credentialStorage.deletePasswordEntry(entryId, vaultId);

      // Update the vault in local list
      final vaultIndex = _passwordVaults.indexWhere((v) => v.id == vaultId);
      if (vaultIndex != -1) {
        final vault = _passwordVaults[vaultIndex];
        final updatedEntries = vault.entries.where((e) => e.id != entryId).toList();

        _passwordVaults[vaultIndex] = vault.copyWith(
          entries: updatedEntries,
          updatedAt: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      setError('Failed to delete password entry: $e');
      print('Error deleting password entry: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
}
