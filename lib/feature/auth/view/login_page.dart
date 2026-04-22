import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/core/constants/app_colors.dart';
import 'package:talk_gym/core/navigation/app_routes.dart';
import 'package:talk_gym/feature/auth/view/widgets/auth_ui.dart';
import 'package:talk_gym/feature/auth/viewmodel/auth_bloc.dart';
import 'package:talk_gym/feature/auth/viewmodel/auth_validators.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _submitAttempted = false;
  bool _usernameTouched = false;
  bool _passwordTouched = false;
  bool _obscurePassword = true;
  String? _errorBanner;

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(_onUsernameFocusChanged);
    _passwordFocusNode.addListener(_onPasswordFocusChanged);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onUsernameFocusChanged() {
    if (!_usernameFocusNode.hasFocus) {
      setState(() {
        _usernameTouched = true;
      });
    }
  }

  void _onPasswordFocusChanged() {
    if (!_passwordFocusNode.hasFocus) {
      setState(() {
        _passwordTouched = true;
      });
    }
  }

  String? get _usernameError {
    final bool shouldShow = _submitAttempted || _usernameTouched;
    if (!shouldShow) {
      return null;
    }
    return AuthValidators.validateUsernameOrEmail(_usernameController.text);
  }

  String? get _passwordError {
    final bool shouldShow = _submitAttempted || _passwordTouched;
    if (!shouldShow) {
      return null;
    }
    return AuthValidators.validatePassword(_passwordController.text);
  }

  bool get _isFormValid {
    return AuthValidators.validateUsernameOrEmail(_usernameController.text) == null &&
        AuthValidators.validatePassword(_passwordController.text) == null;
  }

  void _submit() {
    setState(() {
      _submitAttempted = true;
      _usernameTouched = true;
      _passwordTouched = true;
      _errorBanner = null;
    });

    if (!_isFormValid) {
      HapticFeedback.heavyImpact();
      if (AuthValidators.validateUsernameOrEmail(_usernameController.text) != null) {
        _usernameFocusNode.requestFocus();
      } else {
        _passwordFocusNode.requestFocus();
      }
      return;
    }

    HapticFeedback.lightImpact();
    context.read<AuthBloc>().add(
      LoginSubmitted(
        usernameOrEmail: _usernameController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  Future<void> _showGoogleBottomSheet() async {
    final bool? proceed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Google Sign In',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This will be integrated with Firebase/Google Sign In. For now, demo mode: tap Continue to mock login.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              AuthPrimaryButton(
                label: 'Continue',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
    );

    if (proceed == true && mounted) {
      HapticFeedback.lightImpact();
      context.read<AuthBloc>().add(const GoogleAuthRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (BuildContext context, AuthState state) async {
        if (state is AuthError) {
          HapticFeedback.heavyImpact();
          setState(() {
            _errorBanner = state.message;
          });
        }

        if (state is Authenticated) {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (Route<dynamic> route) => false);
        }
      },
      builder: (BuildContext context, AuthState state) {
        final bool isLoading = state is AuthLoading || state is GoogleAuthLoading;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const AuthAnimatedItem(
                    delay: Duration(milliseconds: 50),
                    child: AuthLogoHeader(
                      title: 'Welcome Back',
                      subtitle: 'Sign in to continue your interview training',
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_errorBanner != null) ...<Widget>[
                    AuthTopErrorBanner(
                      message: _errorBanner!,
                      onClose: () => setState(() => _errorBanner = null),
                    ),
                    const SizedBox(height: 12),
                  ],
                  AuthAnimatedItem(
                    delay: const Duration(milliseconds: 100),
                    child: _AuthInputField(
                      enabled: !isLoading,
                      semanticLabel: 'Email or username field',
                      label: 'Email or Username',
                      controller: _usernameController,
                      focusNode: _usernameFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                    ),
                  ),
                  if (_usernameError != null) AuthInlineErrorText(_usernameError!),
                  const SizedBox(height: 12),
                  AuthAnimatedItem(
                    delay: const Duration(milliseconds: 150),
                    child: _AuthInputField(
                      enabled: !isLoading,
                      semanticLabel: _obscurePassword ? 'Password field, hidden' : 'Password field, visible',
                      label: 'Password',
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _submit(),
                      suffix: IconButton(
                        onPressed: isLoading
                            ? null
                            : () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  if (_passwordError != null) AuthInlineErrorText(_passwordError!),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    button: true,
                    label: 'Sign in button',
                    child: AuthPrimaryButton(
                      label: 'Sign In',
                      isLoading: state is AuthLoading,
                      onPressed: _isFormValid && !isLoading ? _submit : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const AuthDivider(),
                  const SizedBox(height: 20),
                  AuthGoogleButton(
                    label: 'Sign in with Google',
                    onPressed: isLoading ? null : _showGoogleBottomSheet,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Don\'t have an account? ',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      InkWell(
                        onTap: isLoading
                            ? null
                            : () => Navigator.of(context).pushNamed(AppRoutes.signUp),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Master behavioral interviews with AI coaching',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuthInputField extends StatelessWidget {
  const _AuthInputField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.semanticLabel,
    this.keyboardType,
    this.textInputAction,
    this.suffix,
    this.onSubmitted,
    this.onChanged,
    this.obscureText = false,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String semanticLabel;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffix;
  final bool obscureText;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            enabled: enabled,
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            obscureText: obscureText,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            onChanged: onChanged,
            decoration: InputDecoration(
              suffixIcon: suffix,
              filled: true,
              fillColor: AppColors.cardBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
