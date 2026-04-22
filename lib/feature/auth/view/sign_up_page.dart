import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/core/constants/app_colors.dart';
import 'package:talk_gym/core/navigation/app_routes.dart';
import 'package:talk_gym/feature/auth/view/widgets/auth_ui.dart';
import 'package:talk_gym/feature/auth/viewmodel/auth_bloc.dart';
import 'package:talk_gym/feature/auth/viewmodel/auth_validators.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();
  final FocusNode _referralFocusNode = FocusNode();

  bool _submitAttempted = false;
  bool _usernameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _confirmTouched = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _showReferral = false;

  bool _checkingUsername = false;
  bool? _isUsernameAvailable;
  String? _errorBanner;

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(_onUsernameFocusChanged);
    _emailFocusNode.addListener(_onEmailFocusChanged);
    _passwordFocusNode.addListener(_onPasswordFocusChanged);
    _confirmFocusNode.addListener(_onConfirmFocusChanged);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _referralController.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    _referralFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onUsernameFocusChanged() async {
    if (_usernameFocusNode.hasFocus) {
      return;
    }

    setState(() {
      _usernameTouched = true;
    });

    if (AuthValidators.validateUsername(_usernameController.text) != null) {
      return;
    }

    await _checkUsernameAvailability(_usernameController.text);
  }

  void _onEmailFocusChanged() {
    if (!_emailFocusNode.hasFocus) {
      setState(() {
        _emailTouched = true;
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

  void _onConfirmFocusChanged() {
    if (!_confirmFocusNode.hasFocus) {
      setState(() {
        _confirmTouched = true;
      });
    }
  }

  Future<void> _checkUsernameAvailability(String value) async {
    setState(() {
      _checkingUsername = true;
      _isUsernameAvailable = null;
    });

    final bool available = await context.read<AuthBloc>().repository.isUsernameAvailable(value.trim());
    if (!mounted) {
      return;
    }

    setState(() {
      _checkingUsername = false;
      _isUsernameAvailable = available;
    });
  }

  String? get _usernameError {
    final bool shouldShow = _submitAttempted || _usernameTouched;
    if (!shouldShow) {
      return null;
    }

    final String? validationError = AuthValidators.validateUsername(_usernameController.text);
    if (validationError != null) {
      return validationError;
    }

    if (_isUsernameAvailable == false) {
      return 'Username already exists';
    }

    return null;
  }

  String? get _emailError {
    if (!(_submitAttempted || _emailTouched)) {
      return null;
    }
    return AuthValidators.validateEmail(_emailController.text);
  }

  String? get _passwordError {
    if (!(_submitAttempted || _passwordTouched)) {
      return null;
    }
    return AuthValidators.validatePassword(_passwordController.text);
  }

  String? get _confirmError {
    if (!(_submitAttempted || _confirmTouched)) {
      return null;
    }
    return AuthValidators.validateConfirmPassword(_passwordController.text, _confirmController.text);
  }

  bool get _isFormValid {
    return AuthValidators.validateUsername(_usernameController.text) == null &&
        AuthValidators.validateEmail(_emailController.text) == null &&
        AuthValidators.validatePassword(_passwordController.text) == null &&
        AuthValidators.validateConfirmPassword(_passwordController.text, _confirmController.text) == null &&
        _isUsernameAvailable != false;
  }

  String get _passwordStrengthLabel {
    final PasswordStrength strength = AuthValidators.passwordStrength(_passwordController.text);
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  void _submit() {
    setState(() {
      _submitAttempted = true;
      _usernameTouched = true;
      _emailTouched = true;
      _passwordTouched = true;
      _confirmTouched = true;
      _errorBanner = null;
    });

    if (!_isFormValid) {
      HapticFeedback.heavyImpact();
      if (_usernameError != null) {
        _usernameFocusNode.requestFocus();
      } else if (_emailError != null) {
        _emailFocusNode.requestFocus();
      } else if (_passwordError != null) {
        _passwordFocusNode.requestFocus();
      } else {
        _confirmFocusNode.requestFocus();
      }
      return;
    }

    HapticFeedback.lightImpact();
    context.read<AuthBloc>().add(
      SignUpSubmitted(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirm: _confirmController.text,
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

  Future<void> _showTermsDialog(String title) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: const Text('This page is a placeholder and will be integrated soon.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final PasswordStrength strength = AuthValidators.passwordStrength(_passwordController.text);
    final int segments = AuthValidators.strengthSegments(strength);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (BuildContext context, AuthState state) async {
        final NavigatorState navigator = Navigator.of(context);

        if (state is AuthError) {
          HapticFeedback.heavyImpact();
          setState(() {
            _errorBanner = state.message;
          });
        }

        if (state is SignUpSuccess) {
          HapticFeedback.mediumImpact();
          await showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.textSecondary),
                      ),
                      child: const Icon(Icons.check, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Account created! Please verify your email',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );

          if (mounted) {
            navigator.pushReplacementNamed(AppRoutes.login);
          }
        }

        if (state is Authenticated) {
          navigator.pushNamedAndRemoveUntil(AppRoutes.home, (Route<dynamic> route) => false);
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
                      title: 'Create Account',
                      subtitle: 'Start your interview coaching journey today',
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
                  _LabeledInputField(
                    enabled: !isLoading,
                    label: 'Username',
                    controller: _usernameController,
                    focusNode: _usernameFocusNode,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      setState(() {
                        _isUsernameAvailable = null;
                      });
                    },
                    onSubmitted: (_) => _emailFocusNode.requestFocus(),
                    semanticLabel: 'Username field',
                  ),
                  if (_checkingUsername)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Checking username availability...',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    )
                  else if (_usernameError != null)
                    AuthInlineErrorText(_usernameError!)
                  else if ((_submitAttempted || _usernameTouched) && _isUsernameAvailable == true)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Username available',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _LabeledInputField(
                    enabled: !isLoading,
                    label: 'Email',
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                    semanticLabel: 'Email field',
                  ),
                  if (_emailError != null) AuthInlineErrorText(_emailError!),
                  const SizedBox(height: 12),
                  _LabeledInputField(
                    enabled: !isLoading,
                    label: 'Password',
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _confirmFocusNode.requestFocus(),
                    semanticLabel: _obscurePassword ? 'Password field, hidden' : 'Password field, visible',
                    suffix: IconButton(
                      onPressed: isLoading ? null : () => setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (_passwordError != null) AuthInlineErrorText(_passwordError!),
                  const SizedBox(height: 8),
                  PasswordStrengthBar(segments: segments, label: _passwordStrengthLabel),
                  const SizedBox(height: 12),
                  _LabeledInputField(
                    enabled: !isLoading,
                    label: 'Confirm Password',
                    controller: _confirmController,
                    focusNode: _confirmFocusNode,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                    semanticLabel: _obscureConfirm ? 'Confirm password field, hidden' : 'Confirm password field, visible',
                    suffix: IconButton(
                      onPressed: isLoading ? null : () => setState(() => _obscureConfirm = !_obscureConfirm),
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (_confirmError != null) AuthInlineErrorText(_confirmError!),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: isLoading ? null : () => setState(() => _showReferral = !_showReferral),
                      child: Text(
                        _showReferral ? 'Hide Referral Code (optional)' : 'Referral Code (optional)',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  if (_showReferral)
                    _LabeledInputField(
                      enabled: !isLoading,
                      label: 'Referral Code (optional)',
                      controller: _referralController,
                      focusNode: _referralFocusNode,
                      onChanged: (_) {},
                      semanticLabel: 'Referral code field',
                    ),
                  const SizedBox(height: 12),
                  AuthPrimaryButton(
                    label: 'Sign Up',
                    isLoading: state is AuthLoading,
                    onPressed: _isFormValid && !isLoading ? _submit : null,
                  ),
                  const SizedBox(height: 20),
                  const AuthDivider(),
                  const SizedBox(height: 20),
                  AuthGoogleButton(
                    label: 'Sign up with Google',
                    onPressed: isLoading ? null : _showGoogleBottomSheet,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: <Widget>[
                      const Text(
                        'By signing up, you agree to our ',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                      InkWell(
                        onTap: () => _showTermsDialog('Terms of Service'),
                        child: const Text(
                          'Terms of Service',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                      const Text(
                        ' and ',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                      InkWell(
                        onTap: () => _showTermsDialog('Privacy Policy'),
                        child: const Text(
                          'Privacy Policy',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      InkWell(
                        onTap: isLoading
                            ? null
                            : () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Sign In',
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LabeledInputField extends StatelessWidget {
  const _LabeledInputField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.semanticLabel,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String semanticLabel;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final bool enabled;

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
            onChanged: onChanged,
            onSubmitted: onSubmitted,
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
