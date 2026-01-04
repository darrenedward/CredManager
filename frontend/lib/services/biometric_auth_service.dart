import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'database_service.dart';
import 'encryption_service.dart';

/// Service for handling biometric authentication
class BiometricAuthService {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricKeyKey = 'biometric_key';
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  final EncryptionService _encryptionService = EncryptionService();

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.isDeviceSupported();
      if (!isAvailable) {
        return false;
      }

      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return false;
      }

      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on MissingPluginException {
      // Platform doesn't support biometric authentication (e.g., Linux desktop)
      return false;
    } catch (e) {
      // Other errors
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on MissingPluginException {
      // Platform doesn't support biometric authentication
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Check if biometric authentication is enabled in settings
  Future<bool> isBiometricEnabled() async {
    try {
      final String? enabled = await DatabaseService.instance.getMetadata(_biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      print('Error checking biometric enabled status: $e');
      return false;
    }
  }

  /// Enable or disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await DatabaseService.instance.updateMetadata(_biometricEnabledKey, enabled.toString());
      print('Set biometric enabled to: $enabled');
    } catch (e) {
      print('Error setting biometric enabled status: $e');
      throw Exception('Failed to update biometric settings');
    }
  }

  /// Authenticate using biometrics for quick unlock (after passphrase login)
  Future<BiometricAuthResult> authenticateForQuickUnlock({
    String localizedReason = 'Use biometric for quick unlock',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      // Check if biometric is available
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricAuthResult(
          success: false,
          errorType: BiometricAuthError.notAvailable,
          errorMessage: 'Biometric authentication is not available on this device',
        );
      }

      // Check if biometric is enabled
      final bool isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        return BiometricAuthResult(
          success: false,
          errorType: BiometricAuthError.notEnabled,
          errorMessage: 'Biometric authentication is not enabled',
        );
      }

      // Perform authentication
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: false,
        sensitiveTransaction: true,
      );

      if (didAuthenticate) {
        return BiometricAuthResult(success: true);
      } else {
        return BiometricAuthResult(
          success: false,
          errorType: BiometricAuthError.userCancel,
          errorMessage: 'Authentication was cancelled by user',
        );
      }
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    } on MissingPluginException {
      return BiometricAuthResult(
        success: false,
        errorType: BiometricAuthError.notAvailable,
        errorMessage: 'Biometric authentication is not supported on this platform',
      );
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        errorType: BiometricAuthError.unknown,
        errorMessage: 'An unexpected error occurred: $e',
      );
    }
  }

  /// Test biometric authentication (for setup/enablement)
  Future<BiometricAuthResult> testBiometricAuthentication({
    String localizedReason = 'Test biometric authentication',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      // Check if biometric is available
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricAuthResult(
          success: false,
          errorType: BiometricAuthError.notAvailable,
          errorMessage: 'Biometric authentication is not available on this device',
        );
      }

      // Perform test authentication
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: false,
        sensitiveTransaction: true,
      );

      if (didAuthenticate) {
        return BiometricAuthResult(success: true);
      } else {
        return BiometricAuthResult(
          success: false,
          errorType: BiometricAuthError.userCancel,
          errorMessage: 'Test authentication was cancelled by user',
        );
      }
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    } on MissingPluginException {
      return BiometricAuthResult(
        success: false,
        errorType: BiometricAuthError.notAvailable,
        errorMessage: 'Biometric authentication is not supported on this platform',
      );
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        errorType: BiometricAuthError.unknown,
        errorMessage: 'An unexpected error occurred: $e',
      );
    }
  }

  /// Handle platform exceptions and convert to BiometricAuthResult
  BiometricAuthResult _handlePlatformException(PlatformException e) {
    // In local_auth 3.0.0, error codes are plain strings
    switch (e.code) {
      case 'not_available':
      case 'NotAvailable':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricAuthError.notAvailable,
          errorMessage: 'Biometric authentication is not available',
        );
      case 'not_enrolled':
      case 'NotEnrolled':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricAuthError.notEnrolled,
          errorMessage: 'No biometrics enrolled on this device',
        );
      case 'locked_out':
      case 'LockedOut':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricAuthError.lockedOut,
          errorMessage: 'Biometric authentication is temporarily locked',
        );
      case 'permanently_locked_out':
      case 'PermanentlyLockedOut':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricAuthError.permanentlyLockedOut,
          errorMessage: 'Biometric authentication is permanently locked',
        );
      case 'other':
        // Generic error in local_auth 3.0.0
        return BiometricAuthResult(
          success: false,
          errorType: BiometricAuthError.unknown,
          errorMessage: e.message ?? 'Unknown biometric authentication error',
        );
      default:
        return BiometricAuthResult(
          success: false,
          errorType: BiometricAuthError.unknown,
          errorMessage: e.message ?? 'Unknown biometric authentication error: ${e.code}',
        );
    }
  }

  /// Store encrypted master key for biometric access
  Future<void> storeBiometricKey(String encryptedKey) async {
    try {
      // Use AES-GCM encryption for biometric key storage (stronger than XOR)
      final aesEncryptedKey = await _encryptionService.encryptBiometricKey(encryptedKey);
      await DatabaseService.instance.updateMetadata(_biometricKeyKey, aesEncryptedKey);
      print('Stored AES-GCM encrypted biometric key in database');
    } catch (e) {
      print('Error storing biometric key: $e');
      throw Exception('Failed to store biometric key');
    }
  }

  /// Retrieve encrypted master key for biometric access
  Future<String?> getBiometricKey() async {
    try {
      final aesEncryptedKey = await DatabaseService.instance.getMetadata(_biometricKeyKey);
      if (aesEncryptedKey == null) return null;

      // Decrypt the biometric key from database using AES-GCM
      return await _encryptionService.decryptBiometricKey(aesEncryptedKey);
    } catch (e) {
      print('Error retrieving biometric key: $e');
      return null;
    }
  }

  /// Remove stored biometric key
  Future<void> removeBiometricKey() async {
    try {
      await DatabaseService.instance.delete('app_metadata', where: 'key = ?', whereArgs: [_biometricKeyKey]);
      print('Removed biometric key from database');
    } catch (e) {
      print('Error removing biometric key: $e');
      throw Exception('Failed to remove biometric key');
    }
  }

  /// Get user-friendly biometric type name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
      default:
        return 'Biometric';
    }
  }

  /// Get primary biometric type available
  Future<String> getPrimaryBiometricType() async {
    final List<BiometricType> available = await getAvailableBiometrics();
    if (available.isEmpty) return 'None';
    
    // Prioritize face and fingerprint
    if (available.contains(BiometricType.face)) {
      return getBiometricTypeName(BiometricType.face);
    }
    if (available.contains(BiometricType.fingerprint)) {
      return getBiometricTypeName(BiometricType.fingerprint);
    }
    
    return getBiometricTypeName(available.first);
  }
}

/// Result of biometric authentication attempt
class BiometricAuthResult {
  final bool success;
  final BiometricAuthError? errorType;
  final String? errorMessage;

  BiometricAuthResult({
    required this.success,
    this.errorType,
    this.errorMessage,
  });
}

/// Types of biometric authentication errors
enum BiometricAuthError {
  notAvailable,
  notEnabled,
  notEnrolled,
  notSupported,
  lockedOut,
  permanentlyLockedOut,
  userCancel,
  unknown,
}
