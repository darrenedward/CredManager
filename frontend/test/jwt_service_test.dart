import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/services/jwt_service.dart';
import 'package:cred_manager/services/key_derivation_service.dart';

void main() {
  group('JwtService', () {
    test('generateToken and verifyToken work correctly', () {
      final payload = {
        'sub': 'test_user',
        'iss': 'test_issuer',
      };
      final secret = 'test_secret';
      
      final token = JwtService.generateToken(payload, secret);
      expect(token, isNotNull);
      expect(token, isNotEmpty);
      
      final isValid = JwtService.verifyToken(token, secret);
      expect(isValid, isTrue);
    });
    
    test('verifyToken fails with wrong secret', () {
      final payload = {
        'sub': 'test_user',
        'iss': 'test_issuer',
      };
      final secret = 'test_secret';
      final wrongSecret = 'wrong_secret';
      
      final token = JwtService.generateToken(payload, secret);
      final isValid = JwtService.verifyToken(token, wrongSecret);
      expect(isValid, isFalse);
    });
    
    test('isTokenExpired works correctly', () {
      final payload = {
        'sub': 'test_user',
        'iss': 'test_issuer',
        'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600, // 1 hour ago
      };
      final secret = 'test_secret';

      final token = JwtService.generateToken(payload, secret);
      final isExpired = JwtService.isTokenExpired(token);
      expect(isExpired, isTrue);
    });
  });

  group('JwtService with Derived Secrets', () {
    test('generateTokenWithDerivedSecret and verifyTokenWithDerivedSecret work correctly', () async {
      final payload = {
        'sub': 'test_user',
        'iss': 'test_issuer',
      };
      const passphrase = 'TestPassphrase123!';
      final secretKey = await KeyDerivationService.deriveJwtSecret(passphrase);

      final token = JwtService.generateTokenWithDerivedSecret(payload, secretKey);
      expect(token, isNotNull);
      expect(token, isNotEmpty);

      final isValid = JwtService.verifyTokenWithDerivedSecret(token, secretKey);
      expect(isValid, isTrue);
    });

    test('verifyTokenWithDerivedSecret fails with wrong secret', () async {
      final payload = {
        'sub': 'test_user',
        'iss': 'test_issuer',
      };
      const passphrase1 = 'TestPassphrase123!';
      const passphrase2 = 'WrongPassphrase456!';
      final secretKey1 = await KeyDerivationService.deriveJwtSecret(passphrase1);
      final secretKey2 = await KeyDerivationService.deriveJwtSecret(passphrase2);

      final token = JwtService.generateTokenWithDerivedSecret(payload, secretKey1);
      final isValid = JwtService.verifyTokenWithDerivedSecret(token, secretKey2);
      expect(isValid, isFalse);
    });

    test('isTokenExpired works with derived secret tokens', () async {
      final payload = {
        'sub': 'test_user',
        'iss': 'test_issuer',
        'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600, // 1 hour ago
      };
      const passphrase = 'TestPassphrase123!';
      final secretKey = await KeyDerivationService.deriveJwtSecret(passphrase);

      final token = JwtService.generateTokenWithDerivedSecret(payload, secretKey);
      final isExpired = JwtService.isTokenExpired(token);
      expect(isExpired, isTrue);
    });
  });
}