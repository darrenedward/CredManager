# Argon2 Password Verification Test Plan

## Overview

This document outlines the comprehensive testing strategy for the Argon2 password verification functionality (ST001) in the APIKeyManager Flutter application. The tests focus on the `argon2_service.dart` implementation with emphasis on security, edge cases, and performance requirements.

## Context Analysis

Based on the project context and specifications:
- **Primary Target**: `Argon2Service.verifyPassword()` method
- **Security Requirements**: Argon2id hashing only, no SHA-256 fallback
- **Performance Target**: <500ms verification time
- **Input Normalization**: Proper whitespace trimming and handling
- **Error Handling**: Graceful handling of malformed inputs

## Test Strategy

### 1. Unit Test Approach (TDD)
- **Framework**: Flutter Test framework with `flutter_test` package
- **Test Structure**: Organized in descriptive groups for clarity
- **TDD Methodology**: Write failing tests first, then implement functionality
- **Mock Strategy**: Mock external dependencies where appropriate
- **Performance Testing**: Include timing assertions for verification operations

### 2. Test Coverage Requirements

#### Core Verification Tests
- ✅ Correct password verification returns `true`
- ✅ Incorrect password verification returns `false`
- ✅ Case-sensitive password verification
- ✅ Empty password handling
- ✅ Null password handling

#### Input Normalization Tests
- ✅ Leading whitespace trimming
- ✅ Trailing whitespace trimming
- ✅ Multiple spaces handling
- ✅ Tab and newline character handling
- ✅ Unicode character handling

#### Special Character Tests
- ✅ Special characters in passwords (!@#$%^&*)
- ✅ Unicode characters (émojis, accents)
- ✅ Very long passwords (>1000 characters)
- ✅ Passwords with only whitespace

#### Error Handling Tests
- ✅ Malformed hash format
- ✅ Invalid base64 encoding in hash
- ✅ Missing hash components
- ✅ Invalid Argon2 parameters
- ✅ Corrupted salt or hash data

#### Performance Tests
- ✅ Verification completes within 500ms
- ✅ Memory usage remains reasonable
- ✅ No memory leaks during repeated operations

#### Security Tests
- ✅ Constant-time comparison prevents timing attacks
- ✅ No password data leakage in error messages
- ✅ Proper handling of concurrent verification requests

## Test Implementation Structure

### Test File Organization
```
frontend/test/
├── argon2_service_test.dart (NEW - dedicated Argon2 tests)
└── auth_service_test.dart (UPDATED - integration with Argon2)
```

### Test Groups
1. **Password Verification Core Functionality**
2. **Input Normalization and Trimming**
3. **Edge Cases and Special Characters**
4. **Error Handling and Malformed Inputs**
5. **Performance and Security Validation**

## Expected Test Scenarios

### Group 1: Core Functionality
```dart
group('Argon2 Password Verification - Core Functionality', () {
  test('verifyPassword returns true for correct password', () async {
    // TDD: Initially fails until verifyPassword is properly implemented
  });
  
  test('verifyPassword returns false for incorrect password', () async {
    // TDD: Initially fails until verifyPassword is properly implemented
  });
});
```

### Group 2: Input Normalization
```dart
group('Argon2 Password Verification - Input Normalization', () {
  test('verifyPassword handles leading whitespace', () async {
    // Test: "  password" should match "password" hash after trimming
  });
  
  test('verifyPassword handles trailing whitespace', () async {
    // Test: "password  " should match "password" hash after trimming
  });
});
```

### Group 3: Edge Cases
```dart
group('Argon2 Password Verification - Edge Cases', () {
  test('verifyPassword handles empty password', () async {
    // Test: Empty string should be handled gracefully
  });
  
  test('verifyPassword handles special characters', () async {
    // Test: Passwords with !@#$%^&*() characters
  });
});
```

### Group 4: Error Handling
```dart
group('Argon2 Password Verification - Error Handling', () {
  test('verifyPassword handles malformed hash', () async {
    // Test: Invalid hash format should return false, not throw
  });
  
  test('verifyPassword handles invalid base64', () async {
    // Test: Corrupted base64 encoding should be handled gracefully
  });
});
```

### Group 5: Performance and Security
```dart
group('Argon2 Password Verification - Performance & Security', () {
  test('verifyPassword completes within 500ms', () async {
    // Test: Performance requirement validation
  });
  
  test('constant-time comparison prevents timing attacks', () async {
    // Test: Verification time should be consistent regardless of password
  });
});
```

## Mock Strategy

### Dependencies to Mock
- **External Crypto Operations**: Mock the `cryptography` package if needed for consistent testing
- **System Resources**: Mock memory/CPU intensive operations for performance tests
- **Random Generation**: Mock salt generation for predictable test hashes

### Test Data Generation
- **Known Good Hashes**: Pre-computed Argon2 hashes for test passwords
- **Malformed Hashes**: Invalid hash formats for error testing
- **Edge Case Passwords**: Special character and Unicode test cases

## Acceptance Criteria

### Test Organization
- ✅ Tests organized in logical groups with descriptive names
- ✅ Each test has clear setup, execution, and assertion phases
- ✅ Test failures provide meaningful error messages

### Coverage Requirements
- ✅ All public methods of `Argon2Service` are tested
- ✅ All edge cases identified in requirements are covered
- ✅ Error handling paths are validated
- ✅ Performance requirements are verified

### TDD Compliance
- ✅ Tests written before implementation
- ✅ Tests initially fail (proving they test the right thing)
- ✅ Implementation makes tests pass
- ✅ Refactoring maintains test success

## Implementation Notes

### Password Normalization Strategy
According to the spec, passwords should be trimmed before verification to fix parsing bugs. Tests will validate:
- Leading/trailing whitespace removal
- Consistent handling across hash generation and verification
- No impact on legitimate whitespace within passwords

### Performance Considerations
- Tests should validate <500ms requirement for individual verifications
- Batch testing for memory leak detection
- Concurrent verification testing for thread safety

### Security Validation
- Timing attack resistance through constant-time comparison testing
- No sensitive data exposure in error messages or logs
- Proper cleanup of password data from memory

## Next Steps

1. Create dedicated `argon2_service_test.dart` file
2. Implement all test cases using TDD methodology
3. Ensure tests initially fail (proving they work)
4. Update existing `auth_service_test.dart` for integration testing
5. Validate test coverage meets acceptance criteria
6. Execute tests to confirm TDD approach is successful

## Risk Mitigation

### Potential Issues
- **Crypto Library Compatibility**: Tests may need mocking for consistent cross-platform behavior
- **Performance Variance**: Hardware differences may affect timing tests
- **Unicode Handling**: Platform-specific Unicode normalization differences

### Mitigation Strategies
- Use relative performance assertions rather than absolute timing
- Include platform-specific test variations where needed
- Mock external dependencies for consistent behavior
- Include comprehensive error handling test coverage