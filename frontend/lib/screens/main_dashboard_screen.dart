import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../models/auth_state.dart';
import '../models/dashboard_state.dart';
import '../models/project.dart';
import '../models/ai_service.dart';
import '../utils/constants.dart';
import 'settings_screen.dart';
import 'support_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  // Currently selected section (Projects or AI Services)
  String _currentSection = 'projects';

  // Currently selected item (project or AI service)
  String? _currentSelectedItem;

  // Current view (dashboard, projects, ai, support)
  String _currentView = 'dashboard';

  // Track which section is expanded (projects, ai, or null)
  String? _expandedSection;

  // Track recently used items
  final List<Map<String, dynamic>> _recentlyUsed = [];

  // Track visible passwords (key id -> visibility state)
  final Map<String, bool> _visiblePasswords = {};

  // Track editing state (key id -> editing state)
  final Map<String, bool> _editingKeys = {};

  @override
  void initState() {
    super.initState();
    // Load data when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardState = Provider.of<DashboardState>(context, listen: false);
      dashboardState.loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthState, DashboardState>(
      builder: (context, authState, dashboardState, child) {
        return Scaffold(
      body: Column(
        children: [
          // Full-width header
          Container(
            height: 80,
            color: AppConstants.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: AppConstants.accentColor,
                  size: 42,
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppConstants.appTagline,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.palette, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/theme-test');
                  },
                  tooltip: 'Theme Test',
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () {
                    final authState = Provider.of<AuthState>(context, listen: false);
                    authState.logout();
                  },
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
          // Main content area with sidebar and footer
          Expanded(
            child: Column(
              children: [
                // Main content area with sidebar
                Expanded(
                  child: Row(
                    children: [
                      // Full-height sidebar
                      Container(
                        width: 250,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppConstants.primaryColor, // Navy blue at top
                              AppConstants.primaryColor.withValues(alpha: 0.95), // Slightly lighter navy at bottom
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            // Scrollable content with structured menu
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Dashboard Link (moved from OVERVIEW section)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: dashboardState.currentView == 'overview'
                                              ? AppConstants.primaryColor.withValues(alpha: 0.2)
                                              : AppConstants.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: dashboardState.currentView == 'overview'
                                              ? Border.all(color: AppConstants.accentColor.withValues(alpha: 0.5), width: 1)
                                              : null,
                                        ),
                                        child: ListTile(
                                          title: Text(
                                            'Dashboard',
                                            style: TextStyle(
                                              fontWeight: dashboardState.currentView == 'overview' ? FontWeight.w600 : FontWeight.w500,
                                              fontSize: 15,
                                              color: Colors.white,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Overview & Statistics',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withValues(alpha: 0.8),
                                            ),
                                          ),
                                          leading: Icon(
                                            Icons.dashboard,
                                            color: AppConstants.accentColor,
                                            size: 22,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          dense: true,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          onTap: () {
                                            dashboardState.showOverview();
                                          },
                                        ),
                                      ),
                                    ),

                                    const Divider(height: 1),

                                    // PROJECTS Section
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              dashboardState.showProjectsOverview();
                                              setState(() {
                                                _expandedSection = _expandedSection == 'projects' ? null : 'projects';
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: dashboardState.currentView == 'projects_overview'
                                                    ? AppConstants.primaryColor.withValues(alpha: 0.2)
                                                    : AppConstants.primaryColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: dashboardState.currentView == 'projects_overview'
                                                    ? Border.all(color: AppConstants.accentColor.withValues(alpha: 0.5), width: 1)
                                                    : null,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.folder,
                                                    size: 18,
                                                    color: dashboardState.currentView == 'projects_overview' ? AppConstants.accentColor : Colors.white.withValues(alpha: 0.8),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    'PROJECTS',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 1.2,
                                                      color: dashboardState.currentView == 'projects_overview'
                                                          ? Colors.white
                                                          : Colors.white.withValues(alpha: 0.9),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '(${dashboardState.projects.length})',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: dashboardState.currentView == 'projects_overview'
                                                          ? Colors.white.withValues(alpha: 0.9)
                                                          : Colors.white.withValues(alpha: 0.7),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Icon(
                                                    _expandedSection == 'projects' ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                                    size: 18,
                                                    color: dashboardState.currentView == 'projects_overview'
                                                        ? AppConstants.accentColor
                                                        : Colors.white.withValues(alpha: 0.8),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (_expandedSection == 'projects') ...[
                                            ...dashboardState.projects.map((project) {
                                              final isSelected = dashboardState.currentSelectedItem == project.id;
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 4),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? AppConstants.accentColor.withValues(alpha: 0.15) : AppConstants.primaryColor.withValues(alpha: 0.05),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: isSelected ? Border.all(color: AppConstants.accentColor.withValues(alpha: 0.3), width: 1) : null,
                                                ),
                                                child: ListTile(
                                                  title: Text(
                                                    project.name,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  leading: Icon(
                                                    Icons.folder,
                                                    color: isSelected ? AppConstants.accentColor : Colors.white.withValues(alpha: 0.8),
                                                    size: 18,
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  dense: true,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  onTap: () {
                                                    dashboardState.selectProject(project.id);
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                            const SizedBox(height: 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: AppConstants.primaryColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: AppConstants.accentColor.withValues(alpha: 0.3), width: 1),
                                              ),
                                              child: ListTile(
                                                title: Text(
                                                  'Add New Project',
                                                  style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                                                ),
                                                leading: Icon(Icons.add, color: AppConstants.accentColor, size: 18),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                dense: true,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                onTap: _showAddProjectDialog,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    const Divider(height: 1),

                                    // AI SERVICES Section
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              dashboardState.showAiServicesOverview();
                                              setState(() {
                                                _expandedSection = _expandedSection == 'ai' ? null : 'ai';
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: dashboardState.currentView == 'ai_overview'
                                                    ? AppConstants.primaryColor.withValues(alpha: 0.2)
                                                    : AppConstants.primaryColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: dashboardState.currentView == 'ai_overview'
                                                    ? Border.all(color: AppConstants.accentColor.withValues(alpha: 0.5), width: 1)
                                                    : null,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.auto_awesome,
                                                    size: 18,
                                                    color: dashboardState.currentView == 'ai_overview' ? AppConstants.accentColor : Colors.white.withValues(alpha: 0.8),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    'AI SERVICES',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 1.2,
                                                      color: dashboardState.currentView == 'ai_overview'
                                                          ? Colors.white
                                                          : Colors.white.withValues(alpha: 0.9),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '(${dashboardState.aiServices.length})',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: dashboardState.currentView == 'ai_overview'
                                                          ? Colors.white.withValues(alpha: 0.9)
                                                          : Colors.white.withValues(alpha: 0.7),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Icon(
                                                    _expandedSection == 'ai' ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                                    size: 18,
                                                    color: dashboardState.currentView == 'ai_overview'
                                                        ? AppConstants.accentColor
                                                        : Colors.white.withValues(alpha: 0.8),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (_expandedSection == 'ai') ...[
                                            ...dashboardState.aiServices.map((service) {
                                              final isSelected = dashboardState.currentSelectedItem == service.id;
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 4),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? AppConstants.accentColor.withValues(alpha: 0.15) : AppConstants.primaryColor.withValues(alpha: 0.05),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: isSelected ? Border.all(color: AppConstants.accentColor.withValues(alpha: 0.3), width: 1) : null,
                                                ),
                                                child: ListTile(
                                                  title: Text(
                                                    service.name,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  leading: Icon(
                                                    Icons.auto_awesome,
                                                    color: isSelected ? AppConstants.accentColor : Colors.white.withValues(alpha: 0.8),
                                                    size: 18,
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  dense: true,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  onTap: () {
                                                    dashboardState.selectAiService(service.id);
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                            const SizedBox(height: 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: AppConstants.primaryColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: AppConstants.accentColor.withValues(alpha: 0.3), width: 1),
                                              ),
                                              child: ListTile(
                                                title: Text(
                                                  'Add New AI Service',
                                                  style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                                                ),
                                                leading: Icon(Icons.add, color: AppConstants.accentColor, size: 18),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                dense: true,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                onTap: _showAddAiServiceDialog,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Sticky bottom section
                            Container(
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor.withValues(alpha: 0.03),
                                border: Border(
                                  top: BorderSide(color: AppConstants.primaryColor.withValues(alpha: 0.1), width: 1),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: Text(
                                      'Support',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    leading: Icon(
                                      Icons.help,
                                      color: AppConstants.accentColor,
                                      size: 20,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    dense: true,
                                    onTap: () {
                                      setState(() {
                                        _currentView = 'support';
                                        _currentSelectedItem = null;
                                      });
                                    },
                                  ),
                                  ListTile(
                                    title: Text(
                                      'Settings',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    leading: Icon(
                                      Icons.settings,
                                      color: AppConstants.accentColor,
                                      size: 20,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    dense: true,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const SettingsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Main content area
                      Expanded(
                        child: _buildMainContent(),
                      ),
                    ],
                  ),
                ),
                // Footer
                Container(
                  height: 50,
                  color: AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        AppConstants.copyright,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'v${AppConstants.appVersion}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () => _showLicenseDialog(context),
                        child: const Text(
                          'License',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    final dashboardState = Provider.of<DashboardState>(context);

    if (dashboardState.currentView == 'overview') {
      return _buildDashboardView();
    } else if (dashboardState.currentView == 'projects_overview') {
      return _buildProjectsOverview();
    } else if (dashboardState.currentView == 'ai_overview') {
      return _buildAiServicesOverview();
    } else if (dashboardState.currentView == 'support') {
      return const SupportScreen();
    } else if (dashboardState.currentSelectedItem != null) {
      if (dashboardState.currentSection == 'projects') {
        final project = dashboardState.getProject(dashboardState.currentSelectedItem!);
        if (project != null) {
          return _buildProjectDetails(project);
        }
      } else {
        final service = dashboardState.getAiService(dashboardState.currentSelectedItem!);
        if (service != null) {
          return _buildAiServiceDetails(service);
        }
      }
    } else {
      return Container(
        color: Colors.grey[50],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.dashboard,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 20),
              const Text(
                'Select a project or AI service',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Text(
                _currentSection == 'projects'
                  ? 'Choose a project from the sidebar to view its details'
                  : 'Choose an AI service from the sidebar to view its details',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              const Icon(
                Icons.security,
                size: 60,
                color: Colors.amber,
              ),
            ],
          ),
        ),
      );
    }

    // Fallback return
    return Container(
      color: Colors.grey[50],
      child: const Center(
        child: Text(
          'No content to display',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }

  void _showLicenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('License & Disclaimer'),
          content: SingleChildScrollView(
            child: Text(
              AppConstants.licenseText,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
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

  Widget _buildProjectDetails(Project project) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder, size: 30, color: AppConstants.accentColor),
              const SizedBox(width: 10),
              Text(
                project.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditProjectDialog(project),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'API Keys & Credentials',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: project.credentials.length,
              itemBuilder: (context, index) {
                final credential = project.credentials[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: _getIconForKeyType(credential.type.value),
                    title: Text(credential.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCredentialSubtitle(credential),
                        Text(
                          'Modified ${_formatLastModified(credential.updatedAt)}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          icon: Icons.copy,
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () => _copyToClipboard(credential.value),
                          tooltip: 'Copy to clipboard',
                        ),
                        const SizedBox(width: 4),
                        _buildActionButton(
                          icon: Icons.edit,
                          color: Theme.of(context).colorScheme.secondary,
                          onPressed: () => _startEditingCredential(credential),
                          tooltip: 'Edit value',
                        ),
                        if (credential.type == CredentialType.password) ...[
                          const SizedBox(width: 4),
                          _buildActionButton(
                            icon: _visiblePasswords[credential.id] ?? false
                              ? Icons.visibility_off
                              : Icons.visibility,
                            color: Theme.of(context).colorScheme.outline,
                            onPressed: () => _togglePasswordVisibility(credential),
                            tooltip: (_visiblePasswords[credential.id] ?? false)
                              ? 'Hide password'
                              : 'Show password',
                          ),
                        ],
                        const SizedBox(width: 4),
                        _buildActionButton(
                          icon: Icons.delete,
                          color: Theme.of(context).colorScheme.error,
                          onPressed: () => _deleteCredential(credential.id, project.id),
                          tooltip: 'Delete credential',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddCredentialDialog(project.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add New Key'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _generatePassword(project.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.password),
                label: const Text('Generate Password'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiServiceDetails(AiService service) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 30, color: AppConstants.accentColor),
              const SizedBox(width: 10),
              Text(
                service.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditAiServiceDialog(service),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'API Keys',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: service.keys.length,
              itemBuilder: (context, index) {
                final key = service.keys[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.key, color: AppConstants.accentColor),
                    title: Text(key.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAiServiceKeySubtitle(key),
                        Text(
                          'Modified ${_formatLastModified(key.updatedAt)}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          icon: Icons.copy,
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () => _copyToClipboard(key.value),
                          tooltip: 'Copy to clipboard',
                        ),
                        const SizedBox(width: 4),
                        _buildActionButton(
                          icon: Icons.edit,
                          color: Theme.of(context).colorScheme.secondary,
                          onPressed: () => _startEditingAiServiceKey(key),
                          tooltip: 'Edit value',
                        ),
                        const SizedBox(width: 4),
                        _buildActionButton(
                          icon: Icons.delete,
                          color: Theme.of(context).colorScheme.error,
                          onPressed: () => _deleteAiServiceKey(key.id, service.id),
                          tooltip: 'Delete API key',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddAiServiceKeyDialog(service.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add New Key'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView() {
    final dashboardState = Provider.of<DashboardState>(context);

    // Calculate stats
    final totalProjects = dashboardState.projects.length;
    final totalAiServices = dashboardState.aiServices.length;
    final totalKeys = dashboardState.projects.fold(0, (sum, project) => sum + project.credentials.length) +
                      dashboardState.aiServices.fold(0, (sum, service) => sum + service.keys.length);

    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              AppConstants.appTagline,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(Icons.folder, size: 40, color: AppConstants.accentColor),
                          const SizedBox(height: 10),
                          Text(
                            '$totalProjects',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text('Projects', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(Icons.auto_awesome, size: 40, color: AppConstants.accentColor),
                          const SizedBox(height: 10),
                          Text(
                            '$totalAiServices',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text('AI Services', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(Icons.key, size: 40, color: AppConstants.accentColor),
                          const SizedBox(height: 10),
                          Text(
                            '$totalKeys',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text('API Keys', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddProjectDialog,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Project'),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddAiServiceDialog,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: AppConstants.accentColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Add AI Service'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Recently Used Section
            if (_recentlyUsed.isNotEmpty) ...[
              const Text(
                'Recently Used',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _recentlyUsed.map((item) {
                  return Container(
                    width: 200,
                    child: Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          if (item['type'] == 'project') {
                            _trackRecentlyUsed('project', item['id'], item['name']);
                            setState(() {
                              _currentSelectedItem = item['id'];
                              _currentSection = 'projects';
                              _currentView = 'projects';
                            });
                          } else if (item['type'] == 'ai_service') {
                            _trackRecentlyUsed('ai_service', item['id'], item['name']);
                            setState(() {
                              _currentSelectedItem = item['id'];
                              _currentSection = 'ai';
                              _currentView = 'ai';
                            });
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    item['type'] == 'project' ? Icons.folder : Icons.auto_awesome,
                                    size: 16,
                                    color: AppConstants.accentColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['type'] == 'project' ? 'Project' : 'AI Service',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
            ],

            // Getting Started Guide
            const Text(
              'Getting Started',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Cred Manager!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Here\'s how to get started:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 15),
                    _buildGuideStep(1, 'Create your first project to organize your API keys'),
                    _buildGuideStep(2, 'Add API keys for different services (databases, APIs, etc.)'),
                    _buildGuideStep(3, 'Set up AI services for OpenAI, Anthropic, and other providers'),
                    _buildGuideStep(4, 'Use the secure password generator for strong credentials'),
                    const SizedBox(height: 20),
                    const Text(
                      '💡 Tip: All your data is encrypted and stored securely. Your secrets are safe with us!',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
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

  Widget _buildGuideStep(int step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppConstants.accentColor,
            child: Text(
              '$step',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  String _formatLastModified(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _trackRecentlyUsed(String type, String id, String name) {
    // Remove if already exists
    _recentlyUsed.removeWhere((item) => item['id'] == id && item['type'] == type);

    // Add to beginning of list
    _recentlyUsed.insert(0, {
      'type': type,
      'id': id,
      'name': name,
      'lastAccessed': DateTime.now(),
    });

    // Keep only last 5 items
    if (_recentlyUsed.length > 5) {
      _recentlyUsed.removeRange(5, _recentlyUsed.length);
    }
  }

  Widget _buildProjectsOverview() {
    final dashboardState = Provider.of<DashboardState>(context);

    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder, size: 32, color: AppConstants.accentColor),
                const SizedBox(width: 12),
                const Text(
                  'Projects Overview',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manage all your projects and their API keys',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

            // Projects Grid/List
            if (dashboardState.projects.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_open, size: 80, color: Colors.grey),
                    const SizedBox(height: 20),
                    const Text(
                      'No projects yet',
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Create your first project to get started',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _showAddProjectDialog,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: AppConstants.accentColor,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Project'),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: dashboardState.projects.length,
                itemBuilder: (context, index) {
                  final project = dashboardState.projects[index];
                  return Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        _trackRecentlyUsed('project', project.id, project.name);
                        dashboardState.selectProject(project.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.folder, color: AppConstants.accentColor, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    project.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => _showEditProjectDialog(project),
                                  tooltip: 'Edit Project',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: _showAddProjectDialog,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: AppConstants.accentColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add New Project'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiServicesOverview() {
    final dashboardState = Provider.of<DashboardState>(context);

    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 32, color: AppConstants.accentColor),
                const SizedBox(width: 12),
                const Text(
                  'AI Services Overview',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your AI service integrations and API keys',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

            // AI Services Grid/List
            if (dashboardState.aiServices.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    const Text(
                      'No AI services yet',
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add your first AI service to get started',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _showAddAiServiceDialog,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: AppConstants.accentColor,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add First AI Service'),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: dashboardState.aiServices.length,
                itemBuilder: (context, index) {
                  final service = dashboardState.aiServices[index];
                  return Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        _trackRecentlyUsed('ai_service', service.id, service.name);
                        dashboardState.selectAiService(service.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome, color: AppConstants.accentColor, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    service.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => _showEditAiServiceDialog(service),
                                  tooltip: 'Edit AI Service',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: _showAddAiServiceDialog,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: AppConstants.accentColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add New AI Service'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeySubtitle(Map<String, dynamic> key) {
    bool isEditing = _editingKeys[key['id']] ?? false;

    if (isEditing) {
      return _buildEditableKeyValue(key);
    }

    if (key['type'] == 'password') {
      // Check if password is set to visible
      bool isVisible = _visiblePasswords[key['id']] ?? false;
      if (isVisible) {
        return GestureDetector(
          onTap: () => _startEditingKey(key),
          child: Text(
            key['value'],
            style: TextStyle(fontFamily: 'monospace', color: AppConstants.accentColor),
          ),
        );
      } else {
        return const Text('••••••••'); // Masked password
      }
    } else {
      // Truncate long values
      String value = key['value'];
      if (value.length > 30) {
        value = '${value.substring(0, 30)}...';
      }
      return GestureDetector(
        onTap: () => _startEditingKey(key),
        child: Text(
          value,
          style: TextStyle(color: AppConstants.accentColor),
        ),
      );
    }
  }

  Widget _buildCredentialSubtitle(Credential credential) {
    bool isEditing = _editingKeys[credential.id] ?? false;

    if (isEditing) {
      return _buildEditableCredentialValue(credential);
    }

    if (credential.type == CredentialType.password) {
      // Check if password is set to visible
      bool isVisible = _visiblePasswords[credential.id] ?? false;
      if (isVisible) {
        return GestureDetector(
          onTap: () => _startEditingCredential(credential),
          child: Text(
            credential.value,
            style: TextStyle(fontFamily: 'monospace', color: AppConstants.accentColor),
          ),
        );
      } else {
        return const Text('••••••••'); // Masked password
      }
    } else {
      // Truncate long values
      String value = credential.value.length > 30
          ? '${credential.value.substring(0, 30)}...'
          : credential.value;
      return GestureDetector(
        onTap: () => _startEditingCredential(credential),
        child: Text(
          value,
          style: TextStyle(color: AppConstants.accentColor),
        ),
      );
    }
  }

  Widget _buildAiServiceKeySubtitle(AiServiceKey key) {
    bool isEditing = _editingKeys[key.id] ?? false;

    if (isEditing) {
      return _buildEditableAiServiceKeyValue(key);
    }

    // Truncate long values
    String value = key.value.length > 30
        ? '${key.value.substring(0, 30)}...'
        : key.value;
    return GestureDetector(
      onTap: () => _startEditingAiServiceKey(key),
      child: Text(
        value,
        style: TextStyle(color: AppConstants.accentColor),
      ),
    );
  }

  Widget _buildEditableKeyValue(Map<String, dynamic> key) {
    final controller = TextEditingController(text: key['value']);
    final focusNode = FocusNode();

    // Auto-focus and select all text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Editing: ${key['name']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (value) => _saveKeyValue(key, value),
                  maxLines: key['type'] == 'password' ? 1 : 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  _buildActionButton(
                    icon: Icons.check,
                    color: Colors.green,
                    onPressed: () => _saveKeyValue(key, controller.text),
                    tooltip: 'Save changes',
                  ),
                  const SizedBox(width: 6),
                  _buildActionButton(
                    icon: Icons.close,
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () => _cancelEditingKey(key),
                    tooltip: 'Cancel editing',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCredentialValue(Credential credential) {
    final controller = TextEditingController(text: credential.value);
    final focusNode = FocusNode();

    // Auto-focus and select all text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editing: ${credential.name}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  maxLines: credential.type == CredentialType.connectionString ? 3 : 1,
                  onSubmitted: (value) => _saveCredentialValue(credential, value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _cancelEditingCredential(credential),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.outline,
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _saveCredentialValue(credential, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableAiServiceKeyValue(AiServiceKey key) {
    final controller = TextEditingController(text: key.value);
    final focusNode = FocusNode();

    // Auto-focus and select all text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editing: ${key.name}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  maxLines: 1,
                  onSubmitted: (value) => _saveAiServiceKeyValue(key, value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _cancelEditingAiServiceKey(key),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.outline,
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _saveAiServiceKeyValue(key, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getIconForKeyType(String type) {
    switch (type) {
      case 'api_key':
        return const Icon(Icons.key);
      case 'password':
        return const Icon(Icons.password);
      case 'url':
        return const Icon(Icons.link);
      case 'connection_string':
        return const Icon(Icons.storage);
      default:
        return const Icon(Icons.info);
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: color,
        onPressed: onPressed,
        tooltip: tooltip,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String value) {
    // TODO: Implement actual clipboard copy functionality
    // For now, we'll show a more informative message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value.length > 20 ? '${value.substring(0, 20)}...' : value,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  void _startEditingKey(Map<String, dynamic> key) {
    setState(() {
      _editingKeys[key['id']] = true;
    });
  }

  void _saveKeyValue(Map<String, dynamic> key, String newValue) {
    setState(() {
      // Update the key value
      key['value'] = newValue;
      key['lastModified'] = DateTime.now();

      // Stop editing
      _editingKeys[key['id']] = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API key updated successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _cancelEditingKey(Map<String, dynamic> key) {
    setState(() {
      _editingKeys[key['id']] = false;
    });
  }



  void _showAddProjectDialog() {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Project'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Project Name',
              hintText: 'Enter project name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final dashboardState = Provider.of<DashboardState>(context, listen: false);

                  try {
                    final project = await dashboardState.createProject(
                      nameController.text,
                      description: '',
                    );

                    if (project != null) {
                      Navigator.of(context).pop();

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('Project "${nameController.text}" created successfully!'),
                            ],
                          ),
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to create project: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddAiServiceDialog() {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New AI Service'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Service Name',
              hintText: 'Enter AI service name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final dashboardState = Provider.of<DashboardState>(context, listen: false);

                  try {
                    final service = await dashboardState.createAiService(
                      nameController.text,
                      description: '',
                    );

                    if (service != null) {
                      Navigator.of(context).pop();

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('AI Service "${nameController.text}" created successfully!'),
                            ],
                          ),
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to create AI service: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }



  void _generatePassword(String projectId) async {
    final dashboardState = Provider.of<DashboardState>(context, listen: false);

    // Generate a random password
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    final password = List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();

    final passwordName = 'Generated Password ${DateTime.now().second}';

    try {
      final success = await dashboardState.createCredential(
        projectId: projectId,
        name: passwordName,
        value: password,
        type: CredentialType.password,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Password "$passwordName" generated and added!'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate password: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditProjectDialog(Project project) {
    final nameController = TextEditingController(text: project.name);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Project'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Project Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final dashboardState = Provider.of<DashboardState>(context, listen: false);

                  try {
                    final success = await dashboardState.updateProject(
                      project.copyWith(name: nameController.text),
                    );

                    if (success) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Project updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update project: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditAiServiceDialog(AiService service) {
    final nameController = TextEditingController(text: service.name);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit AI Service'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Service Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final dashboardState = Provider.of<DashboardState>(context, listen: false);

                  try {
                    final success = await dashboardState.updateAiService(
                      service.copyWith(name: nameController.text),
                    );

                    if (success) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('AI Service updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update AI service: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // New methods for credential management
  void _startEditingCredential(Credential credential) {
    setState(() {
      _editingKeys[credential.id] = true;
    });
  }

  void _saveCredentialValue(Credential credential, String newValue) async {
    final dashboardState = Provider.of<DashboardState>(context, listen: false);

    try {
      await dashboardState.updateCredential(
        credential.copyWith(value: newValue),
      );

      setState(() {
        _editingKeys[credential.id] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credential updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update credential: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _cancelEditingCredential(Credential credential) {
    setState(() {
      _editingKeys[credential.id] = false;
    });
  }

  void _deleteCredential(String credentialId, String projectId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Credential'),
        content: const Text('Are you sure you want to delete this credential? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      final dashboardState = Provider.of<DashboardState>(context, listen: false);

      try {
        await dashboardState.deleteCredential(credentialId, projectId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credential deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete credential: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _togglePasswordVisibility(Credential credential) {
    setState(() {
      String credentialId = credential.id;
      _visiblePasswords[credentialId] = !(_visiblePasswords[credentialId] ?? false);
    });

    bool isNowVisible = _visiblePasswords[credential.id] ?? false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isNowVisible ? 'Password revealed' : 'Password hidden'
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showAddCredentialDialog(String projectId) {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    CredentialType credentialType = CredentialType.apiKey;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Credential'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Credential Name',
                  hintText: 'e.g., Database Password',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: 'Credential Value',
                  hintText: 'Enter the credential value',
                ),
                obscureText: credentialType == CredentialType.password,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CredentialType>(
                value: credentialType,
                decoration: const InputDecoration(
                  labelText: 'Credential Type',
                ),
                items: CredentialType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      credentialType = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && valueController.text.isNotEmpty) {
                  final dashboardState = Provider.of<DashboardState>(context, listen: false);

                  try {
                    await dashboardState.createCredential(
                      projectId: projectId,
                      name: nameController.text,
                      value: valueController.text,
                      type: credentialType,
                    );

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('Credential "${nameController.text}" added successfully!'),
                          ],
                        ),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add credential: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // AI Service Key methods
  void _startEditingAiServiceKey(AiServiceKey key) {
    setState(() {
      _editingKeys[key.id] = true;
    });
  }

  void _saveAiServiceKeyValue(AiServiceKey key, String newValue) async {
    final dashboardState = Provider.of<DashboardState>(context, listen: false);

    try {
      await dashboardState.updateAiServiceKey(
        key.copyWith(value: newValue),
      );

      setState(() {
        _editingKeys[key.id] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI service key updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update AI service key: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _cancelEditingAiServiceKey(AiServiceKey key) {
    setState(() {
      _editingKeys[key.id] = false;
    });
  }

  void _deleteAiServiceKey(String keyId, String serviceId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete AI Service Key'),
        content: const Text('Are you sure you want to delete this API key? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      final dashboardState = Provider.of<DashboardState>(context, listen: false);

      try {
        await dashboardState.deleteAiServiceKey(keyId, serviceId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI service key deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete AI service key: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAddAiServiceKeyDialog(String serviceId) {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    AiKeyType keyType = AiKeyType.apiKey;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New AI Service Key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Key Name',
                  hintText: 'e.g., API Key',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: 'Key Value',
                  hintText: 'Enter the API key value',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AiKeyType>(
                value: keyType,
                decoration: const InputDecoration(
                  labelText: 'Key Type',
                ),
                items: AiKeyType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      keyType = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && valueController.text.isNotEmpty) {
                  final dashboardState = Provider.of<DashboardState>(context, listen: false);

                  try {
                    await dashboardState.createAiServiceKey(
                      serviceId: serviceId,
                      name: nameController.text,
                      value: valueController.text,
                      type: keyType,
                    );

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('AI service key "${nameController.text}" added successfully!'),
                          ],
                        ),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add AI service key: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}