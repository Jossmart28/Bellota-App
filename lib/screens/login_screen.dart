import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_translations.dart';
import '../l10n/language_notifier.dart';
import '../core/services/auth_service.dart';
import '../core/services/navigation_service.dart';
import '../theme/bellota_colors.dart';
import '../widgets/bellota_text_field.dart';
import '../widgets/bellota_top_actions.dart';
import 'register_screen.dart';

/// Pantalla de Inicio de Sesión de Bellota.
///
/// Valida las credenciales locales del usuario y redirige al flujo
/// de incorporación correcto usando [NavigationService.resolveHomeScreen].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── Formulario ─────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ── Estado local ───────────────────────────────────────────────────────────
  bool _passwordVisible = false;
  bool _isLoading = false;

  // ── Animaciones ────────────────────────────────────────────────────────────
  late AnimationController _animController;
  late Animation<Offset> _formSlide;
  late Animation<double> _formFade;

  // ── Ciclo de vida ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Lógica de negocio ──────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final user = await AuthService.instance.login(
        _emailController.text,
        _passwordController.text,
      );

      if (user != null) {
        await AuthService.instance.saveSession(user);
        if (!mounted) return;

        // Resolución de pantalla sin gaps asíncronos tras el mounted check
        final prefs = await SharedPreferences.getInstance();
        if (!mounted) return;
        final destination = NavigationService.resolveHomeScreen(prefs);
        NavigationService.goReplace(context, destination);
      } else {
        _setLoading(false);
        _showError('Credenciales incorrectas.');
      }
    } catch (_) {
      _setLoading(false);
      _showError('Error al iniciar sesión.');
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: BellotaColors.chilero,
        child: Stack(
          children: [
            // Fondo decorativo
            const Positioned.fill(
              child: CustomPaint(painter: _LoginBackgroundPainter()),
            ),

            // Botones globales (idioma / accesibilidad)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: BellotaTopActions(
                  showSettings: false,
                  onLanguagePressed: () {},
                  onTalkBackPressed: () {},
                ),
              ),
            ),

            // Contenido principal
            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height -
                        MediaQuery.of(context).padding.top,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildLogoSection(),
                        ),
                        Expanded(
                          flex: 5,
                          child: SlideTransition(
                            position: _formSlide,
                            child: FadeTransition(
                              opacity: _formFade,
                              child: _buildFormSection(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Secciones de UI ────────────────────────────────────────────────────────

  Widget _buildLogoSection() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Center(
        child: Image(
          image: AssetImage('assets/images/logo_white.png'),
          width: 220,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildFormSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lang = languageNotifier.currentLang;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
      decoration: BoxDecoration(
        color: BellotaColors.blanco.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        border: Border(
          top: BorderSide(
              color: BellotaColors.blanco.withValues(alpha: 0.25), width: 1),
          left: BorderSide(
              color: BellotaColors.blanco.withValues(alpha: 0.25), width: 1),
          right: BorderSide(
              color: BellotaColors.blanco.withValues(alpha: 0.25), width: 1),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.get('onboarding_and_auth', 'login_title', lang),
              style: textTheme.displayMedium
                  ?.copyWith(color: BellotaColors.blanco),
            ),
            const SizedBox(height: 4),
            Text(
              AppTranslations.get('onboarding_and_auth', 'welcome_back', lang),
              style: textTheme.bodyMedium?.copyWith(
                  color: BellotaColors.blanco.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 28),

            // Campo de email
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

            // Campo de contraseña
            BellotaTextField(
              controller: _passwordController,
              label: AppTranslations.get('onboarding_and_auth', 'password_label', lang),
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
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return AppTranslations.get('onboarding_and_auth', 'enter_pass', lang);
                if (v.length < 6) return AppTranslations.get('onboarding_and_auth', 'min_6_chars', lang);
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Olvidé mi contraseña
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: BellotaColors.blanco,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(10, 36),
                ),
                child: Text(
                  AppTranslations.get('onboarding_and_auth', 'forgot_pass', lang),
                  style: textTheme.bodySmall?.copyWith(
                    color: BellotaColors.blanco.withValues(alpha: 0.85),
                    decoration: TextDecoration.underline,
                    decorationColor:
                        BellotaColors.blanco.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón de ingreso
            _BellotaButton(
              onPressed: _isLoading ? null : _handleLogin,
              isLoading: _isLoading,
              label: AppTranslations.get('onboarding_and_auth', 'enter', lang),
            ),
            const SizedBox(height: 20),

            // Separador "o continúa con"
            Row(
              children: [
                Expanded(
                    child: Divider(
                        color: BellotaColors.blanco.withValues(alpha: 0.3),
                        height: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    AppTranslations.get('onboarding_and_auth', 'or_continue_with', lang),
                    style: textTheme.bodySmall?.copyWith(
                        color: BellotaColors.blanco.withValues(alpha: 0.65)),
                  ),
                ),
                Expanded(
                    child: Divider(
                        color: BellotaColors.blanco.withValues(alpha: 0.3),
                        height: 1)),
              ],
            ),
            const SizedBox(height: 20),

            // Botón de Google
            _SocialButton(
              label: AppTranslations.get('onboarding_and_auth', 'continue_google', lang),
              icon: Icons.g_mobiledata_rounded,
              onPressed: () {},
            ),
            const SizedBox(height: 24),

            // Enlace a registro
            Center(
              child: RichText(
                text: TextSpan(
                  style: textTheme.bodySmall?.copyWith(
                      color: BellotaColors.blanco.withValues(alpha: 0.75)),
                  children: [
                    TextSpan(text: AppTranslations.get('onboarding_and_auth', 'no_account', lang)),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => NavigationService.goTo(
                          context,
                          const RegisterScreen(),
                        ),
                        child: Text(
                          AppTranslations.get('onboarding_and_auth', 'register_now', lang),
                          style: textTheme.bodySmall?.copyWith(
                            color: BellotaColors.blanco,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: BellotaColors.blanco,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Componentes locales de UI ──────────────────────────────────────────────

/// Botón principal con gradiente Bellota.
class _BellotaButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  const _BellotaButton({
    required this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: BellotaColors.buttonGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: BellotaColors.chilero.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: BellotaColors.blanco,
          ),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: BellotaColors.blanco, strokeWidth: 2.5),
                )
              : Text(label),
        ),
      ),
    );
  }
}

/// Botón de proveedor externo (Google, Apple, etc.).
class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: BellotaColors.blanco, size: 24),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: BellotaColors.blanco,
          side: BorderSide(
              color: BellotaColors.blanco.withValues(alpha: 0.45), width: 1.2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: BellotaColors.blanco.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

/// Fondo decorativo de la pantalla de login con curvas y círculos sutiles.
class _LoginBackgroundPainter extends CustomPainter {
  const _LoginBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BellotaColors.blanco.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(
          size.width * 1.2, size.height * 0.2, size.width, size.height * 0.45)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
          size.width * 0.3, size.height * 0.9, 0, size.height)
      ..close();
    canvas.drawPath(
        path2, paint..color = BellotaColors.blanco.withValues(alpha: 0.04));

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.12),
      size.width * 0.18,
      paint..color = BellotaColors.blanco.withValues(alpha: 0.04),
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.85),
      size.width * 0.12,
      paint..color = BellotaColors.blanco.withValues(alpha: 0.03),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}