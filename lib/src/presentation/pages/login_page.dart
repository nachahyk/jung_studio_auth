import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../controllers/auth_cubit.dart';
import '../controllers/auth_state.dart';
import 'login_page_strings.dart';

/// The one shared sign-in/sign-up screen every mini-app reuses. Deliberately
/// themed via ambient `Theme.of(context)` rather than any one app's static
/// color constants, so each mini-app's own `ThemeData` (built via
/// `design_system`'s `buildAppTheme`) drives how this page looks — [appName]/
/// [appIcon] and [strings] are the only per-app customization points,
/// supplied by the caller rather than hardcoded here.
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.appName,
    this.appIcon = Icons.storefront_outlined,
    this.maxContentWidth = 480,
    required this.strings,
  });

  final String appName;
  final IconData appIcon;
  final double maxContentWidth;
  final LoginPageStrings strings;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSignUp = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isSubmitting = true);
    await action();
    if (mounted) setState(() => _isSubmitting = false);
  }

  void _submitEmailPassword(AuthCubit authCubit) {
    if (_isSignUp && !_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!_isSignUp) {
      _run(() => authCubit.signInWithEmailPassword(email, password));
      return;
    }

    _run(() async {
      final needsConfirmation = await authCubit.signUpWithEmailPassword(
        email,
        password,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      if (needsConfirmation && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.strings.confirmEmailSent)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final strings = widget.strings;

    return Scaffold(
      body: BlocListener<AuthCubit, AppAuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(widget.appIcon, size: 56, color: colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        widget.appName,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isSignUp ? strings.signUpSubtitle : strings.signInSubtitle,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      if (_isSignUp) ...[
                        TextFormField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            labelText: strings.fullNameLabel,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? strings.fullNameRequired : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: strings.phoneLabel,
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: strings.addressLabel,
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: strings.emailLabel,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: strings.passwordLabel,
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _submitEmailPassword(authCubit),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary),
                              )
                            : Text(_isSignUp ? strings.createAccountButton : strings.signInButton),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _isSubmitting ? null : () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(_isSignUp ? strings.toggleToSignIn : strings.toggleToSignUp),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _isSubmitting ? null : () => _run(authCubit.signInAnonymously),
                        child: Text(strings.continueAsGuest),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
