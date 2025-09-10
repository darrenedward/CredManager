import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static const int _keyLength = 32; // 256 bits
  static const int _nonceLength = 12; // 96 bits for AES-GCM
  static const int _saltLength = 32; // 256 bits
  
  // AES-GCM cipher for encryption
  final AesGcm _cipher = AesGcm.with256bits();
  
  // Cache for derived keys to avoid repeated derivation
  final Map<String, SecretKey> _keyCache = {};
  
  /// Derives an encryption key from a passphrase using Argon2
  Future<SecretKey> _deriveKey(String passphrase, Uint8List salt) async {
    // Create cache key from passphrase hash and salt
    final cacheKey = sha256.convert(utf8.encode(passphrase + base64.encode(salt))).toString();
    
    // Return cached key if available
    if (_keyCache.containsKey(cacheKey)) {
      return _keyCache[cacheKey]!;
    }
    
    // Use Argon2 for key derivation (same parameters as authentication)
    final argon2 = Argon2id(
      memory: 65536, // 64MB
      parallelism: 4,
      iterations: 1,
      hashLength: _keyLength,
    );
    
    final secretKey = SecretKey(utf8.encode(passphrase));
    final derivedKey = await argon2.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );
    
    // Cache the derived key
    _keyCache[cacheKey] = derivedKey;
    
    return derivedKey;
  }
  
  /// Generates a cryptographically secure random salt
  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_saltLength, (i) => random.nextInt(256))
    );
  }
  
  /// Generates a cryptographically secure random nonce
  Uint8List _generateNonce() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_nonceLength, (i) => random.nextInt(256))
    );
  }
  
  /// Encrypts plaintext using AES-256-GCM
  /// Returns base64-encoded string in format: salt:nonce:ciphertext:tag
  Future<String> encrypt(String plaintext, String passphrase) async {
    try {
      // Generate salt and nonce
      final salt = _generateSalt();
      final nonce = _generateNonce();
      
      // Derive encryption key
      final key = await _deriveKey(passphrase, salt);
      
      // Encrypt the plaintext
      final secretBox = await _cipher.encrypt(
        utf8.encode(plaintext),
        secretKey: key,
        nonce: nonce,
      );
      
      // Combine salt, nonce, ciphertext, and authentication tag
      final saltB64 = base64.encode(salt);
      final nonceB64 = base64.encode(nonce);
      final ciphertextB64 = base64.encode(secretBox.cipherText);
      final tagB64 = base64.encode(secretBox.mac.bytes);
      
      return '$saltB64:$nonceB64:$ciphertextB64:$tagB64';
    } catch (e) {
      throw EncryptionException('Failed to encrypt data: $e');
    }
  }
  
  /// Decrypts ciphertext using AES-256-GCM
  /// Expects base64-encoded string in format: salt:nonce:ciphertext:tag
  Future<String> decrypt(String encryptedData, String passphrase) async {
    try {
      // Parse the encrypted data
      final parts = encryptedData.split(':');
      if (parts.length != 4) {
        throw EncryptionException('Invalid encrypted data format');
      }
      
      final salt = base64.decode(parts[0]);
      final nonce = base64.decode(parts[1]);
      final ciphertext = base64.decode(parts[2]);
      final tag = base64.decode(parts[3]);
      
      // Derive decryption key
      final key = await _deriveKey(passphrase, Uint8List.fromList(salt));
      
      // Create SecretBox for decryption
      final secretBox = SecretBox(
        ciphertext,
        nonce: nonce,
        mac: Mac(tag),
      );
      
      // Decrypt the data
      final plaintext = await _cipher.decrypt(
        secretBox,
        secretKey: key,
      );
      
      return utf8.decode(plaintext);
    } catch (e) {
      throw EncryptionException('Failed to decrypt data: $e');
    }
  }
  
  /// Encrypts multiple values in batch for better performance
  Future<Map<String, String>> encryptBatch(
    Map<String, String> plaintexts, 
    String passphrase
  ) async {
    final encrypted = <String, String>{};
    
    for (final entry in plaintexts.entries) {
      encrypted[entry.key] = await encrypt(entry.value, passphrase);
    }
    
    return encrypted;
  }
  
  /// Decrypts multiple values in batch for better performance
  Future<Map<String, String>> decryptBatch(
    Map<String, String> encryptedData, 
    String passphrase
  ) async {
    final decrypted = <String, String>{};
    
    for (final entry in encryptedData.entries) {
      decrypted[entry.key] = await decrypt(entry.value, passphrase);
    }
    
    return decrypted;
  }
  
  /// Validates that encrypted data can be decrypted (integrity check)
  Future<bool> validateEncryptedData(String encryptedData, String passphrase) async {
    try {
      await decrypt(encryptedData, passphrase);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Clears the key cache (call on logout for security)
  void clearKeyCache() {
    _keyCache.clear();
  }
  
  /// Re-encrypts data with a new passphrase
  Future<String> reEncrypt(
    String encryptedData, 
    String oldPassphrase, 
    String newPassphrase
  ) async {
    // Decrypt with old passphrase
    final plaintext = await decrypt(encryptedData, oldPassphrase);
    
    // Encrypt with new passphrase
    return await encrypt(plaintext, newPassphrase);
  }
  
  /// Generates a secure random password
  String generateSecurePassword({
    int length = 32,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
    bool avoidAmbiguous = true,
  }) {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    const ambiguous = '0O1lI|';
    
    String chars = '';
    if (includeUppercase) chars += uppercase;
    if (includeLowercase) chars += lowercase;
    if (includeNumbers) chars += numbers;
    if (includeSymbols) chars += symbols;
    
    if (avoidAmbiguous) {
      for (final char in ambiguous.split('')) {
        chars = chars.replaceAll(char, '');
      }
    }
    
    if (chars.isEmpty) {
      throw ArgumentError('At least one character type must be included');
    }
    
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }
}

/// Exception thrown when encryption/decryption operations fail
class EncryptionException implements Exception {
  final String message;
  
  const EncryptionException(this.message);
  
  @override
  String toString() => 'EncryptionException: $message';
}
