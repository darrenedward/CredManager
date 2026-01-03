import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'user_model.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/biometric_auth_service.dart';
import '../services/jwt_service.dart';
import '../services/settings_service.dart';
import '../services/credential_storage_service.dart';
import '../utils/constants.dart';

class AuthState extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  DateTime? _sessionStartTime;
  Timer? _sessionTimer;
  Timer? _inactivityTimer;
  int _sessionTimeoutMinutes = AppConstants.defaultSessionTimeout;
  bool _autoCopyPasswords = false;

  // Inactivity tracking
  DateTime? _lastActivityTime;
  static const int _inactivityCheckInterval = 60; // Check every minute

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isLoggedIn => _token != null && _user != null;
  bool get isFirstTime => _user?.isFirstTime ?? true;

  // Enhanced state checks
  bool get hasStoredData => _user != null && !_user!.isFirstTime;
  bool get hasValidSession => _token != null && _user != null;
  int get sessionTimeoutMinutes => _sessionTimeoutMinutes;
  bool get autoCopyPasswords => _autoCopyPasswords;
  DateTime? get sessionStartTime => _sessionStartTime;
  DateTime? get lastActivityTime => _lastActivityTime;
  CredentialStorageService get credentialStorage => _credentialStorage;

  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  final BiometricAuthService _biometricService = BiometricAuthService();
  final SettingsService _settingsService = SettingsService();
  final CredentialStorageService _credentialStorage = CredentialStorageService();

  AuthState() {
    _startInactivityMonitoring();
    // Don't call _loadAuthState here - let AuthWrapper handle it
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _loadAuthState();
    }
  }

  Future<void> _loadAuthState() async {
    print('DEBUG: Loading auth state...');

    // Check setup completion flag (most reliable method)
    bool setupCompleted = await _storageService.getSetupCompleted();
    print('DEBUG: Setup completed flag: $setupCompleted');

    // Migration check: If no setup flag but user has stored data, set flag to true
    if (!setupCompleted) {
      final passphraseHash = await _storageService.getPassphraseHash();
      if (passphraseHash != null) {
        print('DEBUG: Migration - User has stored data but no setup flag, setting flag to true');
        await _storageService.setSetupCompleted(true);
        setupCompleted = true;
      }
    }

    if (!setupCompleted) {
      // Setup not completed - first time user
      print('DEBUG: Setup not completed - first time user');
      _user = User(isFirstTime: true);
    } else {
      // Setup completed - existing user
      print('DEBUG: Setup completed - existing user');
      _user = User(isFirstTime: false);

      // Check for valid session
      _token = await _storageService.getToken();
      if (_token != null) {
        final isTokenExpired = await _storageService.isTokenExpired();
        print('DEBUG: Token exists, expired: $isTokenExpired');

        if (isTokenExpired) {
          // Token expired - clear it
          print('DEBUG: Token expired, clearing...');
          await _storageService.deleteToken();
          await _storageService.setLoggedIn(false);
          _token = null;
        } else {
          // Valid token - establish session
          print('DEBUG: Valid token found, establishing session');
          _establishSession(_token!);
        }
      } else {
        print('DEBUG: No token found');
      }
    }

    // Load session timeout setting
    _sessionTimeoutMinutes = await _settingsService.getSessionTimeout();

    // Load auto-copy passwords setting
    _autoCopyPasswords = await _settingsService.getAutoCopyPasswords();

    print('DEBUG: Auth state loaded - User: ${_user != null}, Token: ${_token != null}, SetupCompleted: $setupCompleted');
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> createPassphrase(String passphrase, List<Map<String, String>> securityQuestions) async {
    try {
      setLoading(true);
      setError(null);
      final token = await _authService.createPassphrase(passphrase, securityQuestions);
      if (token != null) {
        _token = token;
        _user = User(securityQuestions: securityQuestions, isFirstTime: false);

        // Mark setup as completed (most reliable method)
        await _storageService.setSetupCompleted(true);
        await _storageService.setFirstTime(false);
        await _storageService.storeSecurityQuestions(securityQuestions);
        await _storageService.storeToken(token); // Store the JWT token
        await _storageService.setLoggedIn(true); // Mark as logged in

        // Initialize credential storage with user's passphrase
        _credentialStorage.setPassphrase(passphrase);

        // Establish session
        _establishSession(token);
        _updateLastActivity(); // Update activity on login

        print('DEBUG: Setup completed successfully - flag set to true');
        notifyListeners();
      } else {
        setError('Setup failed. Please try again.');
      }
    } catch (e) {
      setError('Setup failed. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  Future<void> login(String passphrase) async {
    try {
      print('DEBUG: AuthState.login called with passphrase');
      setLoading(true);
      setError(null);
      final token = await _authService.login(passphrase);
      print('DEBUG: AuthState.login - token received: ${token != null ? 'YES' : 'NO'}');
      if (token != null) {
        _token = token;
        _user = User(isFirstTime: false);
        await _storageService.storeToken(token);
        await _storageService.setLoggedIn(true);

        // Initialize credential storage with user's passphrase
        _credentialStorage.setPassphrase(passphrase);

        // Establish session
        _establishSession(token);
        _updateLastActivity(); // Update activity on login

        print('DEBUG: AuthState.login - about to notify listeners');
        notifyListeners();
        print('DEBUG: AuthState.login - listeners notified, login complete');
      } else {
        print('DEBUG: AuthState.login - no token received');
        setError('Login failed. Please try again.');
      }
    } on LockoutException catch (e) {
      print('DEBUG: AuthState.login - lockout exception: $e');
      setError('Too many login attempts. Please try again later.');
    } catch (e) {
      print('DEBUG: AuthState.login - exception: $e');
      setError('Login failed. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  /// Enable biometric authentication for quick unlock (no passphrase storage needed)
  Future<bool> enableBiometricAuth() async {
    try {
      setLoading(true);
      setError(null);

      // Check if biometric is available
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (!isAvailable) {
        setError('Biometric authentication is not available on this device');
        return false;
      }

      // Test biometric authentication first
      final authResult = await _biometricService.testBiometricAuthentication(
        localizedReason: 'Test biometric authentication for quick unlock',
      );

      if (!authResult.success) {
        setError(authResult.errorMessage ?? 'Biometric authentication test failed');
        return false;
      }

      // Enable biometric for quick unlock
      await _biometricService.setBiometricEnabled(true);

      print('DEBUG: Biometric authentication enabled for quick unlock');
      return true;
    } catch (e) {
      print('DEBUG: Error enabling biometric auth: $e');
      setError('Failed to enable biometric authentication');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Perform biometric quick unlock (after passphrase login)
  Future<bool> performBiometricQuickUnlock() async {
    try {
      setLoading(true);
      setError(null);

      // Check if biometric is enabled
      final isEnabled = await _biometricService.isBiometricEnabled();
      if (!isEnabled) {
        setError('Biometric authentication is not enabled');
        return false;
      }

      // Authenticate with biometrics for quick unlock
      final authResult = await _biometricService.authenticateForQuickUnlock(
        localizedReason: 'Use biometric for quick unlock',
      );

      if (!authResult.success) {
        setError(authResult.errorMessage ?? 'Biometric authentication failed');
        return false;
      }

      // Biometric authentication successful - user can proceed
      print('DEBUG: Biometric quick unlock successful');
      return true;
    } catch (e) {
      print('DEBUG: Error with biometric quick unlock: $e');
      setError('Biometric quick unlock failed');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometricAuth() async {
    try {
      await _biometricService.setBiometricEnabled(false);
      await _biometricService.removeBiometricKey();
      print('DEBUG: Biometric authentication disabled');
    } catch (e) {
      print('DEBUG: Error disabling biometric auth: $e');
      throw Exception('Failed to disable biometric authentication');
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    return await _biometricService.isBiometricAvailable();
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    return await _biometricService.isBiometricEnabled();
  }


  Future<void> recoverPassphrase(List<String> answers) async {
    try {
      setLoading(true);
      setError(null);
      final success = await _authService.recoverPassphrase(answers);
      if (success) {
        // TODO: Handle recovery, perhaps navigate to passphrase reset
        notifyListeners();
      } else {
        setError('Recovery failed. Please try again.');
      }
    } catch (e) {
      setError('Recovery failed. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _sessionStartTime = null;
    _lastActivityTime = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;

    // Clear credential storage passphrase for security
    _credentialStorage.clearPassphrase();

    await _storageService.deleteToken();
    await _storageService.setLoggedIn(false);
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
    
    // Clear error after 3 seconds
    if (error != null) {
      Future.delayed(const Duration(seconds: 3), () {
        if (_error == error) {
          _error = null;
          notifyListeners();
        }
      });
    }
  }

  Future<void> checkAuth() async {
    if (_token != null) {
      final isValid = await _authService.verifyToken(_token!);
      if (!isValid) {
        await logout();
      }
    }
    notifyListeners();
  }

  /// Establishes a session with the given token
  void _establishSession(String token) {
    _sessionStartTime = DateTime.now();
    _updateLastActivity(); // Initialize last activity
    
    // Set up session expiration check based on JWT token
    final expiration = JwtService.getTokenExpiration(token);
    if (expiration != null) {
      final now = DateTime.now();
      final duration = expiration.difference(now);
      
      // If token is still valid, set up timer to logout when it expires
      if (duration.inMilliseconds > 0) {
        _sessionTimer?.cancel();
        _sessionTimer = Timer(duration, () {
          logout();
        });
      }
    }
    
    // Set up configurable timeout based on settings
    _setUpConfigurableTimeout();
  }

  /// Sets up the configurable session timeout
  void _setUpConfigurableTimeout() {
    // Cancel any existing timer
    _inactivityTimer?.cancel();
    
    // Set up new timer based on configured timeout
    if (_sessionTimeoutMinutes > 0) {
      _inactivityTimer = Timer.periodic(
        Duration(minutes: _inactivityCheckInterval),
        _checkInactivityTimeout,
      );
    }
  }

  /// Checks for inactivity timeout
  void _checkInactivityTimeout(Timer timer) {
    if (_lastActivityTime != null && _sessionTimeoutMinutes > 0) {
      final now = DateTime.now();
      final inactivityDuration = now.difference(_lastActivityTime!);
      final timeoutDuration = Duration(minutes: _sessionTimeoutMinutes);
      
      if (inactivityDuration > timeoutDuration) {
        // User has been inactive for too long, log them out
        logout();
      }
    }
  }

  /// Updates the last activity time
  void _updateLastActivity() {
    _lastActivityTime = DateTime.now();
  }

  /// Starts monitoring user inactivity
  void _startInactivityMonitoring() {
    // Listen for user activity (simplified approach)
    // In a real app, you would track actual user interactions
    _inactivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) {
        // This is a simplified approach - in a real app you would track actual interactions
        // For now, we'll just check if the app is active
        notifyListeners(); // This will trigger activity update in a real implementation
      },
    );
  }

  /// Updates the session timeout setting
  Future<void> updateSessionTimeout(int minutes) async {
    if (minutes > 0) {
      _sessionTimeoutMinutes = minutes;
      await _settingsService.setSessionTimeout(minutes);
      _setUpConfigurableTimeout(); // Re-setup the timeout timer
      notifyListeners();
    }
  }

  /// Sets the session timeout (synchronous version for UI)
  void setSessionTimeout(int minutes) {
    _sessionTimeoutMinutes = minutes;
    _setUpConfigurableTimeout(); // Re-setup the timeout timer
    notifyListeners();

    // Save to storage asynchronously
    _settingsService.setSessionTimeout(minutes);
  }

  /// Sets the auto-copy passwords setting
  Future<void> setAutoCopyPasswords(bool enabled) async {
    _autoCopyPasswords = enabled;
    notifyListeners();

    // Save to storage
    await _settingsService.setAutoCopyPasswords(enabled);
  }

  /// Cleans up expired tokens
  Future<void> cleanupExpiredTokens() async {
    if (_token != null && JwtService.isTokenExpired(_token!)) {
      await logout();
    }
  }

  /// Auto-login with existing valid token
  Future<void> autoLogin(String token) async {
    try {
      print('DEBUG: AuthState.autoLogin called with token');
      setLoading(true);

      // Set the token and user state
      _token = token;
      _user = User(isFirstTime: false);

      // Store token and establish session
      await _storageService.storeToken(token);
      await _storageService.setLoggedIn(true);

      // Establish session
      _establishSession(token);
      _updateLastActivity();

      print('DEBUG: AuthState.autoLogin - session established');
      notifyListeners();
    } catch (e) {
      print('DEBUG: AuthState.autoLogin failed: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  /// Gets remaining session time
  Duration? getRemainingSessionTime() {
    if (_lastActivityTime == null || _sessionTimeoutMinutes <= 0) {
      return null;
    }

    final now = DateTime.now();
    final inactivityDuration = now.difference(_lastActivityTime!);
    final timeoutDuration = Duration(minutes: _sessionTimeoutMinutes);
    final remaining = timeoutDuration - inactivityDuration;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Checks if setup has been completed
  Future<bool> isSetupCompleted() async {
    return await _storageService.getSetupCompleted();
  }

  /// Override notifyListeners to track user activity
  @override
  void notifyListeners() {
    _updateLastActivity(); // Update activity on any state change
    super.notifyListeners();
  }
}