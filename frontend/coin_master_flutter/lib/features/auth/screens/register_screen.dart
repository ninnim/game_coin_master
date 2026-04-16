import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/glass_card.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authProvider.notifier)
        .register(
          _emailCtrl.text.trim(),
          _passCtrl.text,
          _nameCtrl.text.trim(),
        );
    if (success && mounted) context.go('/game');
  }

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGlow),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.crimson),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.crimson),
        ),
        filled: true,
        fillColor: AppColors.surface,
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                'JOIN THE EMPIRE',
                style: AppTextStyles.headline.copyWith(
                  color: AppColors.gold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your warrior account',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 36),
              GlassCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (state.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.crimson.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.crimson,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.error!,
                                  style: const TextStyle(
                                    color: AppColors.crimson,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration(
                          'Warrior Name',
                          Icons.person_outline,
                        ),
                        validator:
                            (v) =>
                                v != null && v.trim().length >= 2
                                    ? null
                                    : 'Min 2 characters',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration:
                            _inputDecoration('Email', Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                        validator:
                            (v) =>
                                v != null && v.contains('@')
                                    ? null
                                    : 'Enter a valid email',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration(
                          'Password',
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        validator:
                            (v) =>
                                v != null && v.length >= 6
                                    ? null
                                    : 'Min 6 characters',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPassCtrl,
                        obscureText: _obscureConfirm,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration(
                          'Confirm Password',
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        validator:
                            (v) =>
                                v == _passCtrl.text
                                    ? null
                                    : 'Passwords do not match',
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: GlassButton(
                          label: 'CREATE ACCOUNT',
                          onTap: _register,
                          isLoading: state.isLoading,
                          icon: Icons.military_tech,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.go('/login'),
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Already a warrior? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextSpan(
                        text: 'Login here!',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
