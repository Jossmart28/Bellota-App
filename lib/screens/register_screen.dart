import 'package:flutter/material.dart';

import '../core/services/auth_service.dart';
import '../core/services/navigation_service.dart';
import '../theme/bellota_colors.dart';
import '../widgets/bellota_text_field.dart';
import '../widgets/bellota_top_actions.dart';
import 'onboarding_screen.dart';

/// Pantalla de Registro de nueva cuenta en Bellota.
///
/// Valida los datos ingresados, verifica que el correo no esté en uso
/// y crea el usuario en la base de datos local usando [AuthService].
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ── Formulario ─────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  // ── Estado local ───────────────────────────────────────────────────────────
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _isLoading = false;

  // ── Ciclo de vida ──────────────────────────────────────────────────────────

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Lógica de negocio ──────────────────────────────────────────────────────

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();

    try {
      // Verificar disponibilidad del correo
      final exists = await AuthService.instance.emailExists(email);
      if (exists) {
        _setLoading(false);
        _showError('Este correo electrónico ya está registrado.');
        return;
      }

      // Crear usuario y guardar sesión
      final user = await AuthService.instance.register(
        _nameController.text,
        email,
        _passwordController.text,
      );
      await AuthService.instance.saveSession(user);

      _setLoading(false);
      if (!mounted) return;

      NavigationService.goAndClearStack(context, const OnboardingScreen());
    } catch (_) {
      _setLoading(false);
      _showError('Ocurrió un error al conectar con la base de datos.');
    }
  }

  // ── Helpers de UI ──────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: BellotaColors.blanco),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
            onLanguagePressed: () {},
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
                // Encabezado
                Text(
                  'Crear Cuenta',
                  style: textTheme.displayMedium
                      ?.copyWith(color: BellotaColors.blanco),
                ),
                const SizedBox(height: 8),
                Text(
                  'Únete a Bellota 🌸',
                  style: textTheme.bodyLarge?.copyWith(
                      color: BellotaColors.blanco.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 32),

                // Tarjeta de formulario
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: BellotaColors.blanco.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: BellotaColors.blanco.withValues(alpha: 0.25)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Nombre
                        BellotaTextField(
                          controller: _nameController,
                          label: 'Nombre',
                          hint: 'Tu nombre o apodo',
                          prefixIcon: Icons.person_outline,
                          validator: (v) =>
                              v!.isEmpty ? 'Ingresa tu nombre' : null,
                        ),
                        const SizedBox(height: 16),

                        // Correo electrónico
                        BellotaTextField(
                          controller: _emailController,
                          label: 'Correo electrónico',
                          hint: 'tu@correo.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Ingresa tu correo';
                            }
                            if (!v.contains('@')) return 'Correo no válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Contraseña
                        BellotaTextField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          obscureText: !_passwordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: BellotaColors.blanco.withValues(alpha: 0.7),
                            ),
                            onPressed: () => setState(
                                () => _passwordVisible = !_passwordVisible),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Ingresa una contraseña';
                            }
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirmar contraseña
                        BellotaTextField(
                          controller: _confirmController,
                          label: 'Confirmar Contraseña',
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          obscureText: !_confirmVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _confirmVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: BellotaColors.blanco.withValues(alpha: 0.7),
                            ),
                            onPressed: () => setState(
                                () => _confirmVisible = !_confirmVisible),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Confirma tu contraseña';
                            }
                            if (v != _passwordController.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Botón de registro
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BellotaColors.melon,
                              foregroundColor: BellotaColors.blanco,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(
                                    color: BellotaColors.blanco)
                                : const Text('Registrarse'),
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
  }
}