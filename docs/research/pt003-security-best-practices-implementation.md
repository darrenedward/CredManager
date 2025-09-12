# PT003 Security Best Practices Implementation Guide

## Overview

This document provides specific security best practices and implementation patterns for PT003 - Dynamic Secrets and Hardcode Removal, mapping current industry standards to the Agent OS development framework.

## Core Principles Alignment

### 1. Keep It Simple (Agent OS Principle)
- **Implementation**: Use straightforward Argon2 key derivation without complex fallbacks
- **Avoid Over-engineering**: Remove SHA-256 fallback entirely as planned
- **Clear Code**: Write self-documenting cryptographic service methods

### 2. Optimize for Readability
- **Clear Naming**: Use descriptive method names like `deriveEncryptionKeyFromPassphrase()`
- **Documentation**: Add comments explaining "why" for security decisions
- **Consistent Patterns**: Follow established cryptographic patterns

### 3. DRY (Don't Repeat Yourself)
- **Centralized Crypto**: Create reusable cryptographic service utilities
- **Shared Validation**: Extract common input validation logic
- **Utility Functions**: Create helpers for common security operations

## Technology-Specific Best Practices

### Flutter/Dart Security Patterns

#### Argon2 Implementation
```dart
// Recommended Argon2 configuration for PT003
final argon2Config = Argon2(
  memory: 1024 * 1024 * 64, // 64MB memory cost
  parallelism: 2,           // 2 threads
  iterations: 1,            // Focus on memory cost
  hashLength: 32,           // 256-bit output
  type: Argon2Type.argon2id // Most secure variant
);
```

#### Dynamic Key Derivation
- **JWT Secrets**: Derive from passphrase with salt "jwt-secret"
- **Encryption Keys**: Derive from passphrase with salt "encryption-key"  
- **Database Keys**: Derive from passphrase with salt "db-encryption"

#### Service Layer Organization
```
lib/services/
├── crypto_service.dart      # Core cryptographic operations
├── key_derivation_service.dart # Passphrase-based key derivation
├── jwt_service.dart         # JWT token generation/validation
└── encryption_service.dart  # AES encryption/decryption
```

### Testing Strategy for PT003

#### Unit Tests (ST016)
```dart
// Test dynamic key derivation consistency
test('deriveJwtSecret produces consistent results', () async {
  final service = KeyDerivationService();
  final secret1 = await service.deriveJwtSecret('passphrase');
  final secret2 = await service.deriveJwtSecret('passphrase');
  expect(secret1, equals(secret2));
});

// Test different salts produce different keys
test('different derivation contexts produce different keys', () async {
  final service = KeyDerivationService();
  final jwtKey = await service.deriveJwtSecret('passphrase');
  final encKey = await service.deriveEncryptionKey('passphrase');
  expect(jwtKey, isNot(equals(encKey)));
});
```

#### Integration Tests (ST022)
```dart
// Complete auth flow with dynamic secrets
testWidgets('full authentication with dynamic JWT secret', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Enter passphrase and login
  await enterText(find.byType(PassphraseField), 'secure-passphrase');
  await tap(find.byType(LoginButton));
  
  // Verify JWT token was generated with dynamic secret
  verify(mockJwtService.generateToken(
    any, 
    derivedSecret: anyNamed('derivedSecret')
  )).called(1);
  
  await expectToSeeDashboard(tester);
});
```

## Security Enhancement Patterns

### Memory Security (ST026)
```dart
// Secure memory zeroing implementation
void secureZero(List<int> data) {
  for (var i = 0; i < data.length; i++) {
    data[i] = 0;
  }
}

// Usage in logout
void logout() {
  secureZero(_currentPassphraseBytes);
  _currentPassphrase = null;
  // Additional cleanup...
}
```

### Rate Limiting (ST024)
```dart
// Login attempt rate limiting
class RateLimiter {
  final Map<String, List<DateTime>> _attempts = {};
  final Duration _window = Duration(minutes: 5);
  final int _maxAttempts = 5;

  bool canAttempt(String identifier) {
    final now = DateTime.now();
    final userAttempts = _attempts[identifier] ?? [];
    
    // Remove expired attempts
    _attempts[identifier] = userAttempts
        .where((attempt) => now.difference(attempt) < _window)
        .toList();
    
    return _attempts[identifier]!.length < _maxAttempts;
  }
}
```

## Migration Best Practices

### Legacy Data Handling (ST031)
```dart
// Migration from SHA-256 to Argon2-only
Future<bool> migrateLegacyAuthData(String passphrase) async {
  try {
    // 1. Verify old SHA-256 hash
    if (!_verifyLegacyHash(passphrase)) {
      return false;
    }
    
    // 2. Re-hash with Argon2
    final newHash = await _argon2Service.hashPassword(passphrase);
    
    // 3. Update database
    await _updateAuthHash(newHash);
    
    // 4. Clean up legacy data
    await _removeLegacyStorage();
    
    return true;
  } catch (e) {
    _logMigrationError(e);
    return false;
  }
}
```

### UI Security Updates (ST021)
- Remove predefined security questions entirely
- Require minimum 3 user-defined security questions
- Implement strong passphrase validation (12+ characters, mixed character types)
- Provide clear user guidance during migration

## Performance Considerations

### Cryptographic Operation Optimization
- **Target**: <200ms for Argon2 operations
- **Async Processing**: Use `compute()` for background crypto operations
- **Memory Management**: Monitor memory usage during key derivation
- **Platform-specific Tuning**: Adjust parameters based on device capabilities

### Testing Performance
- **Benchmark Tests**: Measure crypto operation times
- **Memory Profiling**: Monitor memory usage patterns
- **Cross-platform Validation**: Test on all target devices

## Compliance with Agent OS Standards

### File Structure Alignment
```
frontend/
├── lib/
│   ├── services/           # Service layer implementation
│   │   ├── crypto/         # Cryptographic services
│   │   ├── auth/           # Authentication services
│   │   └── storage/        # Secure storage services
│   ├── utils/
│   │   └── validation.dart # Security validation utilities
│   └── models/
│       └── auth/           # Authentication data models
└── test/
    ├── unit/
    │   └── services/       # Unit tests for services
    └── integration/
        └── auth/           # Integration tests for auth flows
```

### Development Workflow Compliance
- **No Mock Data**: Use real cryptographic operations in tests
- **Type Safety**: Leverage Dart's strong typing for security
- **Build Verification**: Run `flutter test` and `flutter analyze` regularly
- **Complete Implementation**: Avoid "to be implemented" placeholders

## Risk Mitigation Strategies

### Common Pitfalls to Avoid
1. **Hardcoded Salts**: Always use unique, application-specific salts
2. **Insecure Fallbacks**: Remove all SHA-256 fallback code completely
3. **Memory Leaks**: Implement secure memory zeroing for sensitive data
4. **Error Information Leakage**: Use generic error messages

### Security Validation Tests (ST034)
```dart
// Timing attack resistance validation
test('key derivation has constant time characteristics', () async {
  final service = KeyDerivationService();
  final times = <int>[];
  
  for (var i = 0; i < 100; i++) {
    final stopwatch = Stopwatch()..start();
    await service.deriveKey('test-passphrase-$i');
    times.add(stopwatch.elapsedMicroseconds);
  }
  
  // Verify reasonable time consistency
  final avg = times.reduce((a, b) => a + b) / times.length;
  final variance = times.map((t) => (t - avg).abs()).reduce((a, b) => a + b) / times.length;
  expect(variance / avg, lessThan(0.2)); // <20% variance
});
```

## Implementation Checklist

### Phase 1: Core Security (PT002 → PT003)
- [ ] Remove SHA-256 fallback entirely (ST003)
- [ ] Implement proper Argon2 parameter configuration (ST004)
- [ ] Add input validation and sanitization (ST005)
- [ ] Update authentication tests for Argon2-only (ST006)

### Phase 2: Dynamic Secrets (PT003 Core)
- [ ] Implement passphrase-derived JWT secrets (ST018)
- [ ] Implement dynamic AES key derivation (ST020)
- [ ] Remove predefined security questions (ST017, ST021)
- [ ] Write comprehensive tests (ST016, ST022)

### Phase 3: Enhanced Security (PT003 → PT004)
- [ ] Implement login rate limiting (ST024)
- [ ] Enhance biometrics with proper AES encryption (ST025)
- [ ] Implement secure memory zeroing (ST026)
- [ ] Add security validation tests (ST034)

## References

- Agent OS Best Practices: `.agent-os/standards/best-practices.md`
- Flutter Security Documentation: https://flutter.dev/security
- Dart Cryptography Package: https://pub.dev/packages/cryptography
- Argon2 RFC 9106: https://www.rfc-editor.org/rfc/rfc9106

## Service Classes and Cryptographic Utilities Best Practices

### Service Class Architecture Patterns

#### Separation of Concerns
```dart
// Recommended service class structure
class AuthenticationService {
  final CryptoService _cryptoService;
  final SecureStorageService _storageService;
  final ApiClient _apiClient;

  AuthenticationService({
    required CryptoService cryptoService,
    required SecureStorageService storageService,
    required ApiClient apiClient,
  }) : _cryptoService = cryptoService,
       _storageService = storageService,
       _apiClient = apiClient;

  Future<bool> login(String username, String password) async {
    // Business logic separated from UI
    final hashedPassword = await _cryptoService.hashPassword(password);
    final token = await _apiClient.authenticate(username, hashedPassword);
    await _storageService.saveAuthToken(token);
    return true;
  }
}
```

#### Dependency Injection Patterns
```dart
// Using get_it for dependency injection
final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<CryptoService>(() => CryptoService());
  getIt.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  getIt.registerLazySingleton<AuthenticationService>(
    () => AuthenticationService(
      cryptoService: getIt<CryptoService>(),
      storageService: getIt<SecureStorageService>(),
      apiClient: ApiClient(),
    ),
  );
}

// Usage in widgets
final authService = getIt<AuthenticationService>();
```

### Cryptographic Utilities Implementation

#### AES Encryption Best Practices
```dart
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  static const algorithm = encrypt.AES;
  
  final encrypt.Key _key;
  final encrypt.IV _iv;

  EncryptionService({required String passphrase})
      : _key = encrypt.Key.fromUtf8(passphrase.padRight(32).substring(0, 32)),
        _iv = encrypt.IV.fromLength(16);

  String encryptData(String plaintext) {
    final encrypter = encrypt.Encrypter(algorithm(_key));
    final encrypted = encrypter.encrypt(plaintext, iv: _iv);
    return encrypted.base64;
  }

  String decryptData(String ciphertext) {
    final encrypter = encrypt.Encrypter(algorithm(_key));
    final decrypted = encrypter.decrypt64(ciphertext, iv: _iv);
    return decrypted;
  }
}
```

#### Secure Hashing and Digital Signatures
```dart
import 'package:crypto/crypto.dart';
import 'dart:convert';

class HashService {
  static String sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String hmacSha256(String data, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }
}
```

### Secure Storage Implementation

#### Flutter Secure Storage Best Practices
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> deleteAuthToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<void> saveEncryptedData(String key, String value) async {
    await _storage.write(key: 'enc_$key', value: value);
  }

  Future<String?> getEncryptedData(String key) async {
    return await _storage.read(key: 'enc_$key');
  }
}
```

### Network Security Best Practices

#### HTTPS and SSL Pinning
```dart
import 'package:http/http.dart' as http;
import 'package:flutter_ssl_pinning/flutter_ssl_pinning.dart';

class SecureApiClient {
  static Future<void> initializeSslPinning() async {
    await FlutterSslPinning.initialize(
      certs: ['your_pinned_cert_sha256'],
      httpClient: http.Client(),
    );
  }

  static Future<http.Response> getSecure(String url) async {
    final client = http.Client();
    try {
      return await client.get(Uri.parse(url));
    } finally {
      client.close();
    }
  }
}
```

### Project Structure Best Practices

#### Recommended Directory Structure
```
lib/
├── services/
│   ├── crypto/              # Cryptographic services
│   │   ├── encryption_service.dart
│   │   ├── hash_service.dart
│   │   └── key_derivation_service.dart
│   ├── auth/                # Authentication services
│   │   ├── authentication_service.dart
│   │   ├── jwt_service.dart
│   │   └── biometric_service.dart
│   ├── network/             # Network services
│   │   ├── api_client.dart
│   │   ├── ssl_service.dart
│   │   └── interceptors/
│   └── storage/             # Storage services
│       ├── secure_storage_service.dart
│       ├── preferences_service.dart
│       └── cache_service.dart
├── models/                  # Data models
├── utils/                   # Utility classes
└── constants/               # App constants
```

### Security Best Practices for Service Classes

1. **Input Validation**: Always validate and sanitize inputs in service methods
2. **Error Handling**: Use specific error types for different failure scenarios
3. **Memory Management**: Implement secure memory zeroing for sensitive data
4. **Thread Safety**: Ensure service methods are thread-safe when needed
5. **Logging**: Implement comprehensive logging for security events
6. **Testing**: Write extensive unit and integration tests for all services

### Performance Optimization

```dart
// Use compute() for expensive cryptographic operations
Future<String> deriveKeyAsync(String passphrase) async {
  return await compute(_deriveKeyIsolate, passphrase);
}

String _deriveKeyIsolate(String passphrase) {
  // Expensive cryptographic operation
  return Argon2().hashPassword(passphrase);
}
```

## Unit Test Organization Best Practices

### Test File Structure and Naming

#### Directory Structure
```
test/
├── unit/                    # Unit tests
│   ├── services/           # Mirror lib/services structure
│   │   ├── crypto/
│   │   │   ├── encryption_service_test.dart
│   │   │   └── hash_service_test.dart
│   │   ├── auth/
│   │   └── network/
│   ├── models/             # Model tests
│   └── utils/              # Utility tests
├── widget/                 # Widget tests
└── integration/            # Integration tests
```

#### File Naming Convention
- Test files must end with `_test.dart`
- Test files should mirror the structure of the `lib` folder
- Example: `lib/services/crypto/encryption_service.dart` → `test/unit/services/crypto/encryption_service_test.dart`

### Test Method Organization

#### AAA Pattern (Arrange-Act-Assert)
```dart
test('should encrypt data successfully when valid input provided', () async {
  // Arrange: Set up test conditions
  final service = EncryptionService(passphrase: 'secure-passphrase');
  const plaintext = 'sensitive data';
  
  // Act: Perform the action being tested
  final result = service.encryptData(plaintext);
  
  // Assert: Verify the expected outcome
  expect(result, isNotEmpty);
  expect(result, isNot(equals(plaintext)));
});
```

#### Descriptive Test Naming
```dart
// Good test names
test('WhenDivisorIsZero_ShouldThrowDivisionByZeroError', () { ... });
test('shouldReturnUserDataWhenValidCredentialsProvided', () { ... });
test('UserService.login() with invalid credentials throws AuthException', () { ... });

// Avoid vague names
test('test login', () { ... }); // Too vague
test('login test 1', () { ... }); // Not descriptive
```

### Grouping Related Tests

#### Using group() for Organization
```dart
group('EncryptionService', () {
  late EncryptionService service;
  
  setUp(() {
    service = EncryptionService(passphrase: 'test-passphrase');
  });
  
  tearDown(() {
    // Clean up if needed
  });
  
  test('should encrypt and decrypt data consistently', () async {
    const data = 'test data';
    final encrypted = service.encryptData(data);
    final decrypted = service.decryptData(encrypted);
    expect(decrypted, equals(data));
  });
  
  test('should produce different output for same input with different IV', () {
    const data = 'test';
    final result1 = service.encryptData(data);
    final result2 = service.encryptData(data);
    expect(result1, isNot(equals(result2)));
  });
});
```

### Test Data Organization

#### Test Fixtures and Helpers
```dart
// test/fixtures/auth_fixtures.dart
class AuthFixtures {
  static const validCredentials = {
    'username': 'testuser',
    'password': 'Password123!',
  };
  
  static const invalidCredentials = {
    'username': 'testuser',
    'password': 'wrong',
  };
}

// test/utils/test_helpers.dart
Future<void> pumpApp(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: widget),
    ),
  );
}
```

### Best Practices for Test Organization

1. **One Assertion Per Test**: Each test should verify one specific behavior
2. **Independent Tests**: Tests should not depend on each other or shared state
3. **Meaningful Group Names**: Use descriptive group names that reflect the component being tested
4. **Consistent Setup/Teardown**: Use setUp() and tearDown() for common test preparation
5. **Test Coverage**: Organize tests to cover all critical paths and edge cases

### Test Execution and Reporting

#### Running Specific Test Groups
```bash
# Run all unit tests
flutter test test/unit/

# Run specific test file
flutter test test/unit/services/crypto/encryption_service_test.dart

# Run tests with specific name pattern
flutter test --name="encryption"

# Generate test coverage report
flutter test --coverage
```

#### Test Tags for Organization
```dart
@Tags(['unit', 'crypto', 'security'])
group('EncryptionService', () {
  // Tests with specific tags
});

@Tags(['integration', 'auth'])
group('Authentication Flow', () {
  // Integration tests
});
```

### Performance Considerations

#### Efficient Test Organization
```dart
// Use setUpAll for expensive one-time setup
setUpAll(() async {
  await initializeTestDatabase();
});

// Use tearDownAll for cleanup
tearDownAll(() async {
  await cleanUpTestDatabase();
});

// Use mock objects for external dependencies
class MockApiClient extends Mock implements ApiClient {}
```

## References

- Flutter Secure Storage: https://pub.dev/packages/flutter_secure_storage
- Encryption Package: https://pub.dev/packages/encrypt
- Crypto Package: https://pub.dev/packages/crypto
- SSL Pinning: https://pub.dev/packages/flutter_ssl_pinning
- OWASP Mobile Security: https://owasp.org/www-project-mobile-security/
- Flutter Testing Guide: https://flutter.dev/docs/testing
- Dart Test Package: https://pub.dev/packages/test

## Version History
- Created: 2024-09-12
- Updated: 2025-09-12 (Added Service Classes, Crypto Utilities & Test Organization)
- Based on: PT003 Task Specifications
- Aligns with: Agent OS Development Standards