import 'package:flutter/material.dart';
import '../widgets/adaptive_form.dart';
import '../widgets/adaptive_card.dart';
import '../services/responsive_service.dart';
import '../utils/constants.dart';

class CredentialFormScreen extends StatefulWidget {
  final String? credentialId;
  final bool isEditing;

  const CredentialFormScreen({
    super.key,
    this.credentialId,
    this.isEditing = false,
  });

  @override
  State<CredentialFormScreen> createState() => _CredentialFormScreenState();
}

class _CredentialFormScreenState extends State<CredentialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'General';
  DateTime? _expiryDate;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _categories = [
    'General',
    'Social Media',
    'Banking',
    'Email',
    'Work',
    'Shopping',
    'Entertainment',
    'Development',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.credentialId != null) {
      _loadCredential();
    }
  }

  void _loadCredential() {
    // TODO: Load credential data from storage
    // For now, just set some sample data
    _nameController.text = 'Sample Credential';
    _usernameController.text = 'user@example.com';
    _passwordController.text = 'samplepassword';
    _urlController.text = 'https://example.com';
    _notesController.text = 'Sample notes';
    _selectedCategory = 'General';
    _expiryDate = DateTime.now().add(const Duration(days: 365));
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

  @override
  Widget build(BuildContext context) {
    final shouldUseFullScreen = ResponsiveService.shouldUseFullScreenDialog(context);

    if (shouldUseFullScreen) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: _buildForm(),
      );
    } else {
      return AdaptiveDialog(
        title: widget.isEditing ? 'Edit Credential' : 'Add Credential',
        child: _buildForm(),
        actions: [
          AdaptiveFormButton(
            text: 'Cancel',
            isPrimary: false,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          AdaptiveFormButton(
            text: widget.isEditing ? 'Update' : 'Save',
            isLoading: _isLoading,
            onPressed: _saveCredential,
          ),
        ],
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.isEditing ? 'Edit Credential' : 'Add Credential'),
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      actions: [
        if (ResponsiveService.isMobile(context))
          TextButton(
            onPressed: _saveCredential,
            child: Text(
              widget.isEditing ? 'UPDATE' : 'SAVE',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildForm() {
    return AdaptiveForm(
      formKey: _formKey,
      onRefresh: widget.isEditing ? _loadCredential : null,
      children: [
        // Basic Information Section
        AdaptiveText(
          'Basic Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppConstants.primaryColor,
          ),
        ),
        
        AdaptiveTextFormField(
          labelText: 'Name *',
          hintText: 'Enter credential name',
          controller: _nameController,
          prefixIcon: const Icon(Icons.label),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a name';
            }
            return null;
          },
        ),

        AdaptiveDropdownFormField<String>(
          labelText: 'Category',
          value: _selectedCategory,
          prefixIcon: const Icon(Icons.category),
          items: _categories.map((category) => DropdownMenuItem(
            value: category,
            child: Text(category),
          )).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
        ),

        AdaptiveTextFormField(
          labelText: 'Website/URL',
          hintText: 'https://example.com',
          controller: _urlController,
          prefixIcon: const Icon(Icons.link),
          keyboardType: TextInputType.url,
        ),

        // Credentials Section
        const SizedBox(height: 16),
        AdaptiveText(
          'Credentials',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppConstants.primaryColor,
          ),
        ),

        AdaptiveTextFormField(
          labelText: 'Username/Email *',
          hintText: 'Enter username or email',
          controller: _usernameController,
          prefixIcon: const Icon(Icons.person),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter username or email';
            }
            return null;
          },
        ),

        AdaptiveTextFormField(
          labelText: 'Password *',
          hintText: 'Enter password',
          controller: _passwordController,
          prefixIcon: const Icon(Icons.lock),
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            return null;
          },
        ),

        // Additional Information Section
        const SizedBox(height: 16),
        AdaptiveText(
          'Additional Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppConstants.primaryColor,
          ),
        ),

        AdaptiveDatePickerField(
          labelText: 'Expiry Date (Optional)',
          selectedDate: _expiryDate,
          onDateSelected: (date) {
            setState(() {
              _expiryDate = date;
            });
          },
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
        ),

        AdaptiveTextFormField(
          labelText: 'Notes',
          hintText: 'Additional notes (optional)',
          controller: _notesController,
          prefixIcon: const Icon(Icons.notes),
          maxLines: 3,
        ),

        // Action Buttons (for mobile full-screen mode)
        if (ResponsiveService.shouldUseFullScreenDialog(context)) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AdaptiveFormButton(
                  text: 'Cancel',
                  isPrimary: false,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdaptiveFormButton(
                  text: widget.isEditing ? 'Update' : 'Save',
                  isLoading: _isLoading,
                  onPressed: _saveCredential,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _saveCredential() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Save credential to storage
      await Future.delayed(const Duration(seconds: 1)); // Simulate save

      if (mounted) {
        ResponsiveService.triggerHeavyHaptic();
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving credential: $e'),
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
}
