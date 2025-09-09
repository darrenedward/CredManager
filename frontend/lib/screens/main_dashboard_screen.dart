import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../models/auth_state.dart';
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

  // Data for projects - each project has a list of keys
  final Map<String, Map<String, dynamic>> _projects = {
    '1': {
      'id': '1',
      'name': 'E-commerce Platform',
      'lastModified': DateTime.now().subtract(const Duration(hours: 2)),
      'keys': [
        {'id': '1-1', 'name': 'Database Connection String', 'value': 'postgresql://user:pass@host:5432/db', 'type': 'connection_string', 'lastModified': DateTime.now().subtract(const Duration(hours: 3))},
        {'id': '1-2', 'name': 'Admin Password', 'value': 'supersecretpassword123', 'type': 'password', 'lastModified': DateTime.now().subtract(const Duration(hours: 1))},
        {'id': '1-3', 'name': 'API Endpoint', 'value': 'https://api.myproject.com/v1', 'type': 'url', 'lastModified': DateTime.now().subtract(const Duration(minutes: 30))},
      ]
    },
    '2': {
      'id': '2',
      'name': 'Mobile App Backend',
      'lastModified': DateTime.now().subtract(const Duration(hours: 5)),
      'keys': [
        {'id': '2-1', 'name': 'Firebase API Key', 'value': 'AIzaSyB1234567890', 'type': 'api_key', 'lastModified': DateTime.now().subtract(const Duration(hours: 4))},
        {'id': '2-2', 'name': 'Database Password', 'value': 'mobileappsecret', 'type': 'password', 'lastModified': DateTime.now().subtract(const Duration(hours: 2))},
      ]
    },
  };

  // Data for AI services - each service has API key information
  final Map<String, Map<String, dynamic>> _aiServices = {
    '1': {
      'id': '1',
      'name': 'OpenAI',
      'lastModified': DateTime.now().subtract(const Duration(hours: 1)),
      'keys': [
        {'id': '1-1', 'name': 'API Key', 'value': 'sk-abcdefghijklmnopqrstuvwxyz1234567890', 'type': 'api_key', 'lastModified': DateTime.now().subtract(const Duration(hours: 1))},
      ]
    },
    '2': {
      'id': '2',
      'name': 'Anthropic',
      'lastModified': DateTime.now().subtract(const Duration(hours: 6)),
      'keys': [
        {'id': '2-1', 'name': 'API Key', 'value': 'claude-sk-abcdefghijklmnopqrstuvwxyz', 'type': 'api_key', 'lastModified': DateTime.now().subtract(const Duration(hours: 6))},
      ]
    },
  };

  @override
  Widget build(BuildContext context) {
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
                        color: Colors.white,
                        child: Column(
                          children: [
                            // Scrollable content with structured menu
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // OVERVIEW Section
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'OVERVIEW',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: _currentView == 'dashboard' ? Colors.blue[50] : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: ListTile(
                                              title: const Text(
                                                'Dashboard',
                                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                                              ),
                                              subtitle: const Text(
                                                'Overview & Statistics',
                                                style: TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                              leading: Icon(
                                                Icons.dashboard,
                                                color: _currentView == 'dashboard' ? AppConstants.primaryColor : AppConstants.primaryLight,
                                                size: 20,
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              dense: true,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              onTap: () {
                                                setState(() {
                                                  _currentView = 'dashboard';
                                                  _currentSelectedItem = null;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
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
                                              setState(() {
                                                _currentView = 'projects_overview';
                                                _currentSelectedItem = null;
                                                _expandedSection = _expandedSection == 'projects' ? null : 'projects';
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                              decoration: BoxDecoration(
                                                color: _currentView == 'projects_overview' ? Colors.blue[50] : Colors.transparent,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.folder,
                                                    size: 16,
                                                    color: _currentView == 'projects_overview' ? AppConstants.projectIconColor : AppConstants.primaryLight,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'PROJECTS',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '(${_projects.length})',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: _currentView == 'projects_overview' ? Colors.blue[700] : Colors.grey[600],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Icon(
                                                    _expandedSection == 'projects' ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                                    size: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (_expandedSection == 'projects') ...[
                                            ..._projects.values.map((project) {
                                              final isSelected = _currentSelectedItem == project['id'];
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 4),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? Colors.blue[50] : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: ListTile(
                                                  title: Text(
                                                    project['name'],
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    '${project['keys'].length} API keys',
                                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                  ),
                                                  leading: Icon(
                                                    Icons.folder,
                                                    color: isSelected ? Colors.blue[700] : Colors.blue[600],
                                                    size: 18,
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  dense: true,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      _currentSelectedItem = project['id'];
                                                      _currentSection = 'projects';
                                                      _currentView = 'projects';
                                                    });
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                            const SizedBox(height: 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: ListTile(
                                                title: const Text(
                                                  'Add New Project',
                                                  style: TextStyle(fontSize: 13, color: Color(0xFF0f172a), fontWeight: FontWeight.w500),
                                                ),
                                                leading: Icon(Icons.add, color: const Color(0xFF0f172a), size: 18),
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
                                              setState(() {
                                                _currentView = 'ai_overview';
                                                _currentSelectedItem = null;
                                                _expandedSection = _expandedSection == 'ai' ? null : 'ai';
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                              decoration: BoxDecoration(
                                                color: _currentView == 'ai_overview' ? const Color(0xFF0f172a).withOpacity(0.1) : Colors.transparent,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.auto_awesome,
                                                    size: 16,
                                                    color: _currentView == 'ai_overview' ? AppConstants.aiIconColor : AppConstants.secondaryLight,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'AI SERVICES',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '(${_aiServices.length})',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: _currentView == 'ai_overview' ? const Color(0xFF0f172a) : Colors.grey[600],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Icon(
                                                    _expandedSection == 'ai' ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                                    size: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (_expandedSection == 'ai') ...[
                                            ..._aiServices.values.map((service) {
                                              final isSelected = _currentSelectedItem == service['id'];
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 4),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? const Color(0xFF0f172a).withOpacity(0.1) : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: ListTile(
                                                  title: Text(
                                                    service['name'],
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    '${service['keys'].length} API key${service['keys'].length == 1 ? '' : 's'}',
                                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                  ),
                                                  leading: Icon(
                                                    Icons.auto_awesome,
                                                    color: isSelected ? const Color(0xFF0f172a) : Colors.grey[700],
                                                    size: 18,
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  dense: true,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      _currentSelectedItem = service['id'];
                                                      _currentSection = 'ai';
                                                      _currentView = 'ai';
                                                    });
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                            const SizedBox(height: 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0f172a).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: ListTile(
                                                title: const Text(
                                                  'Add New AI Service',
                                                  style: TextStyle(fontSize: 13, color: Color(0xFF0f172a), fontWeight: FontWeight.w500),
                                                ),
                                                leading: Icon(Icons.add, color: const Color(0xFF0f172a), size: 18),
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
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  top: BorderSide(color: Colors.grey, width: 0.5),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: const Text('Support'),
                                    leading: const Icon(Icons.help, color: Colors.blue),
                                    onTap: () {
                                      setState(() {
                                        _currentView = 'support';
                                        _currentSelectedItem = null;
                                      });
                                    },
                                  ),
                                  ListTile(
                                    title: const Text('Settings'),
                                    leading: const Icon(Icons.settings, color: Colors.grey),
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
  }

  Widget _buildMainContent() {
    if (_currentView == 'dashboard') {
      return _buildDashboardView();
    } else if (_currentView == 'projects_overview') {
      return _buildProjectsOverview();
    } else if (_currentView == 'ai_overview') {
      return _buildAiServicesOverview();
    } else if (_currentView == 'support') {
      return const SupportScreen();
    } else if (_currentSelectedItem != null) {
      if (_currentSection == 'projects') {
        final project = _projects[_currentSelectedItem]!;
        return _buildProjectDetails(project);
      } else {
        final service = _aiServices[_currentSelectedItem]!;
        return _buildAiServiceDetails(service);
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

  Widget _buildProjectDetails(Map<String, dynamic> project) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder, size: 30, color: Colors.blue),
              const SizedBox(width: 10),
              Text(
                project['name'],
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
              itemCount: project['keys'].length,
              itemBuilder: (context, index) {
                final key = project['keys'][index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: _getIconForKeyType(key['type']),
                    title: Text(key['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildKeySubtitle(key),
                        Text(
                          'Modified ${_formatLastModified(key['lastModified'])}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.copy, color: AppConstants.copyIconColor),
                          onPressed: () => _copyToClipboard(key['value']),
                          tooltip: 'Copy to clipboard',
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: AppConstants.editIconColor),
                          onPressed: () => _startEditingKey(key),
                          tooltip: 'Edit value',
                        ),
                        if (key['type'] == 'password')
                          IconButton(
                            icon: Icon(
                              _visiblePasswords[key['id']] ?? false
                                ? Icons.visibility_off
                                : Icons.visibility
                            ),
                            onPressed: () => _togglePasswordVisibility(key),
                            tooltip: (_visiblePasswords[key['id']] ?? false)
                              ? 'Hide password'
                              : 'Show password',
                          ),
                        IconButton(
                          icon: Icon(Icons.delete, color: AppConstants.deleteIconColor),
                          onPressed: () => _deleteKey(project['id'], key['id']),
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
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddKeyDialog(project['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add New Key'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _generatePassword(project['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.successColor,
                  foregroundColor: Colors.white,
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

  Widget _buildAiServiceDetails(Map<String, dynamic> service) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 30, color: Colors.purple),
              const SizedBox(width: 10),
              Text(
                service['name'],
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
              itemCount: service['keys'].length,
              itemBuilder: (context, index) {
                final key = service['keys'][index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.key, color: Colors.purple),
                    title: Text(key['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildKeySubtitle(key),
                        if (key['lastModified'] != null)
                          Text(
                            'Modified ${_formatLastModified(key['lastModified'])}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.copy, color: AppConstants.copyIconColor),
                          onPressed: () => _copyToClipboard(key['value']),
                          tooltip: 'Copy to clipboard',
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: AppConstants.editIconColor),
                          onPressed: () => _startEditingKey(key),
                          tooltip: 'Edit value',
                        ),
                        if (key['type'] == 'password')
                          IconButton(
                            icon: Icon(
                              _visiblePasswords[key['id']] ?? false
                                ? Icons.visibility_off
                                : Icons.visibility
                            ),
                            onPressed: () => _togglePasswordVisibility(key),
                            tooltip: (_visiblePasswords[key['id']] ?? false)
                              ? 'Hide password'
                              : 'Show password',
                          ),
                        IconButton(
                          icon: Icon(Icons.delete, color: AppConstants.deleteIconColor),
                          onPressed: () => _deleteKey(service['id'], key['id']),
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
            onPressed: () => _showAddKeyDialog(service['id']),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.secondaryColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add New Key'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView() {
    // Calculate stats
    final totalProjects = _projects.length;
    final totalAiServices = _aiServices.length;
    final totalKeys = _projects.values.fold(0, (sum, project) => sum + (project['keys'] as List).length) +
                      _aiServices.values.fold(0, (sum, service) => sum + (service['keys'] as List).length);

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
                          Icon(Icons.folder, size: 40, color: AppConstants.projectIconColor),
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
                          Icon(Icons.auto_awesome, size: 40, color: AppConstants.aiIconColor),
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
                      backgroundColor: AppConstants.secondaryColor,
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
                                    color: item['type'] == 'project' ? Colors.blue : const Color(0xFF0f172a),
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
            backgroundColor: Colors.blue,
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
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder, size: 32, color: Colors.blue),
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
            if (_projects.isEmpty)
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
                        backgroundColor: Colors.blue,
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
                itemCount: _projects.length,
                itemBuilder: (context, index) {
                  final project = _projects.values.elementAt(index);
                  return Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        _trackRecentlyUsed('project', project['id'], project['name']);
                        setState(() {
                          _currentSelectedItem = project['id'];
                          _currentSection = 'projects';
                          _currentView = 'projects';
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.folder, color: Colors.blue[600], size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    project['name'],
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
                            Text(
                              '${project['keys'].length} API key${project['keys'].length == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
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
                  backgroundColor: Colors.blue,
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
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 32, color: const Color(0xFF0f172a)),
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
            if (_aiServices.isEmpty)
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
                        backgroundColor: const Color(0xFF0f172a),
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
                itemCount: _aiServices.length,
                itemBuilder: (context, index) {
                  final service = _aiServices.values.elementAt(index);
                  return Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        _trackRecentlyUsed('ai_service', service['id'], service['name']);
                        setState(() {
                          _currentSelectedItem = service['id'];
                          _currentSection = 'ai';
                          _currentView = 'ai';
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome, color: const Color(0xFF0f172a), size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    service['name'],
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
                            Text(
                              '${service['keys'].length} API key${service['keys'].length == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
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
                  backgroundColor: const Color(0xFF0f172a),
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
            style: const TextStyle(fontFamily: 'monospace', color: Colors.blue),
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
          style: const TextStyle(color: Colors.blue),
        ),
      );
    }
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
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editing: ${key['name']}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    color: Color(0xFF0f172a), // Navy dark blue
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: AppConstants.primaryColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: AppConstants.primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
                    ),
                  ),
                  onSubmitted: (value) => _saveKeyValue(key, value),
                  maxLines: key['type'] == 'password' ? 1 : 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green, size: 24),
                    onPressed: () => _saveKeyValue(key, controller.text),
                    tooltip: 'Save changes',
                    padding: const EdgeInsets.all(8),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 24),
                    onPressed: () => _cancelEditingKey(key),
                    tooltip: 'Cancel editing',
                    padding: const EdgeInsets.all(8),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
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

  void _togglePasswordVisibility(Map<String, dynamic> key) {
    setState(() {
      String keyId = key['id'];
      // Toggle the visibility state for this specific password
      _visiblePasswords[keyId] = !(_visiblePasswords[keyId] ?? false);
    });

    // Show feedback about the toggle
    bool isNowVisible = _visiblePasswords[key['id']] ?? false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isNowVisible ? 'Password revealed' : 'Password hidden'
        ),
        duration: const Duration(seconds: 1),
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

  void _deleteKey(String parentId, String keyId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete API Key'),
          content: const Text(
            'Are you sure you want to delete this API key? This action cannot be undone.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_currentSection == 'projects') {
                    final project = _projects[parentId]!;
                    project['keys'].removeWhere((key) => key['id'] == keyId);
                  } else {
                    final service = _aiServices[parentId]!;
                    service['keys'].removeWhere((key) => key['id'] == keyId);
                  }
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('API key deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newId = (DateTime.now().millisecondsSinceEpoch).toString();
                  setState(() {
                    _projects[newId] = {
                      'id': newId,
                      'name': nameController.text,
                      'keys': [],
                    };
                  });
                  Navigator.of(context).pop();
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
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newId = (DateTime.now().millisecondsSinceEpoch).toString();
                  setState(() {
                    _aiServices[newId] = {
                      'id': newId,
                      'name': nameController.text,
                      'keys': [],
                    };
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddKeyDialog(String parentId) {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    String keyType = 'api_key';

    // Check if we're in a specific project/service view (not dashboard)
    final isInSpecificView = _currentSelectedItem != null && _currentView != 'dashboard';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isInSpecificView ? 'Add New API Key' : (_currentSection == 'projects' ? 'Add New Key' : 'Add New API Key')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Only show name field if we're NOT in a specific project/service view
              if (!isInSpecificView) ...[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Key Name',
                    hintText: 'Enter key name',
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: isInSpecificView ? 'API Key Value' : (_currentSection == 'projects' ? 'Key Value' : 'API Key'),
                  hintText: isInSpecificView ? 'Enter API key value' : (_currentSection == 'projects' ? 'Enter key value' : 'Enter API key'),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: keyType,
                decoration: const InputDecoration(labelText: 'Key Type'),
                items: const [
                  DropdownMenuItem(value: 'api_key', child: Text('API Key')),
                  DropdownMenuItem(value: 'password', child: Text('Password')),
                  DropdownMenuItem(value: 'url', child: Text('URL')),
                  DropdownMenuItem(value: 'connection_string', child: Text('Connection String')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    keyType = value;
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
            TextButton(
              onPressed: () {
                // Validation depends on context
                final hasName = isInSpecificView || nameController.text.isNotEmpty;
                final hasValue = valueController.text.isNotEmpty;

                if (hasName && hasValue) {
                  final newKeyId = '${parentId}-${DateTime.now().millisecondsSinceEpoch}';

                  // Auto-generate name if we're in specific view
                  final keyName = isInSpecificView
                    ? '${keyType.replaceAll('_', ' ').toUpperCase()} ${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
                    : nameController.text;

                  final newKey = {
                    'id': newKeyId,
                    'name': keyName,
                    'value': valueController.text,
                    'type': keyType,
                    'lastModified': DateTime.now(),
                  };

                  setState(() {
                    if (_currentSection == 'projects') {
                      _projects[parentId]!['keys'].add(newKey);
                    } else {
                      _aiServices[parentId]!['keys'].add(newKey);
                    }
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _generatePassword(String projectId) {
    // Generate a random password
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    final password = List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
    
    final newKeyId = '${projectId}-${DateTime.now().millisecondsSinceEpoch}';
    final newPassword = {
      'id': newKeyId,
      'name': 'Generated Password ${DateTime.now().second}',
      'value': password,
      'type': 'password',
      'lastModified': DateTime.now(),
    };
    
    setState(() {
      _projects[projectId]!['keys'].add(newPassword);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password generated and added')),
    );
  }

  void _showEditProjectDialog(Map<String, dynamic> project) {
    final nameController = TextEditingController(text: project['name']);
    
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
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    project['name'] = nameController.text;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditAiServiceDialog(Map<String, dynamic> service) {
    final nameController = TextEditingController(text: service['name']);
    
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
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    service['name'] = nameController.text;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}