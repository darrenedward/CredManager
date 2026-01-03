import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AuthForm extends StatefulWidget {
  final String title;
  final TextEditingController controller;
  final TextEditingController? confirmController;
  final VoidCallback? onSubmit;
  final bool isSetup;
  final bool isLoading;
  final String? errorMessage;

  const AuthForm({
    super.key,
    required this.title,
    required this.controller,
    this.confirmController,
    this.onSubmit,
    this.isSetup = false,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          obscureText: _isObscure,
          enabled: !widget.isLoading,
          decoration: InputDecoration(
            labelText: widget.title,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _isObscure ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _isObscure = !_isObscure;
                });
              },
            ),
            errorText: widget.errorMessage,
          ),
          onSubmitted: (_) => widget.onSubmit?.call(),
        ),
        if (widget.isSetup && widget.confirmController != null) ...[
          const SizedBox(height: 10),
          TextField(
            controller: widget.confirmController,
            obscureText: _isObscure,
            enabled: !widget.isLoading,
            decoration: const InputDecoration(
              labelText: 'Confirm Passphrase',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => widget.onSubmit?.call(),
          ),
        ],
        if (widget.onSubmit != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: widget.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Continue'),
            ),
          ),
        ],
        const SizedBox(height: 10), // Always add bottom spacing
      ],
    );
  }
}
