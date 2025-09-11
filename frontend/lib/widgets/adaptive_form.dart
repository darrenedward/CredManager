import 'package:flutter/material.dart';
import '../services/responsive_service.dart';
import '../services/biometric_auth_service.dart';
import '../utils/constants.dart';

/// Adaptive form that adjusts layout and spacing based on screen size
class AdaptiveForm extends StatelessWidget {
  final GlobalKey<FormState>? formKey;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final bool enableKeyboardAvoidance;
  final VoidCallback? onRefresh;

  const AdaptiveForm({
    super.key,
    this.formKey,
    required this.children,
    this.padding,
    this.enableKeyboardAvoidance = true,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveService.getResponsivePadding(context);
    final shouldEnablePullToRefresh = ResponsiveService.shouldEnablePullToRefresh(context);

    Widget formContent = Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildFormChildren(context),
      ),
    );

    Widget scrollableContent = SingleChildScrollView(
      padding: responsivePadding,
      child: formContent,
    );

    // Add pull-to-refresh if enabled and callback provided
    if (shouldEnablePullToRefresh && onRefresh != null) {
      scrollableContent = RefreshIndicator(
        onRefresh: () async {
          onRefresh!();
        },
        child: scrollableContent,
      );
    }

    return scrollableContent;
  }

  List<Widget> _buildFormChildren(BuildContext context) {
    final spacing = ResponsiveService.isMobile(context) ? 16.0 : 12.0;
    final List<Widget> formChildren = [];

    for (int i = 0; i < children.length; i++) {
      formChildren.add(children[i]);
      
      // Add spacing between children (except after the last one)
      if (i < children.length - 1) {
        formChildren.add(SizedBox(height: spacing));
      }
    }

    return formChildren;
  }
}

/// Adaptive text form field with responsive sizing and spacing
class AdaptiveTextFormField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;

  const AdaptiveTextFormField({
    super.key,
    this.labelText,
    this.hintText,
    this.helperText,
    this.controller,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final minTapTarget = ResponsiveService.getMinTapTargetSize(context);
    final isMobile = ResponsiveService.isMobile(context);

    return Container(
      constraints: BoxConstraints(
        minHeight: minTapTarget,
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        onSaved: onSaved,
        onChanged: onChanged,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        maxLines: maxLines,
        maxLength: maxLength,
        onTap: onTap,
        style: TextStyle(
          fontSize: isMobile ? 16.0 : 14.0, // Larger text on mobile
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12.0 : 8.0),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16.0 : 12.0,
            vertical: isMobile ? 16.0 : 12.0,
          ),
        ),
      ),
    );
  }
}

/// Adaptive dropdown form field with responsive sizing
class AdaptiveDropdownFormField<T> extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final void Function(T?)? onSaved;
  final Widget? prefixIcon;

  const AdaptiveDropdownFormField({
    super.key,
    this.labelText,
    this.hintText,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final minTapTarget = ResponsiveService.getMinTapTargetSize(context);
    final isMobile = ResponsiveService.isMobile(context);

    return Container(
      constraints: BoxConstraints(
        minHeight: minTapTarget,
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        onSaved: onSaved,
        style: TextStyle(
          fontSize: isMobile ? 16.0 : 14.0,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12.0 : 8.0),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16.0 : 12.0,
            vertical: isMobile ? 16.0 : 12.0,
          ),
        ),
      ),
    );
  }
}

/// Adaptive date picker field
class AdaptiveDatePickerField extends StatelessWidget {
  final String? labelText;
  final DateTime? selectedDate;
  final void Function(DateTime) onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? Function(DateTime?)? validator;
  final Widget? prefixIcon;

  const AdaptiveDatePickerField({
    super.key,
    this.labelText,
    this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final minTapTarget = ResponsiveService.getMinTapTargetSize(context);
    final isMobile = ResponsiveService.isMobile(context);

    return Container(
      constraints: BoxConstraints(
        minHeight: minTapTarget,
      ),
      child: TextFormField(
        readOnly: true,
        onTap: () async {
          ResponsiveService.triggerLightHaptic();
          
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: firstDate ?? DateTime(1900),
            lastDate: lastDate ?? DateTime(2100),
          );
          
          if (picked != null) {
            onDateSelected(picked);
          }
        },
        validator: (value) => validator?.call(selectedDate),
        style: TextStyle(
          fontSize: isMobile ? 16.0 : 14.0,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: selectedDate != null 
              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
              : 'Select date',
          prefixIcon: prefixIcon ?? const Icon(Icons.calendar_today),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12.0 : 8.0),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16.0 : 12.0,
            vertical: isMobile ? 16.0 : 12.0,
          ),
        ),
      ),
    );
  }
}

/// Adaptive form button with responsive sizing
class AdaptiveFormButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final Widget? icon;

  const AdaptiveFormButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final minTapTarget = ResponsiveService.getMinTapTargetSize(context);
    final isMobile = ResponsiveService.isMobile(context);

    Widget buttonChild = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: isMobile ? 16.0 : 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    return Container(
      constraints: BoxConstraints(
        minHeight: minTapTarget,
        minWidth: isMobile ? double.infinity : 120,
      ),
      child: isPrimary
          ? ElevatedButton(
              onPressed: isLoading ? null : () {
                ResponsiveService.triggerHapticFeedback();
                onPressed?.call();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24.0 : 16.0,
                  vertical: isMobile ? 16.0 : 12.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 12.0 : 8.0),
                ),
              ),
              child: buttonChild,
            )
          : OutlinedButton(
              onPressed: isLoading ? null : () {
                ResponsiveService.triggerLightHaptic();
                onPressed?.call();
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24.0 : 16.0,
                  vertical: isMobile ? 16.0 : 12.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 12.0 : 8.0),
                ),
              ),
              child: buttonChild,
            ),
    );
  }
}

/// Biometric authentication prompt widget
class BiometricAuthPrompt extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBiometricSuccess;
  final VoidCallback? onPassphraseFallback;
  final VoidCallback? onCancel;

  const BiometricAuthPrompt({
    super.key,
    this.title = 'Authenticate',
    this.subtitle = 'Use your biometric to authenticate',
    this.onBiometricSuccess,
    this.onPassphraseFallback,
    this.onCancel,
  });

  @override
  State<BiometricAuthPrompt> createState() => _BiometricAuthPromptState();
}

class _BiometricAuthPromptState extends State<BiometricAuthPrompt> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  bool _isAuthenticating = false;
  String _biometricType = 'Biometric';

  @override
  void initState() {
    super.initState();
    _loadBiometricType();
    _authenticateWithBiometric();
  }

  void _loadBiometricType() async {
    final type = await _biometricService.getPrimaryBiometricType();
    if (mounted) {
      setState(() {
        _biometricType = type;
      });
    }
  }

  void _authenticateWithBiometric() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final result = await _biometricService.authenticateWithBiometrics(
        localizedReason: widget.subtitle,
      );

      if (mounted) {
        if (result.success) {
          ResponsiveService.triggerHeavyHaptic();
          widget.onBiometricSuccess?.call();
        } else {
          setState(() {
            _isAuthenticating = false;
          });

          // Show error or fallback based on error type
          if (result.errorType == BiometricAuthError.userCancel) {
            widget.onCancel?.call();
          } else {
            _showErrorAndFallback(result.errorMessage ?? 'Authentication failed');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
        _showErrorAndFallback('Authentication error: $e');
      }
    }
  }

  void _showErrorAndFallback(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Use Passphrase',
          textColor: Colors.white,
          onPressed: () {
            widget.onPassphraseFallback?.call();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveService.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 24.0 : 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Biometric icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getBiometricIcon(),
              size: 40,
              color: AppConstants.primaryColor,
            ),
          ),

          const SizedBox(height: 24),

          // Title
          AdaptiveText(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          AdaptiveText(
            widget.subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Authentication status
          if (_isAuthenticating) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            AdaptiveText(
              'Authenticating with $_biometricType...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else ...[
            AdaptiveFormButton(
              text: 'Try $_biometricType Again',
              onPressed: _authenticateWithBiometric,
              icon: Icon(_getBiometricIcon()),
            ),
          ],

          const SizedBox(height: 16),

          // Fallback options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: widget.onPassphraseFallback,
                child: const AdaptiveText('Use Passphrase'),
              ),
              TextButton(
                onPressed: widget.onCancel,
                child: const AdaptiveText('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getBiometricIcon() {
    switch (_biometricType.toLowerCase()) {
      case 'face id':
        return Icons.face;
      case 'fingerprint':
        return Icons.fingerprint;
      case 'iris':
        return Icons.visibility;
      default:
        return Icons.security;
    }
  }
}
