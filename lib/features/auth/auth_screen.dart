import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../notification/fcm_service.dart';
import '../shell/main_shell.dart';
import 'auth_service.dart';

enum _AuthMode { signIn, signUp, forgotPassword }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthMode _mode = _AuthMode.signIn;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _skillsController = TextEditingController();
  final _otpController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _otpSent = false;
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _skillsController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _errorMessage = null;
      _infoMessage = null;
      _otpSent = false;
      _otpController.clear();
    });
  }

  Future<void> _handleSubmit() async {
    if (_mode == _AuthMode.forgotPassword) {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        setState(() => _errorMessage = 'Enter your email address');
        return;
      }

      if (!_otpSent) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _infoMessage = null;
        });

        final res = await _authService.forgotPassword(email);
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          if (res['success'] == true) {
            _otpSent = true;
            _infoMessage = res['message'] ?? 'Verification code generated!';
            if (res['devOtp'] != null) {
              _otpController.text = res['devOtp'].toString();
            }
          } else {
            _errorMessage = res['errorMessage'];
          }
        });
        return;
      } else {
        final otp = _otpController.text.trim();
        final newPassword = _passwordController.text;
        if (otp.isEmpty) {
          setState(() => _errorMessage = 'Please enter the 6-digit verification code');
          return;
        }
        if (newPassword.length < 6) {
          setState(() => _errorMessage = 'Password must be at least 6 characters');
          return;
        }

        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _infoMessage = null;
        });

        final res = await _authService.resetPassword(
          email: email,
          otp: otp,
          newPassword: newPassword,
        );
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          if (res['success'] == true) {
            _switchMode(_AuthMode.signIn);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['message'] ?? 'Password reset successfully! Please sign in.')),
            );
          } else {
            _errorMessage = res['errorMessage'];
          }
        });
        return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = _mode == _AuthMode.signIn
        ? await _authService.login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
        : await _authService.signup(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            skills: _skillsController.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
          );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      await FcmService().initialize();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainShell(user: result.user)),
        (route) => false,
      );
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_mode) {
      _AuthMode.signIn => 'Sign in to your account',
      _AuthMode.signUp => 'Create your secure profile',
      _AuthMode.forgotPassword => _otpSent ? 'Enter code & new password' : 'Reset your password',
    };

    final subtitle = switch (_mode) {
      _AuthMode.signIn =>
        'Access your Task dashboard,teams and task updates securely.',
      _AuthMode.signUp =>
        'Register with your details to connect with Workers,Freelancers and workflows.',
      _AuthMode.forgotPassword => _otpSent
          ? 'Enter the 6-digit code sent to your email and your new password.'
          : 'Enter your account email to receive a verification code.',
    };

    final switchPrompt = switch (_mode) {
      _AuthMode.signIn => 'Don\'t have an account?',
      _AuthMode.signUp => 'Already have an account?',
      _AuthMode.forgotPassword => 'Remembered your password?',
    };

    final switchAction = switch (_mode) {
      _AuthMode.signIn => 'Sign up',
      _AuthMode.signUp => 'Sign in',
      _AuthMode.forgotPassword => 'Sign in',
    };

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.getHeroGradient(context)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppTheme.logoGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withAlpha(70),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.people_alt_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Theme.of(context).dividerColor.withAlpha(30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withAlpha(12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Secure access',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'WorkConnect',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Trusted app designed for Workers and freelancers.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(209),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: const [
                        _HeaderBadge(
                          label: 'Easy Collab',
                          icon: Icons.groups_rounded,
                          iconColor: AppTheme.primary,
                        ),
                        SizedBox(width: 12),
                        _HeaderBadge(
                          label: 'Live updates',
                          icon: Icons.bolt_rounded,
                          iconColor: Color(0xFF1DBF73),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Transform.translate(
                offset: const Offset(0, -24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                            if (_mode == _AuthMode.forgotPassword) ...[
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withAlpha(25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _otpSent ? Icons.mark_email_read_rounded : Icons.lock_reset_rounded,
                                    size: 48,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: _mode == _AuthMode.forgotPassword ? 24 : 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              textAlign: _mode == _AuthMode.forgotPassword ? TextAlign.center : TextAlign.start,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
                                height: 1.5,
                              ),
                              textAlign: _mode == _AuthMode.forgotPassword ? TextAlign.center : TextAlign.start,
                            ),
                            const SizedBox(height: 28),

                            if (_mode == _AuthMode.signUp) ...[
                              _RoundedField(
                                controller: _nameController,
                                icon: Icons.person_outline,
                                hint: 'Full name',
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                              ),
                              const SizedBox(height: 14),
                            ],

                            _RoundedField(
                              controller: _emailController,
                              icon: Icons.mail_outline,
                              hint: 'Email address',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Email is required' : null,
                            ),

                            if (_mode != _AuthMode.forgotPassword) ...[
                              const SizedBox(height: 14),
                              _RoundedField(
                                controller: _passwordController,
                                icon: Icons.lock_outline,
                                hint: 'Password',
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Password is required';
                                  if (_mode == _AuthMode.signUp && v.length < 6) {
                                    return 'Use at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                            ],

                            if (_mode == _AuthMode.signUp) ...[
                              const SizedBox(height: 14),
                              _RoundedField(
                                controller: _confirmPasswordController,
                                icon: Icons.lock_outline,
                                hint: 'Confirm Password',
                                obscureText: _obscureConfirm,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Please confirm your password';
                                  if (v != _passwordController.text) return 'Passwords do not match';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              _RoundedField(
                                controller: _skillsController,
                                icon: Icons.build_outlined,
                                hint: 'Skills (comma separated)',
                              ),
                            ],

                            if (_mode == _AuthMode.forgotPassword && _otpSent) ...[
                              const SizedBox(height: 14),
                              _RoundedField(
                                controller: _otpController,
                                icon: Icons.pin_outlined,
                                hint: '6-digit verification code',
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 14),
                              _RoundedField(
                                controller: _passwordController,
                                icon: Icons.lock_outline,
                                hint: 'New password',
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'New password is required';
                                  if (v.length < 6) return 'Use at least 6 characters';
                                  return null;
                                },
                              ),
                            ],

                            if (_mode == _AuthMode.signIn) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _switchMode(_AuthMode.forgotPassword),
                                  child: Text('Forgot password?', style: TextStyle(fontSize: 13)),
                                ),
                              ),
                            ],

                            if (_mode == _AuthMode.signUp) ...[
                              const SizedBox(height: 12),
                              Text(
                                'By signing up, you agree to our Terms & Conditions and Privacy Policy',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface),
                              ),
                            ],

                            const SizedBox(height: 18),
                            if (_errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F0),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Color(0xFFB00020), fontSize: 13),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (_infoMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F8F8),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  _infoMessage!,
                                  style: TextStyle(color: AppTheme.primary, fontSize: 13),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        switch (_mode) {
                                          _AuthMode.signIn => 'Login',
                                          _AuthMode.signUp => 'Create Account',
                                          _AuthMode.forgotPassword =>
                                            _otpSent ? 'Reset Password' : 'Send Verification Code',
                                        },
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),



                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  switchPrompt,
                                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                                ),
                                TextButton(
                                  onPressed: () {
                                    if (_mode == _AuthMode.signUp || _mode == _AuthMode.forgotPassword) {
                                      _switchMode(_AuthMode.signIn);
                                    } else {
                                      _switchMode(_AuthMode.signUp);
                                    }
                                  },
                                  child: Text(
                                    switchAction,
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const _RoundedField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 22, color: AppTheme.primary),
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _AuthModeSelector extends StatelessWidget {
  final _AuthMode mode;
  final ValueChanged<_AuthMode> onModeChanged;

  const _AuthModeSelector({
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ModeTab(
          label: 'Sign In',
          isActive: mode == _AuthMode.signIn,
          onTap: () => onModeChanged(_AuthMode.signIn),
        ),
        _ModeTab(
          label: 'Sign Up',
          isActive: mode == _AuthMode.signUp,
          onTap: () => onModeChanged(_AuthMode.signUp),
        ),
      ],
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor:
              isActive ? AppTheme.primary.withAlpha(31) : Theme.of(context).cardColor,
            side: BorderSide(
              color: isActive ? AppTheme.primary : AppTheme.cardBorder,
            ),
            foregroundColor: isActive ? AppTheme.primary : Theme.of(context).colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;

  const _HeaderBadge({
    required this.label,
    required this.icon,
    this.iconColor = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withAlpha(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
