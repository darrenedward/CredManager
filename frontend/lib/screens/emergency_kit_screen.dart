import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/emergency_backup_service.dart';
import '../services/emergency_kit_pdf_service.dart';

/// Emergency Backup Kit Screen
///
/// This screen allows users to:
/// 1. Generate a new emergency backup code
/// 2. Download the emergency kit as a PDF
/// 3. Print the emergency kit
/// 4. View their backup code
class EmergencyKitScreen extends StatefulWidget {
  const EmergencyKitScreen({super.key});

  @override
  State<EmergencyKitScreen> createState() => _EmergencyKitScreenState();
}

class _EmergencyKitScreenState extends State<EmergencyKitScreen> {
  final EmergencyBackupService _backupService = EmergencyBackupService();
  final EmergencyKitPdfService _pdfService = EmergencyKitPdfService();

  bool _isLoading = false;
  bool _hasBackupCode = false;
  DateTime? _backupCodeCreated;
  bool _backupCodeUsed = false;
  String? _generatedBackupCode;
  String? _pdfPath;

  BackupCodeFormat _selectedFormat = BackupCodeFormat.bip39;

  @override
  void initState() {
    super.initState();
    _checkBackupCodeStatus();
  }

  Future<void> _checkBackupCodeStatus() async {
    final hasCode = await _backupService.hasBackupCode();
    final created = await _backupService.getBackupCodeCreationDate();
    final used = await _backupService.wasBackupCodeUsed();

    setState(() {
      _hasBackupCode = hasCode;
      _backupCodeCreated = created;
      _backupCodeUsed = used;
    });
  }

  Future<void> _generateBackupCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Generate new backup code
      final backupCode = await _backupService.generateBackupCode(
        format: _selectedFormat,
      );

      // Hash and store it
      final hashedCode = await _backupService.hashBackupCode(backupCode);
      await _backupService.storeBackupCodeHash(hashedCode);

      setState(() {
        _generatedBackupCode = backupCode;
        _hasBackupCode = true;
        _backupCodeCreated = DateTime.now();
        _backupCodeUsed = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency backup code generated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate backup code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_generatedBackupCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate a backup code first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final path = await _pdfService.saveEmergencyKitPdf(
        backupCode: _generatedBackupCode!,
        username: null,
      );

      setState(() {
        _pdfPath = path;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency kit saved to: $path'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printPdf() async {
    if (_generatedBackupCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate a backup code first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _pdfService.printEmergencyKitPdf(
        backupCode: _generatedBackupCode!,
        username: null,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard() async {
    if (_generatedBackupCode == null) return;

    await Clipboard.setData(ClipboardData(text: _generatedBackupCode!));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup code copied to clipboard'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _regenerateCode() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Backup Code?'),
        content: const Text(
          'This will invalidate your current backup code and generate a new one. '
          'Make sure you have saved the current code before proceeding.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _generateBackupCode();
    }
  }

  void _showBackupCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Emergency Backup Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'IMPORTANT: Write this down and store it safely!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              width: double.infinity,
              child: Text(
                _generatedBackupCode ?? '',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Store this code in a secure location. You can use it to recover your account if you forget your passphrase.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              _copyToClipboard();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Backup Kit'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[700]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Backup Kit',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Generate a backup code to recover your account if you forget your passphrase. '
                                'Store it in a secure location.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Current status card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Backup Code Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_hasBackupCode)
                                Icon(
                                  _backupCodeUsed
                                      ? Icons.check_circle_outline
                                      : Icons.shield_rounded,
                                  color: _backupCodeUsed
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (!_hasBackupCode)
                            const Text(
                              'No backup code generated yet.',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Created: ${_formatDate(_backupCodeCreated)}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_backupCodeUsed)
                                  const Row(
                                    children: [
                                      Icon(Icons.info_outline, size: 18, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text(
                                        'This code has been used. Generate a new one.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  const Row(
                                    children: [
                                      Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text(
                                        'Code is ready to use',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Format selection
                  if (!_hasBackupCode) ...[
                    const Text(
                      'Backup Code Format',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          RadioListTile<BackupCodeFormat>(
                            title: const Text('24-Word Phrase (BIP39)'),
                            subtitle: const Text(
                              'Easy to write down, industry standard for cryptocurrency wallets',
                            ),
                            value: BackupCodeFormat.bip39,
                            groupValue: _selectedFormat,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedFormat = value;
                                });
                              }
                            },
                          ),
                          RadioListTile<BackupCodeFormat>(
                            title: const Text('Base32 Code'),
                            subtitle: const Text(
                              'Compact format, 52 characters',
                            ),
                            value: BackupCodeFormat.base32,
                            groupValue: _selectedFormat,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedFormat = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Actions
                  const Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_hasBackupCode && !_backupCodeUsed)
                          ? _regenerateCode
                          : _generateBackupCode,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: _hasBackupCode ? Colors.orange : null,
                      ),
                      icon: const Icon(Icons.security_rounded),
                      label: Text(
                        _hasBackupCode ? 'Regenerate Backup Code' : 'Generate Backup Code',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  if (_hasBackupCode && _generatedBackupCode != null) ...[
                    const SizedBox(height: 12),

                    // View code button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showBackupCodeDialog,
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Backup Code'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Download PDF button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _downloadPdf,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Download Emergency Kit (PDF)'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.blue[700],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Print button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _printPdf,
                        icon: const Icon(Icons.print),
                        label: const Text('Print Emergency Kit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Copy to clipboard button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy to Clipboard'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Security guidelines
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Security Guidelines',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildGuideline('[+]', 'Store in a secure, private location'),
                          _buildGuideline('[+]', 'Keep physical copies in a safe or lockbox'),
                          _buildGuideline('[+]', 'Consider giving a copy to a trusted person'),
                          _buildGuideline('[!]', 'Do NOT share with untrusted individuals'),
                          _buildGuideline('[!]', 'Do NOT store in cloud storage unencrypted'),
                          _buildGuideline('[!]', 'Do NOT photograph or post online'),
                          const SizedBox(height: 12),
                          Text(
                            'This code can be used ONCE to recover your account. After use, generate a new emergency kit.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGuideline(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              icon,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
