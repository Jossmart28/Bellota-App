import 'package:flutter/material.dart';

import '../l10n/app_translations.dart';
import '../l10n/language_notifier.dart';
import '../core/services/auth_service.dart';
import '../core/services/navigation_service.dart';
import '../theme/bellota_colors.dart';
import '../widgets/bellota_text_field.dart';
import '../widgets/bellota_top_actions.dart';
import 'onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    try {
      final exists = await AuthService.instance.emailExists(email);
      if (exists) {
        _setLoading(false);
        _showError('Este correo electronico ya esta registrado.');
        return;
      }
      final user = await AuthService.instance.register(
        _nameController.text, email, _passwordController.text,
      );
      await AuthService.instance.saveSession(user);
      // Registrar el evento de registro en el log de auditoría
      await AuthService.instance.logAction(
        action: 'register',
        targetType: 'user',
        targetId: user.id,
      );
      _setLoading(false);
      if (!mounted) return;
      NavigationService.goAndClearStack(context, const OnboardingScreen());
    } catch (_) {
      _setLoading(false);
      _showError('Ocurrio un error al conectar con la base de datos.');
    }
  }

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: BellotaColors.blanco)),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: BellotaColors.chilero,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: BellotaColors.blanco),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              BellotaTopActions(
                showSettings: false,
                onLanguagePressed: () => languageNotifier.toggle(),
                onTalkBackPressed: () {},
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.get('onboarding_and_auth', 'create_account', lang),
                      style: textTheme.displayMedium?.copyWith(color: BellotaColors.blanco),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppTranslations.get('onboarding_and_auth', 'join_bellota', lang),
                      style: textTheme.bodyLarge?.copyWith(color: BellotaColors.blanco.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: BellotaColors.blanco.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: BellotaColors.blanco.withValues(alpha: 0.25)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            BellotaTextField(
                              controller: _nameController,
                              label: AppTranslations.get('onboarding_and_auth', 'name_label', lang),
                              hint: AppTranslations.get('onboarding_and_auth', 'name_hint', lang),
                              prefixIcon: Icons.person_outline,
                              validator: (v) => v!.isEmpty ? AppTranslations.get('onboarding_and_auth', 'enter_name', lang) : null,
                            ),
                            const SizedBox(height: 16),
                            BellotaTextField(
                              controller: _emailController,
                              label: AppTranslations.get('onboarding_and_auth', 'email_label', lang),
                              hint: AppTranslations.get('onboarding_and_auth', 'email_hint', lang),
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) return AppTranslations.get('onboarding_and_auth', 'enter_email', lang);
                                if (!v.contains('@')) return AppTranslations.get('onboarding_and_auth', 'invalid_email', lang);
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            BellotaTextField(
                              controller: _passwordController,
                              label: AppTranslations.get('onboarding_and_auth', 'password_label', lang),
                              hint: 'aaaaaaaa',
                              prefixIcon: Icons.lock_outline,
                              obscureText: !_passwordVisible,
                              suffixIcon: IconButton(
                                icon: Icon(_passwordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: BellotaColors.blanco.withValues(alpha: 0.7)),
                                onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return AppTranslations.get('onboarding_and_auth', 'enter_pass', lang);
                                if (v.length < 6) return AppTranslations.get('onboarding_and_auth', 'min_6_chars', lang);
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            BellotaTextField(
                              controller: _confirmController,
                              label: AppTranslations.get('onboarding_and_auth', 'confirm_pass', lang),
                              hint: 'aaaaaaaa',
                              prefixIcon: Icons.lock_outline,
                              obscureText: !_confirmVisible,
                              suffixIcon: IconButton(
                                icon: Icon(_confirmVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: BellotaColors.blanco.withValues(alpha: 0.7)),
                                onPressed: () => setState(() => _confirmVisible = !_confirmVisible),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return AppTranslations.get('onboarding_and_auth', 'confirm_pass_req', lang);
                                if (v != _passwordController.text) return AppTranslations.get('onboarding_and_auth', 'pass_no_match', lang);
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: BellotaColors.melon,
                                  foregroundColor: BellotaColors.blanco,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                ),
                                child: _isLoading
                                    ? CircularProgressIndicator(color: BellotaColors.blanco)
                                    : Text(AppTranslations.get('onboarding_and_auth', 'register_btn', lang)),
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
          ),
        );
      },
    );
  }
}
