import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../data/auth_service.dart';
import '../validators/auth_validators.dart';
import '../widgets/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await AuthService.registerUser(
        username: _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Allow location to continue.')),
      );
      Navigator.of(context).pushReplacementNamed(AppRoutes.locationSetup);
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Selve vinagam'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 38,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _RegisterHeader(),
                          const SizedBox(height: 24),
                          AuthTextField(
                            controller: _usernameController,
                            label: 'Username',
                            validator: AuthValidators.validateUsername,
                            prefixIcon: const Icon(
                              Icons.account_circle_outlined,
                            ),
                            focusNode: _usernameFocusNode,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            onFieldSubmitted: (_) =>
                                _phoneFocusNode.requestFocus(),
                          ),
                          const SizedBox(height: 14),
                          AuthTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            keyboardType: TextInputType.phone,
                            validator: AuthValidators.validatePhone,
                            prefixIcon: const Icon(Icons.phone_outlined),
                            focusNode: _phoneFocusNode,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            onFieldSubmitted: (_) =>
                                _emailFocusNode.requestFocus(),
                          ),
                          const SizedBox(height: 14),
                          AuthTextField(
                            controller: _emailController,
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: AuthValidators.validateEmail,
                            prefixIcon: const Icon(Icons.mail_outline),
                            focusNode: _emailFocusNode,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.username,
                              AutofillHints.email,
                            ],
                            onFieldSubmitted: (_) =>
                                _passwordFocusNode.requestFocus(),
                          ),
                          const SizedBox(height: 14),
                          AuthTextField(
                            controller: _passwordController,
                            label: 'Password',
                            obscureText: _obscurePassword,
                            validator: AuthValidators.validatePassword,
                            prefixIcon: const Icon(Icons.lock_outline),
                            focusNode: _passwordFocusNode,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            onFieldSubmitted: (_) =>
                                _confirmPasswordFocusNode.requestFocus(),
                            suffixIcon: IconButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          AuthTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm password',
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              return AuthValidators.validateConfirmPassword(
                                value,
                                _passwordController.text,
                              );
                            },
                            prefixIcon: const Icon(
                              Icons.verified_user_outlined,
                            ),
                            focusNode: _confirmPasswordFocusNode,
                            autofillHints: const [AutofillHints.newPassword],
                            onFieldSubmitted: (_) => _submitRegister(),
                            suffixIcon: IconButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => setState(
                                      () => _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                    ),
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _submitRegister,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Create account'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already registered?',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        FocusScope.of(context).unfocus();
                                        Navigator.of(
                                          context,
                                        ).pushReplacementNamed(AppRoutes.login);
                                      },
                                child: const Text('Sign in'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F2FF),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.person_add_alt_1_outlined,
            color: Color(0xFF007AFF),
            size: 34,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Selve vinagam',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
