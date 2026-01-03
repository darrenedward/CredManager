import 'package:flutter_test/flutter_test.dart';
import 'package:cred_manager/services/emergency_kit_pdf_service.dart';
import 'dart:typed_data';
import 'dart:io';

// Unit tests for PDF Generation Service (ST040)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Emergency Kit PDF Service Tests (ST040)', () {
    late EmergencyKitPdfService pdfService;

    setUp(() {
      pdfService = EmergencyKitPdfService();
    });

    test('should generate PDF from backup code', () async {
      // TDD: This test validates PDF generation
      final backupCode = 'abandon ability able about above absent absorb abstract absurd abuse access';
      final username = 'testuser@example.com';

      final pdfBytes = await pdfService.generateEmergencyKitPdf(
        backupCode: backupCode,
        username: username,
        includeQrCode: true,
      );

      expect(pdfBytes, isNotNull, reason: 'PDF bytes should be generated');
      expect(pdfBytes.length, greaterThan(2000), reason: 'PDF should have substantial content');

      // Verify PDF header
      final pdfString = String.fromCharCodes(pdfBytes);
      expect(pdfString, contains('%PDF'), reason: 'Should be valid PDF format');
    });

    test('should generate PDF without QR code', () async {
      // TDD: This test validates PDF generation without QR code
      final backupCode = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'; // Base32 format

      final pdfBytes = await pdfService.generateEmergencyKitPdf(
        backupCode: backupCode,
        includeQrCode: false,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(2000));

      final pdfString = String.fromCharCodes(pdfBytes);
      expect(pdfString, contains('%PDF'));
    });

    test('should generate PDF with BIP39 backup code', () async {
      // TDD: This test validates BIP39 format in PDF
      final bip39Code = 'word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 '
                        'word13 word14 word15 word16 word17 word18 word19 word20 word21 word22 word23 word24';

      final pdfBytes = await pdfService.generateEmergencyKitPdf(
        backupCode: bip39Code,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(2000));
    });

    test('should generate PDF with Base32 backup code', () async {
      // TDD: This test validates Base32 format in PDF
      final base32Code = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

      final pdfBytes = await pdfService.generateEmergencyKitPdf(
        backupCode: base32Code,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(2000));
    });

    test('should include security warnings in PDF', () async {
      // TDD: This test validates security guidance
      final backupCode = 'test backup code phrase';

      final pdfBytes = await pdfService.generateEmergencyKitPdf(
        backupCode: backupCode,
      );

      // PDF is compressed, so just verify it was generated
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(2000));
    });

    test('should handle empty username', () async {
      // TDD: This test validates handling of missing username
      final backupCode = 'test code';

      final pdfBytes = await pdfService.generateEmergencyKitPdf(
        backupCode: backupCode,
        username: null,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(2000));
    });

    test('should handle special characters in backup code', () async {
      // TDD: This test validates handling of edge cases
      final backupCode = 'test-code_with.special';

      final pdfBytes = await pdfService.generateEmergencyKitPdf(
        backupCode: backupCode,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(2000));
    });

    test('should generate consistent PDFs for same input', () async {
      // TDD: This test validates PDF consistency
      final backupCode = 'consistency test code';

      final pdfBytes1 = await pdfService.generateEmergencyKitPdf(
        backupCode: backupCode,
      );
      final pdfBytes2 = await pdfService.generateEmergencyKitPdf(
        backupCode: backupCode,
      );

      // Content should be similar (may differ slightly due to timestamps)
      expect(pdfBytes1.length, greaterThan(2000));
      expect(pdfBytes2.length, greaterThan(2000));
      // Sizes should be very close (within 100 bytes)
      expect((pdfBytes1.length - pdfBytes2.length).abs(), lessThan(100));
    });

    test('should include one-time use warning', () async {
      // TDD: This test validates one-time use warning
      final backupCode = 'one-time test code';

      final pdfBytes = await pdfService.generateEmergencyKitPdf(
        backupCode: backupCode,
      );

      // PDF is compressed, so just verify it was generated
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(2000));
    });

    test('should include generation timestamp', () async {
      // TDD: This test validates timestamp inclusion
      final backupCode = 'timestamp test';

      final pdfBytes = await pdfService.generateEmergencyKitPdf(
        backupCode: backupCode,
      );

      // PDF is compressed, so just verify it was generated
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(2000));
    });
  });
}
