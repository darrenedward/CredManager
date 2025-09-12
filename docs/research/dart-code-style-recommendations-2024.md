# Dart Code Style Recommendations 2024

## Overview

This document provides comprehensive Dart code style recommendations based on current industry best practices, Flutter documentation, and security considerations for the Agent OS development framework.

## Naming Conventions

### File Naming
- **Source Files**: Use `lowercase_with_underscores.dart` (e.g., `user_service.dart`)
- **Test Files**: Append `_test.dart` (e.g., `user_service_test.dart`)
- **Directory Names**: Use `lowercase_with_underscores` (e.g., `lib/services/auth/`)

### Class Naming
```dart
// Use UpperCamelCase for classes
class UserAuthenticationService { ... }
class CryptoUtils { ... }
class ApiClient { ... }
```

### Method and Function Naming
```dart
// Use lowerCamelCase for methods and functions
Future<User> authenticateUser(String username, String password) { ... }
String generateSecureToken() { ... }
void validateInput(String input) { ... }
```

### Variable Naming
```dart
// Use lowerCamelCase for variables
final userService = UserService();
const maxLoginAttempts = 5;
var isLoading = false;

// Boolean variables should sound like questions
bool isAuthenticated = false;
bool hasPermission = true;
bool shouldRefresh = true;
```

### Constant Naming
```dart
// Use lowerCamelCase for constants
const defaultTimeout = Duration(seconds: 30);
const minPasswordLength = 12;

// Use UPPER_CASE for compile-time constants
const String API_BASE_URL = 'https://api.example.com';
const int MAX_RETRY_ATTEMPTS = 3;
```

## Code Organization

### Project Structure
```
lib/
├── services/           # Business logic services
│   ├── auth/          # Authentication services
│   ├── crypto/        # Cryptographic services
│   ├── network/       # Network services
│   └── storage/       # Storage services
├── models/            # Data models
│   ├── user.dart
│   ├── auth.dart
│   └── api/
├── utils/             # Utility classes
│   ├── validation.dart
│   ├── extensions.dart
│   └── constants.dart
├── widgets/           # Reusable widgets
│   ├── common/
│   └── auth/
└── main.dart          # Application entry point
```

### Service Class Organization
```dart
// Service classes should follow dependency injection pattern
class AuthenticationService {
  final UserService _userService;
  final TokenService _tokenService;
  final ApiClient _apiClient;

  AuthenticationService({
    required UserService userService,
    required TokenService tokenService,
    required ApiClient apiClient,
  }) : _userService = userService,
       _tokenService = tokenService,
       _apiClient = apiClient;

  Future<User> login(String username, String password) async {
    // Business logic implementation
  }
}
```

### Method Ordering
```dart
class ExampleService {
  // 1. Public properties
  final String apiUrl;
  
  // 2. Private properties
  final _httpClient = HttpClient();
  
  // 3. Constructors
  ExampleService({required this.apiUrl});
  
  // 4. Public methods
  Future<Data> fetchData() async { ... }
  
  // 5. Private methods
  String _formatUrl(String endpoint) { ... }
}
```

## Code Formatting

### Line Length
- **Maximum**: 80-100 characters per line
- **Exception**: Long strings, URLs, or import statements

### Indentation
- **Spaces**: 2 spaces per indentation level (not tabs)
- **Alignment**: Align related elements vertically

### Braces and Spacing
```dart
// Good spacing
void exampleFunction(String parameter) {
  if (condition) {
    // Code here
  } else {
    // Alternative code
  }
}

// Method calls with multiple parameters
service.doSomething(
  parameter1,
  parameter2,
  parameter3,
);
```

## Documentation Standards

### Class Documentation
```dart
/// Service responsible for user authentication and session management.
///
/// This service handles login, logout, token refresh, and authentication
/// state management throughout the application.
class AuthenticationService {
  // ...
}
```

### Method Documentation
```dart
/// Authenticates a user with provided credentials.
///
/// Throws [AuthenticationException] if credentials are invalid or
/// [NetworkException] if there's a connection issue.
///
/// Returns [User] object upon successful authentication.
Future<User> authenticate(String username, String password) async {
  // Implementation
}
```

### Parameter Documentation
```dart
/// Validates user input against security requirements.
///
/// [input]: The user input to validate
/// [minLength]: Minimum required length (default: 8)
/// [requireSpecialChars]: Whether to require special characters
bool validateInput(
  String input, {
  int minLength = 8,
  bool requireSpecialChars = true,
}) {
  // Validation logic
}
```

## Testing Best Practices

### Test Structure
```dart
// test/unit/services/auth/authentication_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockUserService extends Mock implements UserService {}

void main() {
  late AuthenticationService authService;
  late MockUserService mockUserService;

  setUp(() {
    mockUserService = MockUserService();
    authService = AuthenticationService(userService: mockUserService);
  });

  group('AuthenticationService', () {
    test('should authenticate user with valid credentials', () async {
      // Arrange
      when(mockUserService.validateCredentials('user', 'pass'))
          .thenAnswer((_) async => true);
      
      // Act
      final result = await authService.authenticate('user', 'pass');
      
      // Assert
      expect(result, isTrue);
    });
  });
}
```

### Test Naming Convention
```dart
// Use descriptive test names
test('WhenUserProvidesValidCredentials_ShouldReturnTrue', () { ... });
test('shouldThrowValidationErrorWhenEmailIsInvalid', () { ... });
test('UserService.login() with empty password throws ArgumentError', () { ... });
```

### AAA Pattern (Arrange-Act-Assert)
```dart
test('should encrypt data with AES algorithm', () {
  // Arrange
  final service = EncryptionService(key: 'secret-key');
  const plaintext = 'sensitive data';
  
  // Act
  final result = service.encrypt(plaintext);
  
  // Assert
  expect(result, isNotEmpty);
  expect(result, isNot(equals(plaintext)));
});
```

## Security Best Practices

### Input Validation
```dart
/// Validates email format with proper security considerations
bool isValidEmail(String email) {
  const pattern = r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$';
  final regex = RegExp(pattern);
  return regex.hasMatch(email) && email.length <= 254;
}
```

### Secure Storage
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
}
```

### Cryptographic Operations
```dart
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  final encrypt.Encrypter _encrypter;
  final encrypt.IV _iv;

  EncryptionService({required String key})
      : _encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(key))),
        _iv = encrypt.IV.fromLength(16);

  String encryptData(String plaintext) {
    return _encrypter.encrypt(plaintext, iv: _iv).base64;
  }
}
```

## Error Handling

### Custom Exception Classes
```dart
/// Base class for authentication-related exceptions
abstract class AuthenticationException implements Exception {
  final String message;
  final Object? cause;

  AuthenticationException(this.message, [this.cause]);

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Thrown when invalid credentials are provided
class InvalidCredentialsException extends AuthenticationException {
  InvalidCredentialsException() : super('Invalid username or password');
}

/// Thrown when account is locked due to too many failed attempts
class AccountLockedException extends AuthenticationException {
  AccountLockedException(Duration lockDuration)
      : super('Account locked for ${lockDuration.inMinutes} minutes');
}
```

### Error Handling Patterns
```dart
Future<User> login(String username, String password) async {
  try {
    final response = await _apiClient.post('/login', {
      'username': username,
      'password': password,
    });
    
    return User.fromJson(response.data);
  } on SocketException catch (e) {
    throw NetworkException('No internet connection', e);
  } on HttpException catch (e) {
    if (e.statusCode == 401) {
      throw InvalidCredentialsException();
    }
    rethrow;
  }
}
```

## Performance Considerations

### Asynchronous Operations
```dart
// Use compute() for expensive operations
Future<String> hashPassword(String password) async {
  return await compute(_hashPasswordIsolate, password);
}

String _hashPasswordIsolate(String password) {
  // Expensive cryptographic operation
  return Argon2().hashPassword(password);
}
```

### Memory Management
```dart
// Secure memory cleanup
void secureZero(List<int> data) {
  for (var i = 0; i < data.length; i++) {
    data[i] = 0;
  }
}

void logout() {
  secureZero(_passwordBytes);
  _password = null;
  _clearSensitiveData();
}
```

## Linting and Analysis

### Recommended Analysis Options
```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    # Security-related warnings
    use_key_in_widget_constructors: error
    missing_required_param: error
    invalid_use_of_protected_member: error
    
  exclude:
    - '**/*.g.dart'
    - '**/*.freezed.dart'

linter:
  rules:
    # Code style rules
    - always_use_package_imports
    - avoid_empty_else
    - avoid_print
    - camel_case_types
    - constant_identifier_names
    - empty_constructor_bodies
    - library_names
    - library_prefixes
    - non_constant_identifier_names
    - prefer_final_fields
    - prefer_final_locals
    - sort_constructors_first
    - sort_unnamed_constructors_first
    
    # Security rules
    - avoid_web_libraries_in_flutter
    - no_leading_underscores_for_local_identifiers
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_in_for_each
```

## Version Control Best Practices

### Commit Messages
```
feat(auth): implement JWT token refresh mechanism

- Added token refresh functionality to AuthenticationService
- Implemented automatic token renewal before expiration
- Added comprehensive tests for refresh scenarios

Fixes #123
```

### Branch Naming
```
feature/user-authentication
bugfix/fix-login-issue  
hotfix/security-patch
release/v1.2.0
```

## References

- Dart Style Guide: https://dart.dev/guides/language/effective-dart/style
- Flutter Testing: https://flutter.dev/docs/testing
- OWASP Mobile Security: https://owasp.org/www-project-mobile-security/
- Dart Cryptography: https://pub.dev/packages/cryptography
- Flutter Secure Storage: https://pub.dev/packages/flutter_secure_storage

## Version History
- Created: 2024-09-12
- Based on: Current Dart/Flutter best practices and security standards
- Aligns with: Agent OS Development Standards