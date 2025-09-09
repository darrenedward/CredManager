import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_state.dart';
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
                    backgroundColor: Colors.orange,
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
          style: TextStyle(color: AppConstants.primaryColor),
        ),
        backgroundColor: AppConstants.surfaceColor,
      ),
      body: Container(
        color: AppConstants.backgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Security Settings
            _buildExpandableCard(
              'security',
              'Security Settings',
              'Configure security preferences and authentication',
              Icons.security,
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
              [
                _buildSwitchSetting(
                  'Dark Mode',
                  'Use dark theme for the interface',
                  _darkMode,
                  (value) => setState(() => _darkMode = value),
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
                  leading: Icon(Icons.vpn_key, color: AppConstants.accentColor),
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
              [
                ListTile(
                  title: const Text('Export Data'),
                  subtitle: const Text('Export all your data as JSON'),
                  leading: Icon(Icons.download, color: AppConstants.primaryColor),
                  onTap: () {
                    // TODO: Implement export functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export functionality coming soon')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Import Data'),
                  subtitle: const Text('Import data from JSON file'),
                  leading: Icon(Icons.upload, color: AppConstants.secondaryColor),
                  onTap: () {
                    // TODO: Implement import functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Import functionality coming soon')),
                    );
                  },
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
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
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
        color: AppConstants.primaryColor,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 2,
      color: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildExpandableCard(String key, String title, String subtitle, IconData icon, List<Widget> children) {
    final isExpanded = _expandedCard == key;

    return Card(
      elevation: isExpanded ? 4 : 2,
      color: AppConstants.surfaceColor,
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
                    color: AppConstants.primaryColor,
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
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppConstants.primaryColor,
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
              color: AppConstants.primaryColor,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
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
          color: AppConstants.primaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppConstants.secondaryColor,
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
                color: AppConstants.primaryColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
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
              color: Colors.grey[600],
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
          activeColor: AppConstants.secondaryColor,
          inactiveColor: AppConstants.secondaryColor.withOpacity(0.3),
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
            style: TextStyle(color: AppConstants.primaryColor),
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
          activeColor: AppConstants.secondaryColor,
        );
      }).toList(),
    );
  }
}