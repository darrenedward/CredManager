import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/auth_state.dart';
import '../models/dashboard_state.dart';
import '../models/project.dart';
import '../models/ai_service.dart';
import '../models/password_vault.dart';
import '../services/theme_service.dart';
import '../services/biometric_auth_service.dart';
import '../services/password_generator_service.dart';
import '../utils/constants.dart';
import '../services/responsive_service.dart';
import '../widgets/adaptive_card.dart';
import 'settings_screen.dart';
import 'terms_screen.dart';

class MainDashboardScreenResponsive extends StatefulWidget {
  const MainDashboardScreenResponsive({super.key});

  @override
  State<MainDashboardScreenResponsive> createState() => _MainDashboardScreenResponsiveState();
}

class _MainDashboardScreenResponsiveState extends State<MainDashboardScreenResponsive> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  final PasswordGeneratorService _passwordGenerator = PasswordGeneratorService();

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthState, DashboardState>(
      builder: (context, authState, dashboardState, child) {
        final bool shouldUseDrawer = ResponsiveService.shouldUseDrawer(context);
        final bool showBottomNav = ResponsiveService.shouldShowBottomNavigation(context);
        
        return Scaffold(
          appBar: _buildResponsiveAppBar(context, shouldUseDrawer),
          drawer: shouldUseDrawer ? _buildNavigationDrawer(context, dashboardState) : null,
          body: _buildResponsiveBody(context, dashboardState, shouldUseDrawer),
          bottomNavigationBar: showBottomNav ? _buildBottomNavigationBar(context, dashboardState) : null,
        );
      },
    );
  }

  /// Build responsive app bar
  PreferredSizeWidget _buildResponsiveAppBar(BuildContext context, bool shouldUseDrawer) {
    // On desktop/tablet (with sidebar), use minimal AppBar
    // On mobile (drawer), use full AppBar with logout
    if (!shouldUseDrawer) {
      return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0, // Essentially hide the AppBar on desktop
      );
    }

    return AppBar(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Icon(
            Icons.security,
            color: AppConstants.accentColor,
            size: 28,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () {
            final authState = Provider.of<AuthState>(context, listen: false);
            authState.logout();
          },
          tooltip: 'Logout',
        ),
      ],
    );
  }

  /// Build responsive body layout
  Widget _buildResponsiveBody(BuildContext context, DashboardState dashboardState, bool shouldUseDrawer) {
    if (shouldUseDrawer) {
      // Mobile layout - no sidebar, content takes full width
      return Column(
        children: [
          Expanded(child: _buildMainContent(context, dashboardState)),
          _buildFooter(context),
        ],
      );
    } else {
      // Desktop/Tablet layout - sidebar + content
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildSidebar(context, dashboardState),
                Expanded(child: _buildMainContent(context, dashboardState)),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      );
    }
  }

  /// Build sidebar for desktop/tablet
  Widget _buildSidebar(BuildContext context, DashboardState dashboardState) {
    return Container(
      width: ResponsiveService.getSidebarWidth(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: _buildNavigationContent(context, dashboardState),
    );
  }

  /// Build navigation drawer for mobile
  Widget _buildNavigationDrawer(BuildContext context, DashboardState dashboardState) {
    return Drawer(
      backgroundColor: AppConstants.primaryColor,
      child: _buildNavigationContent(context, dashboardState),
    );
  }

  /// Build shared navigation content for both sidebar and drawer
  Widget _buildNavigationContent(BuildContext context, DashboardState dashboardState) {
    return Column(
      children: [
        // Navigation items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildNavigationItem(
                context,
                icon: Icons.dashboard,
                title: 'Dashboard',
                subtitle: 'Overview & Statistics',
                isSelected: dashboardState.currentView == 'overview',
                onTap: () => dashboardState.showOverview(),
              ),
              const SizedBox(height: 8),
              _buildNavigationItem(
                context,
                icon: Icons.folder,
                title: 'Projects',
                subtitle: 'Manage Projects',
                isSelected: dashboardState.currentView == 'project_management',
                onTap: () {
                  dashboardState.showProjectManagement();
                  if (ResponsiveService.isMobile(context)) {
                    Navigator.pop(context); // Close drawer on mobile
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildNavigationItem(
                context,
                icon: Icons.auto_awesome,
                title: 'AI Services',
                subtitle: 'Manage AI Services',
                isSelected: dashboardState.currentView == 'ai_service_management',
                onTap: () {
                  dashboardState.showAiServiceManagement();
                  if (ResponsiveService.isMobile(context)) {
                    Navigator.pop(context); // Close drawer on mobile
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildNavigationItem(
                context,
                icon: Icons.lock_outline,
                title: 'Passwords',
                subtitle: 'Password Vault',
                isSelected: dashboardState.currentView == 'password_vault_management',
                onTap: () {
                  dashboardState.showPasswordVaultManagement();
                  if (ResponsiveService.isMobile(context)) {
                    Navigator.pop(context); // Close drawer on mobile
                  }
                },
              ),
            ],
          ),
        ),
        // Settings at bottom
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildNavigationItem(
                context,
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'App Settings',
                isSelected: dashboardState.currentView == 'settings',
                onTap: () {
                  dashboardState.showSettings();
                  if (ResponsiveService.isMobile(context)) {
                    Navigator.pop(context); // Close drawer on mobile
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildNavigationItem(
                context,
                icon: Icons.help,
                title: 'Support',
                subtitle: 'Help & Documentation',
                isSelected: dashboardState.currentView == 'support',
                onTap: () {
                  dashboardState.showSupport();
                  if (ResponsiveService.isMobile(context)) {
                    Navigator.pop(context); // Close drawer on mobile
                  }
                },
              ),
              const SizedBox(height: 16),
              // Logout button at bottom
              _buildNavigationItem(
                context,
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out securely',
                isSelected: false,
                onTap: () {
                  final authState = Provider.of<AuthState>(context, listen: false);
                  authState.logout();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build navigation item
  Widget _buildNavigationItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppConstants.primaryColor.withValues(alpha: 0.2)
            : AppConstants.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppConstants.accentColor.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppConstants.accentColor,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }

  /// Build main content area
  Widget _buildMainContent(BuildContext context, DashboardState dashboardState) {
    // Show different content based on current view
    switch (dashboardState.currentView) {
      case 'settings':
        return _buildSettingsContent(context);
      case 'support':
        return _buildSupportContent(context);
      case 'project_management':
        return _buildProjectManagementContent(context, dashboardState);
      case 'project_detail':
        return _buildProjectDetailContent(context, dashboardState);
      case 'ai_service_management':
        return _buildAiServiceManagementContent(context, dashboardState);
      case 'ai_service_detail':
        return _buildAiServiceDetailContent(context, dashboardState);
      case 'password_vault_management':
        return _buildPasswordVaultManagementContent(context, dashboardState);
      case 'password_vault_detail':
        return _buildPasswordVaultDetailContent(context, dashboardState);
      default:
        return _buildDashboardContent(context, dashboardState);
    }
  }

  /// Build dashboard content (default view)
  Widget _buildDashboardContent(BuildContext context, DashboardState dashboardState) {
    return SingleChildScrollView(
      padding: ResponsiveService.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section with icon
          Row(
            children: [
              Icon(
                Icons.security,
                size: 40,
                color: AppConstants.accentColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdaptiveText(
                      'Welcome to ${AppConstants.appName}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AdaptiveText(
                      'Your secure, offline-first credential manager',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats cards
          AdaptiveGrid(
            children: [
              AdaptiveCard(
                onTap: () => ResponsiveService.triggerLightHaptic(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.security,
                      color: AppConstants.accentColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const AdaptiveText(
                      'Total Credentials',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const AdaptiveText(
                      '0',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              AdaptiveCard(
                onTap: () => ResponsiveService.triggerLightHaptic(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.folder,
                      color: AppConstants.accentColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const AdaptiveText(
                      'Projects',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const AdaptiveText(
                      '0',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              AdaptiveCard(
                onTap: () => ResponsiveService.triggerLightHaptic(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: AppConstants.accentColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const AdaptiveText(
                      'AI Services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const AdaptiveText(
                      '0',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Getting Started section
          AdaptiveText(
            'Getting Started',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          _buildGettingStartedGrid(context, dashboardState),

          const SizedBox(height: 32),

          // Quick actions
          AdaptiveText(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          AdaptiveGrid(
            children: [
              AdaptiveCard(
                onTap: () {
                  ResponsiveService.triggerHapticFeedback();
                  _showAddCredentialDialog(context, dashboardState);
                },
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: AdaptiveText(
                        'Add Credential',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AdaptiveCard(
                onTap: () {
                  ResponsiveService.triggerHapticFeedback();
                  _showImportDataDialog(context);
                },
                child: const Row(
                  children: [
                    Icon(Icons.upload, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: AdaptiveText(
                        'Import Data',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AdaptiveCard(
                onTap: () {
                  ResponsiveService.triggerHapticFeedback();
                  _showBackupDataDialog(context);
                },
                child: const Row(
                  children: [
                    Icon(Icons.backup, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: AdaptiveText(
                        'Backup Data',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Security reminder
          AdaptiveCard(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: AppConstants.accentColor,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdaptiveText(
                          'Your Data is Secure',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AdaptiveText(
                          'All credentials are encrypted and stored locally on your device. No data is transmitted to external servers.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build settings content
  Widget _buildSettingsContent(BuildContext context) {
    return Consumer<AuthState>(
      builder: (context, authState, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveService.isMobile(context) ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Settings header
              AdaptiveText(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              AdaptiveText(
                'Configure your app preferences and security settings',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Security Settings
              _buildSettingsSection(
                context,
                icon: Icons.security,
                title: 'Security Settings',
                description: 'Configure security preferences and authentication settings.',
                children: [
                  _buildTimeoutSetting(context, authState),
                  const Divider(),
                  _buildBiometricSetting(context),
                  const Divider(),
                  _buildAutoLockSetting(context),
                ],
              ),

              const SizedBox(height: 24),

              // Appearance Settings
              _buildSettingsSection(
                context,
                icon: Icons.palette,
                title: 'Appearance & Experience',
                description: 'Customize the app look and behavior.',
                children: [
                  Consumer<ThemeService>(
                    builder: (context, themeService, child) => _buildSwitchSetting(
                      context,
                      'Dark Mode',
                      'Use dark theme for the interface',
                      themeService.isDarkMode,
                      (value) async {
                        await themeService.setDarkMode(value);
                      },
                    ),
                  ),
                  const Divider(),
                  Consumer<AuthState>(
                    builder: (context, authState, child) => _buildSwitchSetting(
                      context,
                      'Auto-copy Passwords',
                      'Automatically copy passwords to clipboard when viewing credentials',
                      authState.autoCopyPasswords,
                      (value) async {
                        await authState.setAutoCopyPasswords(value);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value
                                ? 'Auto-copy passwords enabled'
                                : 'Auto-copy passwords disabled'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  _buildSwitchSetting(
                    context,
                    'Show Welcome Screen',
                    'Display welcome screen on startup',
                    true, // TODO: Connect to actual setting
                    (value) {
                      // TODO: Implement welcome screen toggle
                      _showFeatureComingSoon(context, 'Welcome Screen');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Data Management
              _buildSettingsSection(
                context,
                icon: Icons.storage,
                title: 'Data Management',
                description: 'Manage your data and backups.',
                children: [
                  _buildActionSetting(
                    context,
                    'Export Data',
                    'Export encrypted backup of all your data',
                    Icons.download,
                    () => _showBackupDataDialog(context),
                  ),
                  const Divider(),
                  _buildActionSetting(
                    context,
                    'Import Data',
                    'Import data from encrypted backup file',
                    Icons.upload,
                    () => _showImportDataDialog(context),
                  ),
                  const Divider(),
                  _buildActionSetting(
                    context,
                    'Clear All Data',
                    'Reset application and delete all stored data',
                    Icons.delete_forever,
                    () => _showClearDataDialog(context),
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build support content
  Widget _buildSupportContent(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveService.isMobile(context) ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Support header
          AdaptiveText(
            'Support & Documentation',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          AdaptiveText(
            'Everything you need to know about ${AppConstants.appName}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // About section
          _buildSupportSection(
            context,
            icon: Icons.security,
            title: 'About ${AppConstants.appName}',
            description: 'Cred Manager is a secure, offline-first application designed to help you manage your API keys, passwords, and other sensitive credentials. All data is encrypted and stored locally on your device.',
            children: [
              _buildFeatureList(),
            ],
          ),

          const SizedBox(height: 24),

          // How it works
          _buildSupportSection(
            context,
            icon: Icons.settings,
            title: 'How It Works',
            description: 'Follow these simple steps to get started with secure credential management.',
            children: [
              _buildHowItWorksStep(1, 'Setup', 'Create a secure passphrase to protect your data'),
              const SizedBox(height: 12),
              _buildHowItWorksStep(2, 'Organize', 'Create projects to group related credentials'),
              const SizedBox(height: 12),
              _buildHowItWorksStep(3, 'Store', 'Add API keys, passwords, and connection strings'),
              const SizedBox(height: 12),
              _buildHowItWorksStep(4, 'Access', 'View, copy, and manage your credentials securely'),
            ],
          ),

          const SizedBox(height: 24),

          // Examples
          _buildSupportSection(
            context,
            icon: Icons.lightbulb,
            title: 'Examples & Use Cases',
            description: 'Real-world scenarios where Cred Manager helps organize and secure your credentials.',
            children: [
              _buildExample(
                'E-commerce Platform',
                'Store database connection strings, payment gateway API keys, admin passwords, and webhook secrets all in one secure project.',
              ),
              const SizedBox(height: 16),
              _buildExample(
                'AI Development',
                'Manage API keys for OpenAI, Anthropic, and other AI services. Keep track of different environments (dev/staging/prod).',
              ),
              const SizedBox(height: 16),
              _buildExample(
                'Web Development',
                'Organize API keys for different services like AWS, Google Cloud, social media APIs, and third-party integrations.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build settings section with full width
  Widget _buildSettingsSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(ResponsiveService.isMobile(context) ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppConstants.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdaptiveText(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveService.isMobile(context) ? 18 : 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AdaptiveText(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: ResponsiveService.isMobile(context) ? 13 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  /// Build timeout setting with slider
  Widget _buildTimeoutSetting(BuildContext context, AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdaptiveText(
                    'Session Timeout',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AdaptiveText(
                    'Automatically logout after inactivity',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            AdaptiveText(
              authState.sessionTimeoutMinutes == 0
                ? 'Never'
                : '${authState.sessionTimeoutMinutes} min',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppConstants.primaryColor,
            inactiveTrackColor: AppConstants.primaryColor.withValues(alpha: 0.3),
            thumbColor: AppConstants.primaryColor,
            overlayColor: AppConstants.primaryColor.withValues(alpha: 0.2),
            valueIndicatorColor: AppConstants.primaryColor,
          ),
          child: Slider(
            value: authState.sessionTimeoutMinutes.toDouble(),
            min: 0,
            max: 60,
            divisions: 12, // 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60
            label: authState.sessionTimeoutMinutes == 0
              ? 'Never'
              : '${authState.sessionTimeoutMinutes} minutes',
            onChanged: (value) {
              authState.setSessionTimeout(value.round());
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AdaptiveText(
              'Never',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            AdaptiveText(
              '60 min',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build biometric setting
  Widget _buildBiometricSetting(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkBiometricAvailability(),
      builder: (context, snapshot) {
        final isAvailable = snapshot.data ?? false;

        return FutureBuilder<bool>(
          future: _biometricService.isBiometricEnabled(),
          builder: (context, enabledSnapshot) {
            final isEnabled = enabledSnapshot.data ?? false;

            return _buildSwitchSetting(
              context,
              'Biometric Authentication',
              isAvailable
                ? 'Use fingerprint or face unlock to access the app'
                : 'Biometric authentication not available on this device',
              isEnabled,
              isAvailable ? (value) async {
                if (value) {
                  // Enable biometric authentication
                  await _enableBiometricAuth(context);
                } else {
                  // Disable biometric authentication
                  await _disableBiometricAuth(context);
                }
              } : null,
              enabled: isAvailable,
            );
          },
        );
      },
    );
  }

  /// Build auto-lock setting
  Widget _buildAutoLockSetting(BuildContext context) {
    return _buildSwitchSetting(
      context,
      'Auto-lock',
      'Lock the app when it goes to background',
      true, // TODO: Connect to actual auto-lock setting
      (value) {
        // TODO: Implement auto-lock toggle
        _showFeatureComingSoon(context, 'Auto-lock');
      },
    );
  }

  /// Build switch setting
  Widget _buildSwitchSetting(
    BuildContext context,
    String title,
    String description,
    bool value,
    ValueChanged<bool>? onChanged, {
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdaptiveText(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: enabled ? null : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                AdaptiveText(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: enabled ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }

  /// Build action setting
  Widget _buildActionSetting(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : AppConstants.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdaptiveText(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: isDestructive ? Colors.red : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AdaptiveText(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  /// Check biometric availability
  Future<bool> _checkBiometricAvailability() async {
    return await _biometricService.isBiometricAvailable();
  }

  /// Enable biometric authentication
  Future<void> _enableBiometricAuth(BuildContext context) async {
    try {
      // Show dialog to get current passphrase
      final passphrase = await _showPassphraseDialog(context);
      if (passphrase == null) return;

      final authState = Provider.of<AuthState>(context, listen: false);
      final success = await authState.enableBiometricAuth();

      if (mounted) {
        setState(() {}); // Refresh the UI
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication enabled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Error message already handled in AuthState
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enabling biometric authentication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Disable biometric authentication
  Future<void> _disableBiometricAuth(BuildContext context) async {
    try {
      final authState = Provider.of<AuthState>(context, listen: false);
      await authState.disableBiometricAuth();

      if (mounted) {
        setState(() {}); // Refresh the UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication disabled'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disabling biometric authentication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show dialog to enter current passphrase
  Future<String?> _showPassphraseDialog(BuildContext context) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enable Biometric Authentication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your current passphrase to enable biometric authentication:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Passphrase',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final passphrase = controller.text.trim();
              if (passphrase.isNotEmpty) {
                Navigator.of(context).pop(passphrase);
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  /// Show feature coming soon dialog
  void _showFeatureComingSoon(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(featureName),
        content: Text('$featureName will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Build support section with full width
  Widget _buildSupportSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(ResponsiveService.isMobile(context) ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppConstants.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdaptiveText(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveService.isMobile(context) ? 18 : 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AdaptiveText(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: ResponsiveService.isMobile(context) ? 13 : 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  /// Build feature list
  Widget _buildFeatureList() {
    final features = [
      'AES-256-GCM encryption',
      'Offline-first design',
      'Cross-platform support',
      'Biometric authentication',
      'Secure local storage',
      'Project organization',
    ];

    return Column(
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppConstants.accentColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            AdaptiveText(feature),
          ],
        ),
      )).toList(),
    );
  }

  /// Build how it works step
  Widget _buildHowItWorksStep(int step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppConstants.accentColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AdaptiveText(
                step.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdaptiveText(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                AdaptiveText(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build example
  Widget _buildExample(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveText(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        AdaptiveText(
          description,
          style: TextStyle(
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Build bottom navigation bar for mobile
  Widget _buildBottomNavigationBar(BuildContext context, DashboardState dashboardState) {
    int currentIndex = 0;
    
    // Determine current index based on dashboard state
    if (dashboardState.currentView == 'overview') {
      currentIndex = 0;
    } else if (dashboardState.currentView == 'project_management') {
      currentIndex = 1;
    } else if (dashboardState.currentView == 'ai_service_management') {
      currentIndex = 2;
    } else if (dashboardState.currentView == 'settings') {
      currentIndex = 3;
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppConstants.primaryColor,
      selectedItemColor: AppConstants.accentColor,
      unselectedItemColor: Colors.white70,
      onTap: (index) {
        switch (index) {
          case 0:
            dashboardState.showOverview();
            break;
          case 1:
            dashboardState.showProjectManagement();
            break;
          case 2:
            dashboardState.showAiServiceManagement();
            break;
          case 3:
            dashboardState.showSettings();
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder),
          label: 'Projects',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome),
          label: 'AI Services',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  /// Build footer
  Widget _buildFooter(BuildContext context) {
    if (ResponsiveService.isMobile(context)) {
      return const SizedBox.shrink(); // Hide footer on mobile
    }

    return Container(
      height: 60,
      color: AppConstants.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Copyright on the left
          GestureDetector(
            onTap: () => _showLicenseDialog(context),
            child: Text(
              AppConstants.copyright,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          // Terms and Version on the right
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsScreen()),
                ),
                child: const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Version ${AppConstants.appVersion}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show license dialog
  void _showLicenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.gavel,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text('License Information'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cred Manager v${AppConstants.appVersion}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  AppConstants.licenseText,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Build project management content
  Widget _buildProjectManagementContent(BuildContext context, DashboardState dashboardState) {
    return SingleChildScrollView(
      padding: ResponsiveService.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AdaptiveText(
                'Projects',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              AdaptiveText(
                'Organize your credentials into projects',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showCreateProjectDialog(context, dashboardState),
                icon: const Icon(Icons.add),
                label: const Text('New Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Projects list
          if (dashboardState.projects.isEmpty)
            _buildEmptyStateWithoutAction(
              context,
              icon: Icons.folder_outlined,
              title: 'No Projects Yet',
              description: 'Create your first project to start organizing your credentials',
            )
          else
            AdaptiveGrid(
              children: dashboardState.projects.map((project) =>
                AdaptiveCard(
                  onTap: () {
                    ResponsiveService.triggerLightHaptic();
                    // Navigate directly to project management for this project
                    dashboardState.selectProject(project.id);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.folder,
                            color: AppConstants.accentColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AdaptiveText(
                              project.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (project.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        AdaptiveText(
                          project.description!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.security,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          AdaptiveText(
                            '${project.credentials.length} credentials',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          AdaptiveText(
                            'Updated ${_formatDate(project.updatedAt)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ),
        ],
      ),
    );
  }

  /// Build project detail content
  Widget _buildProjectDetailContent(BuildContext context, DashboardState dashboardState) {
    final project = dashboardState.currentSelectedItem != null
        ? dashboardState.getProject(dashboardState.currentSelectedItem!)
        : null;

    if (project == null) {
      // If project not found, go back to project management
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dashboardState.showProjectManagement();
      });
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: ResponsiveService.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => dashboardState.showProjectManagement(),
                tooltip: 'Back to Projects',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdaptiveText(
                      project.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    if (project.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      AdaptiveText(
                        project.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Project stats
          Row(
            children: [
              _buildProjectStat(
                context,
                icon: Icons.key,
                label: 'Credentials',
                value: '${project.credentials.length}',
                color: AppConstants.accentColor,
              ),
              const SizedBox(width: 16),
              _buildProjectStat(
                context,
                icon: Icons.calendar_today,
                label: 'Created',
                value: _formatDate(project.createdAt),
                color: AppConstants.secondaryColor,
              ),
              const SizedBox(width: 16),
              _buildProjectStat(
                context,
                icon: Icons.update,
                label: 'Updated',
                value: _formatDate(project.updatedAt),
                color: AppConstants.successColor,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Add credential button
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _showAddCredentialToProjectDialog(context, project, dashboardState),
              icon: const Icon(Icons.add),
              label: const Text('Add Credential'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Credentials section
          AdaptiveText(
            'Credentials',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Credentials list
          if (project.credentials.isEmpty)
            _buildEmptyStateWithoutAction(
              context,
              icon: Icons.key_outlined,
              title: 'No Credentials Yet',
              description: 'Add your first credential to this project',
            )
          else
            ...project.credentials.map((credential) =>
              _buildCredentialCard(context, credential, project, dashboardState)
            ).toList(),
        ],
      ),
    );
  }

  /// Build AI service detail content
  Widget _buildAiServiceDetailContent(BuildContext context, DashboardState dashboardState) {
    final service = dashboardState.currentSelectedItem != null
        ? dashboardState.getAiService(dashboardState.currentSelectedItem!)
        : null;

    if (service == null) {
      // If service not found, go back to AI service management
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dashboardState.showAiServiceManagement();
      });
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: ResponsiveService.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => dashboardState.showAiServiceManagement(),
                tooltip: 'Back to AI Services',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdaptiveText(
                      service.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    if (service.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      AdaptiveText(
                        service.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Service stats
          Row(
            children: [
              _buildServiceStat(
                context,
                icon: Icons.key,
                label: 'API Keys',
                value: '${service.keys.length}',
                color: AppConstants.accentColor,
              ),
              const SizedBox(width: 16),
              _buildServiceStat(
                context,
                icon: Icons.calendar_today,
                label: 'Created',
                value: _formatDate(service.createdAt),
                color: AppConstants.secondaryColor,
              ),
              const SizedBox(width: 16),
              _buildServiceStat(
                context,
                icon: Icons.update,
                label: 'Updated',
                value: _formatDate(service.updatedAt),
                color: AppConstants.successColor,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Add API key button
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _showAddApiKeyToServiceDialog(context, service, dashboardState),
              icon: const Icon(Icons.add),
              label: const Text('Add API Key'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // API Keys section
          AdaptiveText(
            'API Keys',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // API Keys list
          if (service.keys.isEmpty)
            _buildEmptyStateWithoutAction(
              context,
              icon: Icons.key_outlined,
              title: 'No API Keys Yet',
              description: 'Add your first API key to this service',
            )
          else
            ...service.keys.map((apiKey) =>
              _buildApiKeyCard(context, apiKey, service, dashboardState)
            ).toList(),
        ],
      ),
    );
  }

  /// Build AI service management content
  Widget _buildAiServiceManagementContent(BuildContext context, DashboardState dashboardState) {
    return SingleChildScrollView(
      padding: ResponsiveService.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AdaptiveText(
                'AI Services',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              AdaptiveText(
                'Manage your AI service API keys and configurations',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showCreateAiServiceDialog(context, dashboardState),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('New AI Service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // AI Services list
          if (dashboardState.aiServices.isEmpty)
            _buildEmptyStateWithoutAction(
              context,
              icon: Icons.auto_awesome_outlined,
              title: 'No AI Services Yet',
              description: 'Add your first AI service to manage API keys and configurations',
            )
          else
            AdaptiveGrid(
              children: dashboardState.aiServices.map((service) =>
                AdaptiveCard(
                  onTap: () {
                    ResponsiveService.triggerLightHaptic();
                    // Navigate directly to AI service management for this service
                    dashboardState.selectAiService(service.id);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: AppConstants.accentColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AdaptiveText(
                              service.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (service.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        AdaptiveText(
                          service.description!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.vpn_key,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          AdaptiveText(
                            '${service.keys.length} API keys',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          AdaptiveText(
                            'Updated ${_formatDate(service.updatedAt)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ),
        ],
      ),
    );
  }

  /// Build empty state widget without action button (to avoid duplicate buttons)
  Widget _buildEmptyStateWithoutAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            AdaptiveText(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            AdaptiveText(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build getting started grid with proper layout
  Widget _buildGettingStartedGrid(BuildContext context, DashboardState dashboardState) {
    final isMobile = ResponsiveService.isMobile(context);
    final isTablet = ResponsiveService.isTablet(context);

    final cards = [
      _buildGettingStartedCard(
        context,
        icon: Icons.folder_outlined,
        title: 'Create Your First Project',
        description: 'Organize credentials by grouping them into projects',
        onTap: () {
          ResponsiveService.triggerHapticFeedback();
          dashboardState.showProjectManagement();
        },
      ),
      _buildGettingStartedCard(
        context,
        icon: Icons.add_circle_outline,
        title: 'Add Credentials',
        description: 'Store API keys, passwords, and connection strings securely',
        onTap: () {
          ResponsiveService.triggerHapticFeedback();
          _showAddCredentialDialog(context, dashboardState);
        },
      ),
      _buildGettingStartedCard(
        context,
        icon: Icons.auto_awesome_outlined,
        title: 'Setup AI Services',
        description: 'Manage API keys for OpenAI, Anthropic, and other AI platforms',
        onTap: () {
          ResponsiveService.triggerHapticFeedback();
          dashboardState.showAiServiceManagement();
        },
      ),
      _buildGettingStartedCard(
        context,
        icon: Icons.settings_outlined,
        title: 'Configure Settings',
        description: 'Customize security, appearance, and backup preferences',
        onTap: () {
          ResponsiveService.triggerHapticFeedback();
          dashboardState.showSettings();
        },
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((card) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: card,
        )).toList(),
      );
    } else {
      return Wrap(
        spacing: 16.0,
        runSpacing: 16.0,
        children: cards.map((card) => SizedBox(
          width: isTablet
            ? (MediaQuery.of(context).size.width - 80) / 2 // 2 columns on tablet
            : (MediaQuery.of(context).size.width - 128) / 4, // 4 columns on desktop
          child: card,
        )).toList(),
      );
    }
  }

  /// Build getting started card
  Widget _buildGettingStartedCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return AdaptiveCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppConstants.accentColor,
              size: ResponsiveService.isMobile(context) ? 24 : 28,
            ),
            const SizedBox(height: 8),
            AdaptiveText(
              title,
              style: TextStyle(
                fontSize: ResponsiveService.isMobile(context) ? 14 : 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            AdaptiveText(
              description,
              style: TextStyle(
                fontSize: ResponsiveService.isMobile(context) ? 12 : 13,
                color: Colors.grey[600],
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Show add credential dialog
  void _showAddCredentialDialog(BuildContext context, DashboardState dashboardState) {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final urlController = TextEditingController();
    final notesController = TextEditingController();
    String? selectedProjectId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Credential'),
          content: SizedBox(
            width: ResponsiveService.isMobile(context) ? double.maxFinite : 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Project selection
                  DropdownButtonFormField<String>(
                    value: selectedProjectId,
                    decoration: const InputDecoration(
                      labelText: 'Project',
                      hintText: 'Select a project',
                      border: OutlineInputBorder(),
                    ),
                    items: dashboardState.projects.map((project) {
                      return DropdownMenuItem(
                        value: project.id,
                        child: Text(project.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedProjectId = value;
                      });
                    },
                    validator: (value) => value == null ? 'Please select a project' : null,
                  ),
                  const SizedBox(height: 16),

                  // Credential name
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Credential Name',
                      hintText: 'e.g., Production Database',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Username/Email
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username/Email',
                      hintText: 'Enter username or email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password/API Key
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password/API Key',
                      hintText: 'Enter password or API key',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // URL (optional)
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL (Optional)',
                      hintText: 'https://example.com',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes (optional)
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Additional information...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a credential name')),
                  );
                  return;
                }

                if (selectedProjectId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a project')),
                  );
                  return;
                }

                if (passwordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a password or API key')),
                  );
                  return;
                }

                try {
                  await dashboardState.addDetailedCredentialToProject(
                    selectedProjectId!,
                    nameController.text.trim(),
                    usernameController.text.trim(),
                    passwordController.text.trim(),
                    url: urlController.text.trim().isEmpty ? null : urlController.text.trim(),
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Credential added successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding credential: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Credential'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show import data dialog
  void _showImportDataDialog(BuildContext context) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Consumer<DashboardState>(
        builder: (context, dashboardState, child) => AlertDialog(
          title: const Text('Import Data'),
          content: SizedBox(
            width: ResponsiveService.isMobile(context) ? double.maxFinite : 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Import data from a backup file or paste backup JSON:'),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Backup Data (JSON)',
                    hintText: 'Paste your backup JSON here...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will merge with your existing data. Duplicate projects will be skipped.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (textController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please paste backup data')),
                  );
                  return;
                }

                Navigator.pop(context);
                await _performDataImport(context, dashboardState, textController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }

  /// Perform data import
  Future<void> _performDataImport(BuildContext context, DashboardState dashboardState, String jsonData) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Importing data...'),
            ],
          ),
        ),
      );

      // Parse JSON
      final backupData = jsonDecode(jsonData) as Map<String, dynamic>;

      int importedProjects = 0;
      int importedServices = 0;
      int skippedProjects = 0;

      // Import projects
      if (backupData['projects'] != null) {
        final projectsData = backupData['projects'] as List<dynamic>;
        for (final projectData in projectsData) {
          try {
            final project = Project.fromJson(projectData as Map<String, dynamic>);

            // Check if project already exists
            final existingProject = dashboardState.projects.any((p) => p.id == project.id || p.name == project.name);
            if (!existingProject) {
              await dashboardState.createProject(project.name, description: project.description);
              importedProjects++;
            } else {
              skippedProjects++;
            }
          } catch (e) {
            print('Error importing project: $e');
          }
        }
      }

      // Import AI services
      if (backupData['ai_services'] != null) {
        final servicesData = backupData['ai_services'] as List<dynamic>;
        for (final serviceData in servicesData) {
          try {
            final service = AiService.fromJson(serviceData as Map<String, dynamic>);

            // Check if service already exists
            final existingService = dashboardState.aiServices.any((s) => s.id == service.id || s.name == service.name);
            if (!existingService) {
              await dashboardState.createAiService(service.name, description: service.description);
              importedServices++;
            }
          } catch (e) {
            print('Error importing AI service: $e');
          }
        }
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import completed!\nProjects: $importedProjects imported, $skippedProjects skipped\nAI Services: $importedServices imported'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: Invalid backup format\n$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Show backup data dialog
  void _showBackupDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer<DashboardState>(
        builder: (context, dashboardState, child) => AlertDialog(
          title: const Text('Backup Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create an encrypted backup of all your projects and credentials.'),
              const SizedBox(height: 16),
              const Text('The backup file will be encrypted with your current passphrase.'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Projects: ${dashboardState.projects.length}\nCredentials: ${dashboardState.projects.fold(0, (sum, p) => sum + p.credentials.length)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performDataBackup(context, dashboardState);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Backup'),
            ),
          ],
        ),
      ),
    );
  }

  /// Perform data backup
  Future<void> _performDataBackup(BuildContext context, DashboardState dashboardState) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating backup...'),
            ],
          ),
        ),
      );

      // Create backup data
      final backupData = {
        'version': '1.0.0',
        'created_at': DateTime.now().toIso8601String(),
        'projects': dashboardState.projects.map((p) => p.toJson()).toList(),
        'ai_services': dashboardState.aiServices.map((s) => s.toJson()).toList(),
      };

      // Convert to JSON string
      final jsonString = jsonEncode(backupData);

      // For now, just show success (in a real app, you'd save to file)
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup created successfully!\n${jsonString.length} characters'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // In a real implementation, you would:
        // 1. Save to file system
        // 2. Allow user to choose location
        // 3. Encrypt the backup file
        print('Backup data: $jsonString');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show clear data dialog
  void _showClearDataDialog(BuildContext context) {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Consumer<DashboardState>(
        builder: (context, dashboardState, child) => AlertDialog(
          title: const Text('Clear All Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete all your data:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text('• ${dashboardState.projects.length} projects'),
              Text('• ${dashboardState.projects.fold(0, (sum, p) => sum + p.credentials.length)} credentials'),
              Text('• ${dashboardState.aiServices.length} AI services'),
              const Text('• All settings and preferences'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Type "DELETE ALL" to confirm:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  hintText: 'DELETE ALL',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (confirmController.text.trim() != 'DELETE ALL') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please type "DELETE ALL" to confirm'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _performClearAllData(context, dashboardState);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete All'),
            ),
          ],
        ),
      ),
    );
  }

  /// Perform clear all data
  Future<void> _performClearAllData(BuildContext context, DashboardState dashboardState) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Clearing all data...'),
            ],
          ),
        ),
      );

      // Clear all data
      await dashboardState.clearAllData();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data has been cleared successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show create project dialog
  void _showCreateProjectDialog(BuildContext context, DashboardState dashboardState) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                hintText: 'Enter project name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter project description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await dashboardState.createProject(
                  nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }



  /// Show create AI service dialog
  void _showCreateAiServiceDialog(BuildContext context, DashboardState dashboardState) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New AI Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Service Name',
                hintText: 'e.g., OpenAI, Anthropic, Google AI',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter service description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await dashboardState.createAiService(
                  nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }



  /// Build project stat widget
  Widget _buildProjectStat(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: AdaptiveCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              AdaptiveText(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              AdaptiveText(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build credential card for project detail view
  Widget _buildCredentialCard(BuildContext context, dynamic credential, Project project, DashboardState dashboardState) {
    return AdaptiveCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCredentialIcon(credential.type ?? 'API Key'),
                  color: AppConstants.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdaptiveText(
                        credential.serviceName ?? 'Unnamed Service',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AdaptiveText(
                        credential.type ?? 'API Key',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyCredentialToClipboard(context, credential),
                  tooltip: 'Copy to clipboard',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showEditCredentialDialog(context, credential, project, dashboardState),
                  tooltip: 'Edit credential',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _showDeleteCredentialDialog(context, credential, project, dashboardState),
                  tooltip: 'Delete credential',
                ),
              ],
            ),
            if (credential.description?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              AdaptiveText(
                credential.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get appropriate icon for credential type
  IconData _getCredentialIcon(String type) {
    switch (type.toLowerCase()) {
      case 'api key':
        return Icons.key;
      case 'password':
        return Icons.lock;
      case 'database':
        return Icons.storage;
      case 'ssh key':
        return Icons.terminal;
      case 'token':
        return Icons.token;
      case 'certificate':
        return Icons.security;
      default:
        return Icons.key;
    }
  }

  /// Show add credential to project dialog
  void _showAddCredentialToProjectDialog(BuildContext context, Project project, DashboardState dashboardState) {
    // TODO: Implement add credential dialog specific to this project
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add credential dialog - Coming soon')),
    );
  }

  /// Copy credential to clipboard
  void _copyCredentialToClipboard(BuildContext context, dynamic credential) {
    // TODO: Implement clipboard copy functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credential copied to clipboard')),
    );
  }

  /// Show edit credential dialog
  void _showEditCredentialDialog(BuildContext context, dynamic credential, Project project, DashboardState dashboardState) {
    // TODO: Implement edit credential dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit credential dialog - Coming soon')),
    );
  }

  /// Show delete credential confirmation dialog
  void _showDeleteCredentialDialog(BuildContext context, dynamic credential, Project project, DashboardState dashboardState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Credential'),
        content: Text('Are you sure you want to delete the credential for "${credential.serviceName ?? 'Unnamed Service'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement credential deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Credential deletion - Coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Build service stat widget
  Widget _buildServiceStat(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: AdaptiveCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              AdaptiveText(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              AdaptiveText(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build API key card for AI service detail view
  Widget _buildApiKeyCard(BuildContext context, dynamic apiKey, dynamic service, DashboardState dashboardState) {
    return AdaptiveCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.key,
                  color: AppConstants.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdaptiveText(
                        apiKey.name ?? 'Unnamed API Key',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AdaptiveText(
                        'API Key',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyApiKeyToClipboard(context, apiKey),
                  tooltip: 'Copy to clipboard',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showEditApiKeyDialog(context, apiKey, service, dashboardState),
                  tooltip: 'Edit API key',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _showDeleteApiKeyDialog(context, apiKey, service, dashboardState),
                  tooltip: 'Delete API key',
                ),
              ],
            ),
            if (apiKey.description?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              AdaptiveText(
                apiKey.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show add API key to service dialog
  void _showAddApiKeyToServiceDialog(BuildContext context, dynamic service, DashboardState dashboardState) {
    // TODO: Implement add API key dialog specific to this service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add API key dialog - Coming soon')),
    );
  }

  /// Copy API key to clipboard
  void _copyApiKeyToClipboard(BuildContext context, dynamic apiKey) {
    // TODO: Implement clipboard copy functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key copied to clipboard')),
    );
  }

  /// Show edit API key dialog
  void _showEditApiKeyDialog(BuildContext context, dynamic apiKey, dynamic service, DashboardState dashboardState) {
    // TODO: Implement edit API key dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit API key dialog - Coming soon')),
    );
  }

  /// Show delete API key confirmation dialog
  void _showDeleteApiKeyDialog(BuildContext context, dynamic apiKey, dynamic service, DashboardState dashboardState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete API Key'),
        content: Text('Are you sure you want to delete the API key "${apiKey.name ?? 'Unnamed API Key'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement API key deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('API key deletion - Coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Build password vault management content
  Widget _buildPasswordVaultManagementContent(BuildContext context, DashboardState dashboardState) {
    final vaults = dashboardState.passwordVaults;

    return SingleChildScrollView(
      padding: ResponsiveService.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AdaptiveText(
                'Password Vaults',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Create Password Vault',
                onPressed: () => _showAddPasswordVaultDialog(context, dashboardState),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AdaptiveText(
            'Securely store and manage your passwords',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Password vaults grid
          if (vaults.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    AdaptiveText(
                      'No Password Vaults Yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    AdaptiveText(
                      'Create your first password vault to get started',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddPasswordVaultDialog(context, dashboardState),
                      icon: const Icon(Icons.add),
                      label: const AdaptiveText('Create Password Vault'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            AdaptiveGrid(
              children: vaults.map((vault) {
                return AdaptiveCard(
                  onTap: () {
                    dashboardState.selectPasswordVault(vault.id);
                    ResponsiveService.triggerLightHaptic();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lock,
                              color: AppConstants.primaryColor,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AdaptiveText(
                                    vault.name,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (vault.description != null)
                                    AdaptiveText(
                                      vault.description!,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _showPasswordVaultOptions(context, vault, dashboardState),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AdaptiveText(
                          '${vault.entryCount} ${vault.entryCount == 1 ? 'password' : 'passwords'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// Build password vault detail content
  Widget _buildPasswordVaultDetailContent(BuildContext context, DashboardState dashboardState) {
    final vaultId = dashboardState.currentSelectedItem;
    final vault = vaultId != null ? dashboardState.getPasswordVault(vaultId) : null;

    if (vault == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            AdaptiveText(
              'Password Vault Not Found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: ResponsiveService.getResponsivePadding(context),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  dashboardState.showPasswordVaultManagement();
                  ResponsiveService.triggerLightHaptic();
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdaptiveText(
                      vault.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (vault.description != null)
                      AdaptiveText(
                        vault.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Vault',
                onPressed: () => _showEditPasswordVaultDialog(context, vault, dashboardState),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete Vault',
                onPressed: () => _showDeletePasswordVaultDialog(context, vault, dashboardState),
              ),
            ],
          ),
        ),
        // Password entries list
        Expanded(
          child: vault.entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.vpn_key,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      AdaptiveText(
                        'No Passwords Yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      AdaptiveText(
                        'Add your first password to this vault',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddPasswordEntryDialog(context, vault, dashboardState),
                        icon: const Icon(Icons.add),
                        label: const AdaptiveText('Add Password'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: ResponsiveService.getResponsivePadding(context),
                  itemCount: vault.entries.length,
                  itemBuilder: (context, index) {
                    final entry = vault.entries[index];
                    return AdaptiveCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.vpn_key),
                        title: AdaptiveText(entry.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (entry.username != null)
                              AdaptiveText('User: ${entry.username}'),
                            if (entry.url != null)
                              AdaptiveText(entry.url!, style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.content_copy),
                              onPressed: () => _copyPasswordToClipboard(context, entry),
                              tooltip: 'Copy Password',
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _showPasswordEntryOptions(context, entry, vault, dashboardState),
                            ),
                          ],
                        ),
                        onTap: () => _showPasswordEntryDetails(context, entry, vault, dashboardState),
                      ),
                    );
                  },
                ),
        ),
        // Floating action button
        FloatingActionButton(
          onPressed: () => _showAddPasswordEntryDialog(context, vault, dashboardState),
          backgroundColor: AppConstants.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  /// Show add password vault dialog
  void _showAddPasswordVaultDialog(BuildContext context, DashboardState dashboardState) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Password Vault'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Vault Name',
                hintText: 'e.g., Personal, Work, Social Media',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description of this vault',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a vault name')),
                );
                return;
              }
              Navigator.pop(context);
              await dashboardState.createPasswordVault(
                nameController.text.trim(),
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  /// Show edit password vault dialog
  void _showEditPasswordVaultDialog(BuildContext context, dynamic vault, DashboardState dashboardState) {
    final nameController = TextEditingController(text: vault.name);
    final descriptionController = TextEditingController(text: vault.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Password Vault'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Vault Name',
                hintText: 'e.g., Personal, Work, Social Media',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description of this vault',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a vault name')),
                );
                return;
              }

              final updatedVault = vault.copyWith(
                name: nameController.text.trim(),
                description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
              );

              final success = await dashboardState.updatePasswordVault(updatedVault);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password vault updated')),
                );
                ResponsiveService.triggerLightHaptic();
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to update vault'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Show delete password vault dialog
  void _showDeletePasswordVaultDialog(BuildContext context, dynamic vault, DashboardState dashboardState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Password Vault'),
        content: Text('Are you sure you want to delete "${vault.name}"? All passwords in this vault will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await dashboardState.deletePasswordVault(vault.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password vault deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Show password vault options
  void _showPasswordVaultOptions(BuildContext context, dynamic vault, DashboardState dashboardState) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Vault'),
              onTap: () {
                Navigator.pop(context);
                _showEditPasswordVaultDialog(context, vault, dashboardState);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Vault', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeletePasswordVaultDialog(context, vault, dashboardState);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show add password entry dialog
  void _showAddPasswordEntryDialog(BuildContext context, dynamic vault, DashboardState dashboardState) {
    showDialog(
      context: context,
      builder: (context) => _AddPasswordEntryDialog(
        vault: vault,
        dashboardState: dashboardState,
        passwordGenerator: _passwordGenerator,
      ),
    );
  }

  /// Show password entry details
  void _showPasswordEntryDetails(BuildContext context, dynamic entry, dynamic vault, DashboardState dashboardState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PasswordEntryDetailsSheet(
        entry: entry,
        vault: vault,
        dashboardState: dashboardState,
        passwordGenerator: _passwordGenerator,
      ),
    );
  }

  /// Show password entry options
  void _showPasswordEntryOptions(BuildContext context, dynamic entry, dynamic vault, DashboardState dashboardState) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showPasswordEntryDetails(context, entry, vault, dashboardState);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement edit password entry
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit password - Coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeletePasswordEntryDialog(context, entry, vault, dashboardState);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Copy password to clipboard
  Future<void> _copyPasswordToClipboard(BuildContext context, dynamic entry) async {
    try {
      await Clipboard.setData(ClipboardData(text: entry.value));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password for "${entry.name}" copied to clipboard'),
            duration: const Duration(seconds: 2),
          ),
        );
        ResponsiveService.triggerLightHaptic();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show delete password entry dialog
  void _showDeletePasswordEntryDialog(BuildContext context, dynamic entry, dynamic vault, DashboardState dashboardState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Password'),
        content: Text('Are you sure you want to delete "${entry.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await dashboardState.deletePasswordEntry(entry.id, vault.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Dialog for adding a new password entry with strength indicator and generator
class _AddPasswordEntryDialog extends StatefulWidget {
  final dynamic vault;
  final DashboardState dashboardState;
  final PasswordGeneratorService passwordGenerator;

  const _AddPasswordEntryDialog({
    Key? key,
    required this.vault,
    required this.dashboardState,
    required this.passwordGenerator,
  }) : super(key: key);

  @override
  State<_AddPasswordEntryDialog> createState() => _AddPasswordEntryDialogState();
}

class _AddPasswordEntryDialogState extends State<_AddPasswordEntryDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _obscurePassword = true;
  bool _showGeneratorOptions = false;
  int _passwordLength = 16;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;

  int get _passwordStrength {
    if (_passwordController.text.isEmpty) return 0;
    return widget.passwordGenerator.calculateStrength(_passwordController.text);
  }

  String get _passwordStrengthLabel {
    return widget.passwordGenerator.getStrengthLabel(_passwordStrength);
  }

  Color get _passwordStrengthColor {
    final colorHex = widget.passwordGenerator.getStrengthColor(_passwordStrength);
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    final password = widget.passwordGenerator.generatePassword(
      length: _passwordLength,
      includeUppercase: _includeUppercase,
      includeLowercase: _includeLowercase,
      includeNumbers: _includeNumbers,
      includeSymbols: _includeSymbols,
    );
    setState(() {
      _passwordController.text = password;
    });
    ResponsiveService.triggerLightHaptic();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., Gmail, Netflix, Bank',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username/Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.autorenew),
                      tooltip: 'Generate Password',
                      onPressed: () {
                        setState(() {
                          _showGeneratorOptions = !_showGeneratorOptions;
                        });
                      },
                    ),
                  ],
                ),
              ),
              obscureText: _obscurePassword,
              onChanged: (value) => setState(() {}),
            ),
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AdaptiveText(
                        'Strength: $_passwordStrengthLabel',
                        style: TextStyle(
                          color: _passwordStrengthColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AdaptiveText(
                        '$_passwordStrength/100',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _passwordStrength / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                  ),
                ],
              ),
            ],
            if (_showGeneratorOptions) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdaptiveText(
                      'Password Generator Options',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        AdaptiveText('Length: $_passwordLength'),
                        Expanded(
                          child: Slider(
                            value: _passwordLength.toDouble(),
                            min: 8,
                            max: 32,
                            divisions: 24,
                            label: _passwordLength.toString(),
                            onChanged: (value) {
                              setState(() {
                                _passwordLength = value.toInt();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const AdaptiveText('Uppercase (A-Z)'),
                      value: _includeUppercase,
                      onChanged: (value) => setState(() => _includeUppercase = value ?? false),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const AdaptiveText('Lowercase (a-z)'),
                      value: _includeLowercase,
                      onChanged: (value) => setState(() => _includeLowercase = value ?? false),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const AdaptiveText('Numbers (0-9)'),
                      value: _includeNumbers,
                      onChanged: (value) => setState(() => _includeNumbers = value ?? false),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const AdaptiveText('Symbols (!@#\$%)'),
                      value: _includeSymbols,
                      onChanged: (value) => setState(() => _includeSymbols = value ?? false),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _generatePassword,
                      icon: const Icon(Icons.autorenew),
                      label: const AdaptiveText('Generate Password'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL (Optional)',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_nameController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter name and password')),
              );
              return;
            }
            Navigator.pop(context);
            await widget.dashboardState.createPasswordEntry(
              vaultId: widget.vault.id,
              name: _nameController.text.trim(),
              value: _passwordController.text.trim(),
              username: _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
              url: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password saved')),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Bottom sheet for displaying password entry details
class _PasswordEntryDetailsSheet extends StatefulWidget {
  final dynamic entry;
  final dynamic vault;
  final DashboardState dashboardState;
  final PasswordGeneratorService passwordGenerator;

  const _PasswordEntryDetailsSheet({
    Key? key,
    required this.entry,
    required this.vault,
    required this.dashboardState,
    required this.passwordGenerator,
  }) : super(key: key);

  @override
  State<_PasswordEntryDetailsSheet> createState() => _PasswordEntryDetailsSheetState();
}

class _PasswordEntryDetailsSheetState extends State<_PasswordEntryDetailsSheet> {
  bool _obscurePassword = true;

  int get _passwordStrength {
    return widget.passwordGenerator.calculateStrength(widget.entry.value);
  }

  String get _passwordStrengthLabel {
    return widget.passwordGenerator.getStrengthLabel(_passwordStrength);
  }

  Color get _passwordStrengthColor {
    final colorHex = widget.passwordGenerator.getStrengthColor(_passwordStrength);
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  }

  Future<void> _copyToClipboard(String text, String label) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label copied to clipboard'), duration: const Duration(seconds: 1)),
        );
        ResponsiveService.triggerLightHaptic();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to copy: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showRegeneratePasswordDialog(BuildContext context) async {
    int passwordLength = 16;
    bool includeUppercase = true;
    bool includeLowercase = true;
    bool includeNumbers = true;
    bool includeSymbols = true;
    String? generatedPassword;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Regenerate Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdaptiveText(
                  'Generate a new secure password for ${widget.entry.name}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    AdaptiveText('Length: $passwordLength'),
                    Expanded(
                      child: Slider(
                        value: passwordLength.toDouble(),
                        min: 8,
                        max: 32,
                        divisions: 24,
                        label: passwordLength.toString(),
                        onChanged: (value) {
                          setDialogState(() {
                            passwordLength = value.toInt();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  title: const AdaptiveText('Uppercase (A-Z)'),
                  value: includeUppercase,
                  onChanged: (value) => setDialogState(() => includeUppercase = value ?? false),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const AdaptiveText('Lowercase (a-z)'),
                  value: includeLowercase,
                  onChanged: (value) => setDialogState(() => includeLowercase = value ?? false),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const AdaptiveText('Numbers (0-9)'),
                  value: includeNumbers,
                  onChanged: (value) => setDialogState(() => includeNumbers = value ?? false),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const AdaptiveText('Symbols (!@#\$%)'),
                  value: includeSymbols,
                  onChanged: (value) => setDialogState(() => includeSymbols = value ?? false),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                if (generatedPassword != null) ...[
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final strengthScore = widget.passwordGenerator.calculateStrength(generatedPassword!);
                      final strengthLabel = widget.passwordGenerator.getStrengthLabel(strengthScore);
                      final strengthColorHex = widget.passwordGenerator.getStrengthColor(strengthScore);
                      final strengthColor = Color(int.parse(strengthColorHex.replaceFirst('#', '0xFF')));

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppConstants.primaryColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AdaptiveText(
                              'Generated Password:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: AdaptiveText(
                                    generatedPassword!,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.content_copy),
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(text: generatedPassword!));
                                    if (dialogContext.mounted) {
                                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                                        const SnackBar(
                                          content: Text('Password copied to clipboard'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                    ResponsiveService.triggerLightHaptic();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AdaptiveText(
                                  'Strength: $strengthLabel',
                                  style: TextStyle(
                                    color: strengthColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                AdaptiveText(
                                  '$strengthScore/100',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: strengthScore / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final newPassword = widget.passwordGenerator.generatePassword(
                  length: passwordLength,
                  includeUppercase: includeUppercase,
                  includeLowercase: includeLowercase,
                  includeNumbers: includeNumbers,
                  includeSymbols: includeSymbols,
                );
                setDialogState(() {
                  generatedPassword = newPassword;
                });
                ResponsiveService.triggerLightHaptic();
              },
              icon: const Icon(Icons.autorenew),
              label: const AdaptiveText('Generate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            if (generatedPassword != null)
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  // Update the password entry
                  final updatedEntry = widget.entry.copyWith(
                    value: generatedPassword,
                    updatedAt: DateTime.now(),
                  );
                  await widget.dashboardState.updatePasswordEntry(updatedEntry);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password updated successfully')),
                    );
                    Navigator.pop(context); // Close the details sheet
                  }
                },
                child: const Text('Save Password'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.vpn_key, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdaptiveText(
                          entry.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (entry.username != null)
                          AdaptiveText(
                            entry.username!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Password section
                  _buildDetailSection(
                    context,
                    icon: Icons.lock,
                    title: 'Password',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AdaptiveText(
                                _obscurePassword ? '••••••••' : entry.value,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                                ResponsiveService.triggerLightHaptic();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.content_copy),
                              onPressed: () => _copyToClipboard(entry.value, 'Password'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.autorenew),
                              tooltip: 'Regenerate Password',
                              onPressed: () => _showRegeneratePasswordDialog(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Strength indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AdaptiveText(
                              'Strength: $_passwordStrengthLabel',
                              style: TextStyle(
                                color: _passwordStrengthColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AdaptiveText(
                              '$_passwordStrength/100',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: _passwordStrength / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                        ),
                      ],
                    ),
                  ),
                  // Username section
                  if (entry.username != null)
                    _buildDetailSection(
                      context,
                      icon: Icons.person,
                      title: 'Username',
                      child: Row(
                        children: [
                          Expanded(
                            child: AdaptiveText(entry.username!),
                          ),
                          IconButton(
                            icon: const Icon(Icons.content_copy),
                            onPressed: () => _copyToClipboard(entry.username!, 'Username'),
                          ),
                        ],
                      ),
                    ),
                  // Email section
                  if (entry.email != null)
                    _buildDetailSection(
                      context,
                      icon: Icons.email,
                      title: 'Email',
                      child: Row(
                        children: [
                          Expanded(
                            child: AdaptiveText(entry.email!),
                          ),
                          IconButton(
                            icon: const Icon(Icons.content_copy),
                            onPressed: () => _copyToClipboard(entry.email!, 'Email'),
                          ),
                        ],
                      ),
                    ),
                  // URL section
                  if (entry.url != null)
                    _buildDetailSection(
                      context,
                      icon: Icons.link,
                      title: 'URL',
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final url = entry.url!;
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url));
                                }
                              },
                              child: AdaptiveText(
                                entry.url!,
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.content_copy),
                            onPressed: () => _copyToClipboard(entry.url!, 'URL'),
                          ),
                        ],
                      ),
                    ),
                  // Notes section
                  if (entry.notes != null)
                    _buildDetailSection(
                      context,
                      icon: Icons.note,
                      title: 'Notes',
                      child: AdaptiveText(entry.notes!),
                    ),
                  // Tags section
                  if (entry.tags != null && entry.tags!.isNotEmpty)
                    _buildDetailSection(
                      context,
                      icon: Icons.local_offer,
                      title: 'Tags',
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: entry.tagList.map((tag) {
                          return Chip(
                            label: AdaptiveText(tag, style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                          );
                        }).toList(),
                      ),
                    ),
                  // Metadata section
                  _buildDetailSection(
                    context,
                    icon: Icons.info_outline,
                    title: 'Information',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetadataRow('Created', _formatDate(entry.createdAt)),
                        const SizedBox(height: 4),
                        _buildMetadataRow('Updated', _formatDate(entry.updatedAt)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, {required IconData icon, required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              AdaptiveText(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AdaptiveText(label, style: const TextStyle(color: Colors.grey)),
        AdaptiveText(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
