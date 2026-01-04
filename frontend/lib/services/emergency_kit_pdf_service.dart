import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr/qr.dart';
import 'package:file_selector/file_selector.dart' as file_selector;

/// Service for generating Emergency Backup Kit PDFs
///
/// This service creates professional PDF documents containing:
/// - User's backup code (BIP39 words or Base32)
/// - QR code for easy scanning
/// - Security guidance and warnings
/// - Printable format for safe storage
class EmergencyKitPdfService {
  static const double _pageMargin = 48.0;
  static const double _sectionSpacing = 24.0;
  static const double _itemSpacing = 12.0;

  /// Generate an Emergency Kit PDF
  ///
  /// [backupCode] - The plaintext backup code
  /// [username] - Optional username/identifier
  /// [includeQrCode] - Whether to include QR code (default: true)
  ///
  /// Returns the PDF as bytes
  Future<Uint8List> generateEmergencyKitPdf({
    required String backupCode,
    String? username,
    bool includeQrCode = true,
  }) async {
    final pdf = pw.Document();

    // Generate QR code image data if requested
    pw.ImageProvider? qrImage;
    if (includeQrCode) {
      qrImage = await _generateQrCodeImage(backupCode);
    }

    // Add the emergency kit page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(_pageMargin),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              pw.SizedBox(height: _sectionSpacing),

              // Title and warning
              _buildTitleSection(),
              pw.SizedBox(height: _sectionSpacing),

              // Main content in two columns
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left column - backup code
                    pw.Expanded(
                      flex: 3,
                      child: _buildBackupCodeSection(backupCode, username),
                    ),
                    pw.SizedBox(width: _sectionSpacing),

                    // Right column - QR code and guidance
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (includeQrCode && qrImage != null)
                            _buildQrCodeSection(qrImage),
                          if (includeQrCode && qrImage != null)
                            pw.SizedBox(height: _itemSpacing),
                          _buildSecurityGuidance(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Footer
              pw.SizedBox(height: _sectionSpacing),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Save the Emergency Kit PDF to a file
  ///
  /// [backupCode] - The plaintext backup code
  /// [username] - Optional username/identifier
  ///
  /// Returns the file path of the saved PDF
  Future<String> saveEmergencyKitPdf({
    required String backupCode,
    String? username,
  }) async {
    final pdfBytes = await generateEmergencyKitPdf(
      backupCode: backupCode,
      username: username,
      includeQrCode: true,
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'emergency_kit_$timestamp.pdf';

    // Use file selector on desktop platforms for save dialog
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      final result = await file_selector.getSaveLocation(
        acceptedTypeGroups: [
          file_selector.XTypeGroup(
            label: 'PDF Files',
            extensions: ['pdf'],
          ),
        ],
        suggestedName: filename,
      );

      if (result == null) {
        throw Exception('No file selected - save cancelled by user');
      }

      final file = File(result.path);
      await file.writeAsBytes(pdfBytes);
      return file.path;
    }

    // For mobile platforms, save to downloads directory directly
    final directory = await getDownloadsDirectory();
    final file = File('${directory?.path}/$filename');
    await file.writeAsBytes(pdfBytes);

    return file.path;
  }

  /// Print the Emergency Kit PDF
  ///
  /// [backupCode] - The plaintext backup code
  /// [username] - Optional username/identifier
  Future<void> printEmergencyKitPdf({
    required String backupCode,
    String? username,
  }) async {
    final pdfBytes = await generateEmergencyKitPdf(
      backupCode: backupCode,
      username: username,
      includeQrCode: true,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'emergency_kit.pdf',
    );
  }

  // ==================== PRIVATE METHODS ====================

  /// Build the header section
  pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'API Key Manager',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Text(
            'Emergency Backup Kit',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the title and warning section
  pw.Widget _buildTitleSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'IMPORTANT: KEEP THIS DOCUMENT SAFE',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.red700,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'This document contains your emergency backup code that can recover your account if you forget your master passphrase.',
          style: pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Store it in a secure location (safe, lockbox, or with a trusted person). Do not share it with anyone.',
          style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
        ),
      ],
    );
  }

  /// Build the backup code section
  pw.Widget _buildBackupCodeSection(String backupCode, String? username) {
    final isBip39 = backupCode.contains(' ');
    final lines = isBip39 ? backupCode.split(' ') : [backupCode];

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Your Emergency Backup Code',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),

          if (username != null) ...[
            pw.Text('Account: $username', style: pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 8),
          ],

          // Display code in a grid or single line
          if (isBip39)
            _buildBip39WordGrid(lines)
          else
            _buildBase32CodeDisplay(backupCode),

          pw.SizedBox(height: 16),
          pw.Text(
            'Use this code to recover your account if you forget your passphrase.',
            style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );
  }

  /// Build BIP39 word grid (4 columns x 6 rows for 24 words)
  pw.Widget _buildBip39WordGrid(List<String> words) {
    final rows = <List<String>>[];
    for (int i = 0; i < words.length; i += 4) {
      rows.add(words.sublist(i, (i + 4 < words.length) ? i + 4 : words.length));
    }

    return pw.Column(
      children: rows.map((row) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            children: row.map((word) {
              final index = words.indexOf(word) + 1;
              return pw.Expanded(
                child: pw.Container(
                  margin: const pw.EdgeInsets.only(right: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Text(
                    '$index. $word',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  /// Build Base32 code display
  pw.Widget _buildBase32CodeDisplay(String code) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Text(
        code,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  /// Build the QR code section
  pw.Widget _buildQrCodeSection(pw.ImageProvider qrImage) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'Scan QR Code',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Image(
              qrImage,
              width: 150,
              height: 150,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Contains your backup code',
            style: pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build the security guidance section
  pw.Widget _buildSecurityGuidance() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber100,
        border: pw.Border.all(color: PdfColors.amber700, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Security Guidelines',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.amber900,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildGuidelineItem('[+]', 'Store in a secure, private location'),
          _buildGuidelineItem('[+]', 'Keep physical copies in a safe or lockbox'),
          _buildGuidelineItem('[+]', 'Consider giving a copy to a trusted person'),
          _buildGuidelineItem('[!]', 'Do NOT share with untrusted individuals'),
          _buildGuidelineItem('[!]', 'Do NOT store in cloud storage unencrypted'),
          _buildGuidelineItem('[!]', 'Do NOT photograph or post online'),
          pw.SizedBox(height: 12),
          pw.Text(
            'This code can be used ONCE to recover your account. After use, generate a new emergency kit.',
            style: pw.TextStyle(
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.red700,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a single guidance item
  pw.Widget _buildGuidelineItem(String icon, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 20,
            child: pw.Text(
              icon,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the footer section
  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated: ${_formatDate(DateTime.now())}',
            style: pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'API Key Manager - Emergency Backup Kit v1.0',
            style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );
  }

  /// Generate QR code image from data
  /// Note: This is a placeholder implementation. QR code generation will be
  /// implemented when integrating with the Flutter UI using qr_flutter widgets.
  /// For now, this returns null to skip QR code in PDF.
  Future<pw.ImageProvider?> _generateQrCodeImage(String data) async {
    // QR code generation disabled for now
    // Will be implemented with qr_flutter widget in UI layer
    return null;
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Get the downloads directory
  Future<Directory?> getDownloadsDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows) {
      final directory = Directory('${Platform.environment['USERPROFILE']}\\Downloads');
      if (await directory.exists()) {
        return directory;
      }
    } else if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final directory = Directory('$home/Downloads');
        if (await directory.exists()) {
          return directory;
        }
      }
    }
    return await getApplicationDocumentsDirectory();
  }
}
