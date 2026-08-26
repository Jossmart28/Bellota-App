import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import '../database/database_helper.dart';
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
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      try {
        bool exists = await DatabaseHelper.instance.emailExists(email);
        if (exists) {
          setState(() => _isLoading = false);
          if (mounted) {
            _showError('Este correo electrónico ya está registrado.');
          }
          return;
        }

        final userId = await DatabaseHelper.instance.registerUser(name, email, password);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', name);
        await prefs.setString('userEmail', email);
        await prefs.setInt('userId', userId);
        
        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) _showError('Ocurrió un error al conectar con la base de datos.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: BellotaColors.blanco)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: BellotaColors.chilero,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: BellotaColors.blanco),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // === BOTONES GLOBALES ===
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
                Text(
                  'Crear Cuenta',
                  style: textTheme.displayMedium?.copyWith(color: BellotaColors.blanco),
                ),
                const SizedBox(height: 8),
                Text(
                  'Únete a Bellota 🌸',
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
                        _BellotaTextField(
                          controller: _nameController,
                          label: 'Nombre',
                          hint: 'Tu nombre o apodo',
                          prefixIcon: Icons.person_outline,
                          validator: (v) => v!.isEmpty ? 'Ingresa tu nombre' : null,
                        ),
                        const SizedBox(height: 16),
                        _BellotaTextField(
                          controller: _emailController,
                          label: 'Correo electrónico',
                          hint: 'tu@correo.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingresa tu correo';
                            if (!v.contains('@')) return 'Correo no válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _BellotaTextField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          obscureText: !_passwordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: BellotaColors.blanco.withValues(alpha: 0.7),
                            ),
                            onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _BellotaTextField(
                          controller: _confirmController,
                          label: 'Confirmar Contraseña',
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          obscureText: !_confirmVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _confirmVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: BellotaColors.blanco.withValues(alpha: 0.7),
                            ),
                            onPressed: () => setState(() => _confirmVisible = !_confirmVisible),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                            if (v != _passwordController.text) return 'Las contraseñas no coinciden';
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: BellotaColors.blanco)
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

// --- WIDGET REUTILIZABLE LOCAL ---
class _BellotaTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _BellotaTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: BellotaColors.blanco),
      cursorColor: BellotaColors.blanco,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: BellotaColors.blanco.withValues(alpha: 0.75)),
        suffixIcon: suffixIcon,
      ),
    );
  }
}