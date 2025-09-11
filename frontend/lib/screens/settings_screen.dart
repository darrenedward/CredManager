import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import '../models/auth_state.dart';
import '../models/dashboard_state.dart';
import '../services/theme_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Accordion state
  String? _expandedCard;

  // Security Settings
  int _selectedTimeout = AppConstants.defaultSessionTimeout;
  bool _biometricEnabled = false;
  bool _autoLockEnabled = true;

  // Password Generation Settings
  int _passwordLength = 16;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  bool _avoidAmbiguous = true;

  // Passphrase Requirements
  int _minPassphraseLength = 12;
  bool _requireUppercase = true;
  bool _requireLowercase = true;
  bool _requireNumbers = true;
  bool _requireSymbols = false;

  // Backup & Recovery
  bool _enableBackupPhrase = false;
  bool _autoBackup = false;
  int _backupFrequency = 7; // days

  // UI Settings
  bool _darkMode = false;
  bool _showWelcomeScreen = true;

  // User Experience
  bool _autoCopyPasswords = true;
  bool _showPasswordStrength = true;
  bool _enableQuickActions = true;
  int _maxRecentItems = 5;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    setState(() {
      _selectedTimeout = authState.sessionTimeoutMinutes;
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = Provider.of<AuthState>(context, listen: false);
      await authState.updateSessionTimeout(_selectedTimeout);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save settings. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getProjectsData() {
    try {
      final dashboardState = Provider.of<DashboardState>(context, listen: false);
      return dashboardState.projects.map((p) => p.toJson()).toList();
    } catch (e) {
      print('Error getting projects data for export: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _getAiServicesData() {
    try {
      final dashboardState = Provider.of<DashboardState>(context, listen: false);
      return dashboardState.aiServices.map((s) => s.toJson()).toList();
    } catch (e) {
      print('Error getting AI services data for export: $e');
      return [];
    }
  }

  Future<void> _exportData() async {
    try {
      // Create export data structure
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'appName': AppConstants.appName,
        'settings': {
          'sessionTimeout': _selectedTimeout,
          'biometricEnabled': _biometricEnabled,
          'autoLockEnabled': _autoLockEnabled,
          'passwordLength': _passwordLength,
          'includeUppercase': _includeUppercase,
          'includeLowercase': _includeLowercase,
          'includeNumbers': _includeNumbers,
          'includeSymbols': _includeSymbols,
          'avoidAmbiguous': _avoidAmbiguous,
          'minPassphraseLength': _minPassphraseLength,
          'requireUppercase': _requireUppercase,
          'requireLowercase': _requireLowercase,
          'requireNumbers': _requireNumbers,
          'requireSymbols': _requireSymbols,
          'enableBackupPhrase': _enableBackupPhrase,
          'autoBackup': _autoBackup,
          'backupFrequency': _backupFrequency,
          'darkMode': _darkMode,
          'showWelcomeScreen': _showWelcomeScreen,
          'autoCopyPasswords': _autoCopyPasswords,
          'showPasswordStrength': _showPasswordStrength,
          'enableQuickActions': _enableQuickActions,
          'maxRecentItems': _maxRecentItems,
        },
        'projects': _getProjectsData(),
        'aiServices': _getAiServicesData(),
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Copy to clipboard for now (in a real app, you'd save to file)
      await Clipboard.setData(ClipboardData(text: jsonString));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Data exported to clipboard! Paste into a text file to save.')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Import Data'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Paste your exported JSON data below:'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    hintText: 'Paste JSON data here...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final jsonData = jsonDecode(controller.text);
                  await _processImportData(jsonData);
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Import failed: Invalid JSON format'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processImportData(Map<String, dynamic> data) async {
    try {
      // Validate data structure
      if (data['version'] == null || data['settings'] == null) {
        throw Exception('Invalid data format');
      }

      // Import settings
      final settings = data['settings'] as Map<String, dynamic>;
      setState(() {
        _selectedTimeout = settings['sessionTimeout'] ?? _selectedTimeout;
        _biometricEnabled = settings['biometricEnabled'] ?? _biometricEnabled;
        _autoLockEnabled = settings['autoLockEnabled'] ?? _autoLockEnabled;
        _passwordLength = settings['passwordLength'] ?? _passwordLength;
        _includeUppercase = settings['includeUppercase'] ?? _includeUppercase;
        _includeLowercase = settings['includeLowercase'] ?? _includeLowercase;
        _includeNumbers = settings['includeNumbers'] ?? _includeNumbers;
        _includeSymbols = settings['includeSymbols'] ?? _includeSymbols;
        _avoidAmbiguous = settings['avoidAmbiguous'] ?? _avoidAmbiguous;
        _minPassphraseLength = settings['minPassphraseLength'] ?? _minPassphraseLength;
        _requireUppercase = settings['requireUppercase'] ?? _requireUppercase;
        _requireLowercase = settings['requireLowercase'] ?? _requireLowercase;
        _requireNumbers = settings['requireNumbers'] ?? _requireNumbers;
        _requireSymbols = settings['requireSymbols'] ?? _requireSymbols;
        _enableBackupPhrase = settings['enableBackupPhrase'] ?? _enableBackupPhrase;
        _autoBackup = settings['autoBackup'] ?? _autoBackup;
        _backupFrequency = settings['backupFrequency'] ?? _backupFrequency;
        _darkMode = settings['darkMode'] ?? _darkMode;
        _showWelcomeScreen = settings['showWelcomeScreen'] ?? _showWelcomeScreen;
        _autoCopyPasswords = settings['autoCopyPasswords'] ?? _autoCopyPasswords;
        _showPasswordStrength = settings['showPasswordStrength'] ?? _showPasswordStrength;
        _enableQuickActions = settings['enableQuickActions'] ?? _enableQuickActions;
        _maxRecentItems = settings['maxRecentItems'] ?? _maxRecentItems;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Settings imported successfully!'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'This will permanently delete all your projects, API keys, and settings. This action cannot be undone. Make sure you have backed up any important data before proceeding.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement clear all data functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data clearing not yet implemented'),
                    backgroundColor: Colors.amber,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear All Data'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Security Settings
            _buildExpandableCard(
              'security',
              'Security Settings',
              'Configure security preferences and authentication',
              Icons.security,
              AppConstants.supportIconColor1,
              [
                _buildSettingItem(
                  'Session Timeout',
                  'Set how long you can be inactive before being automatically logged out.',
                  _buildTimeoutSelector(),
                ),
                const Divider(),
                _buildSwitchSetting(
                  'Auto-lock',
                  'Automatically lock the app when inactive',
                  _autoLockEnabled,
                  (value) => setState(() => _autoLockEnabled = value),
                ),
                const Divider(),
                _buildSwitchSetting(
                  'Biometric Authentication',
                  'Use fingerprint or face unlock',
                  _biometricEnabled,
                  (value) => setState(() => _biometricEnabled = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Passphrase Requirements
            _buildExpandableCard(
              'passphrase',
              'Passphrase Requirements',
              'Set security requirements for passphrases',
              Icons.vpn_key,
              AppConstants.supportIconColor2,
              [
                _buildSliderSetting(
                  'Minimum Length',
                  'Minimum characters required for passphrases',
                  _minPassphraseLength.toDouble(),
                  8,
                  32,
                  (value) => setState(() => _minPassphraseLength = value.toInt()),
                ),
                const Divider(),
                _buildSwitchSetting(
                  'Require Uppercase',
                  'Passphrase must contain uppercase letters (A-Z)',
                  _requireUppercase,
                  (value) => setState(() => _requireUppercase = value),
                ),
                const Divider(),
                _buildSwitchSetting(
                  'Require Lowercase',
                  'Passphrase must contain lowercase letters (a-z)',
                  _requireLowercase,
                  (value) => setState(() => _requireLowercase = value),
                ),
                const Divider(),
                _buildSwitchSetting(
                  'Require Numbers',
                  'Passphrase must contain numbers (0-9)',
                  _requireNumbers,
                  (value) => setState(() => _requireNumbers = value),
                ),
                const Divider(),
                _buildSwitchSetting(
                  'Require Symbols',
                  'Passphrase must contain special characters (!@#\$%)',
                  _requireSymbols,
                  (value) => setState(() => _requireSymbols = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Password Generation
            _buildExpandableCard(
              'password',
              'Password Generation',
              'Configure default settings for password generation',
              Icons.password,
              AppConstants.supportIconColor3,
              [
                _buildSliderSetting(
                  'Default Length',
                  'Default length for generated passwords',
                  _passwordLength.toDouble(),
                  8,
                  64,
                  (value) => setState(() => _passwordLength = value.toInt()),
                ),
                const Divider(),
                _buildSwitchSetting(
                  'Include Uppercase',
                  'Include uppercase letters (A-Z)',
                  _includeUppercase,
                  (value) => setState(() => _includeUppercase = value),
                ),
                const Divider(),
                _buildSwitchSetting(
                  'Include Lowercase',
                  'Include lowercase letters (a-z)',
                  _includeLowercase,
                  (value) => setState(() => _includeLowercase = value),
                ),
                const Divider(),
                _buildSwitchSetting(
                  'Include Numbers',
                  'Include numbers (0-9)',
                  _includeNumbers,
                  (value) => setState(() => _includeNumbers = value),
                ),
                const Divider(),
                _buildSwitchSetting(
                  'Include Symbols',
                  'Include special characters (!@#\$%)',
                  _includeSymbols,
                  (value) => setState(() => _includeSymbols = value),
                ),
                const Divider(),
                _buildSwitchSetting(
                  'Avoid Ambiguous',
                  'Avoid similar characters (0/O, 1/l/I)',
                  _avoidAmbiguous,
                  (value) => setState(() => _avoidAmbiguous = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Appearance & Experience
            _buildExpandableCard(
              'appearance',
              'Appearance & Experience',
              'Customize the app look and behavior',
              Icons.palette,
              AppConstants.supportIconColor4,
              [
                Consumer<ThemeService>(
                  builder: (context, themeService, child) => _buildSwitchSetting(
                    'Dark Mode',
                    'Use dark theme for the interface',
                    themeService.isDarkMode,
                    (value) async {
                      await themeService.setDarkMode(value);
                      setState(() => _darkMode = value);
                    },
                  ),
                ),
                const Divider(),
                _buildSwitchSetting(
                  'Show Welcome Screen',
                  'Display welcome screen on startup',
                  _showWelcomeScreen,
                  (value) => setState(() => _showWelcomeScreen = value),
                ),
                const Divider(),
                _buildSwitchSetting(
                  'Auto-copy Passwords',
                  'Automatically copy generated passwords to clipboard',
                  _autoCopyPasswords,
                  (value) => setState(() => _autoCopyPasswords = value),
                ),
                const Divider(),
                _buildSwitchSetting(
                  'Show Password Strength',
                  'Display password strength indicator',
                  _showPasswordStrength,
                  (value) => setState(() => _showPasswordStrength = value),
                ),
                const Divider(),
                _buildSwitchSetting(
                  'Enable Quick Actions',
                  'Show quick action buttons in project views',
                  _enableQuickActions,
                  (value) => setState(() => _enableQuickActions = value),
                ),
                const Divider(),
                _buildSliderSetting(
                  'Recent Items Limit',
                  'Maximum number of recently used items to show',
                  _maxRecentItems.toDouble(),
                  3,
                  10,
                  (value) => setState(() => _maxRecentItems = value.toInt()),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Backup & Recovery
            _buildExpandableCard(
              'backup',
              'Backup & Recovery',
              'Configure data backup and recovery options',
              Icons.backup,
              AppConstants.supportIconColor5,
              [
                _buildSwitchSetting(
                  'Enable Backup Phrase',
                  'Generate a recovery phrase for account access',
                  _enableBackupPhrase,
                  (value) => setState(() => _enableBackupPhrase = value),
                ),
                const Divider(),
                _buildSwitchSetting(
                  'Auto Backup',
                  'Automatically backup data to secure storage',
                  _autoBackup,
                  (value) => setState(() => _autoBackup = value),
                ),
                if (_autoBackup) ...[
                  const Divider(),
                  _buildSliderSetting(
                    'Backup Frequency',
                    'How often to create automatic backups (days)',
                    _backupFrequency.toDouble(),
                    1,
                    30,
                    (value) => setState(() => _backupFrequency = value.toInt()),
                  ),
                ],
                const Divider(),
                ListTile(
                  title: const Text('Generate Recovery Code'),
                  subtitle: const Text('Create a one-time recovery code'),
                  leading: Icon(Icons.vpn_key, color: AppConstants.supportIconColor2),
                  onTap: () {
                    // TODO: Implement recovery code generation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Recovery code generation coming soon')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Data Management
            _buildExpandableCard(
              'data',
              'Data Management',
              'Import, export, and manage your data',
              Icons.storage,
              AppConstants.supportIconColor1,
              [
                ListTile(
                  title: const Text('Export Data'),
                  subtitle: const Text('Export all your settings as JSON'),
                  leading: Icon(Icons.download, color: Theme.of(context).colorScheme.secondary),
                  onTap: _exportData,
                ),
                const Divider(),
                ListTile(
                  title: const Text('Import Data'),
                  subtitle: const Text('Import settings from JSON data'),
                  leading: Icon(Icons.upload, color: Theme.of(context).colorScheme.secondary),
                  onTap: _importData,
                ),
                const Divider(),
                ListTile(
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Permanently delete all data'),
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  onTap: _showClearDataDialog,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Save Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save All Settings',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildExpandableCard(String key, String title, String subtitle, IconData icon, Color iconColor, List<Widget> children) {
    final isExpanded = _expandedCard == key;

    return Card(
      elevation: isExpanded ? 4 : 2,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _expandedCard = isExpanded ? null : key;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ],
              ),
            ),
          ),
          // Content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: children,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, Widget control) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          control,
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildSliderSetting(String title, String subtitle, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.secondary,
          inactiveColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildTimeoutSelector() {
    final List<Map<String, int>> timeoutOptions = [
      {'5 minutes': 5},
      {'15 minutes': 15},
      {'30 minutes': 30},
      {'1 hour': 60},
      {'2 hours': 120},
    ];

    return Column(
      children: timeoutOptions.map((option) {
        final label = option.keys.first;
        final value = option.values.first;

        return RadioListTile<int>(
          title: Text(
            label,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          value: value,
          groupValue: _selectedTimeout,
          onChanged: _isLoading
              ? null
              : (value) {
                  setState(() {
                    _selectedTimeout = value!;
                  });
                },
          activeColor: Theme.of(context).colorScheme.secondary,
        );
      }).toList(),
    );
  }
}