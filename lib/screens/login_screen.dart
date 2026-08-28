import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import '../database/database_helper.dart';
import '../widgets/bellota_top_actions.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';
import 'calendar_tour_screen.dart';
import 'personal_data_screen.dart';

/// Pantalla de Inicio de Sesión
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _passwordVisible = false;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<Offset> _formSlide;
  late Animation<double> _formFade;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );

    _formSlide = Tween<Offset>(
      begin: Offset(0, 0.4),
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

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      try {
        final user = await DatabaseHelper.instance.loginUser(email, password);
        
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userName', user['name']);
          await prefs.setString('userEmail', user['email']);
          await prefs.setInt('userId', user['id'] as int);

          final onboardingDone = prefs.getBool('onboarding_done') ?? false;
          final calendarTourDone = prefs.getBool('calendar_tour_done') ?? false;
          final setupCompleted = prefs.getBool('setup_completed') ?? false;

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) {
                  if (!onboardingDone) return OnboardingScreen();
                  if (!calendarTourDone) return CalendarTourScreen();
                  if (!setupCompleted) return PersonalDataScreen();
                  return DashboardScreen();
                },
              ),
            );
          }
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Credenciales incorrectas.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: BellotaColors.blanco)),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error al iniciar sesión.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: BellotaColors.blanco))),
          );
        }
      }
    }
  }

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
            Positioned.fill(
              child: CustomPaint(
                painter: _LoginBackgroundPainter(),
              ),
            ),
            
            // === BOTONES GLOBALES ===
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

            SafeArea(
              child: SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top),
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

  // --- SECCIONES DE UI ---

  Widget _buildLogoSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Center(
        child: Image.asset(
          'assets/images/logo_white.png',
          width: 220,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildFormSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.fromLTRB(28, 36, 28, 32),
      decoration: BoxDecoration(
        color: BellotaColors.blanco.withValues(alpha: 0.12),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        border: Border(
          top: BorderSide(color: BellotaColors.blanco.withValues(alpha: 0.25), width: 1),
          left: BorderSide(color: BellotaColors.blanco.withValues(alpha: 0.25), width: 1),
          right: BorderSide(color: BellotaColors.blanco.withValues(alpha: 0.25), width: 1),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Iniciar Sesión',
              style: textTheme.displayMedium?.copyWith(color: BellotaColors.blanco),
            ),
            SizedBox(height: 4),
            Text(
              'Bienvenida de vuelta 🌸',
              style: textTheme.bodyMedium?.copyWith(color: BellotaColors.blanco.withValues(alpha: 0.75)),
            ),
            SizedBox(height: 28),

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
            SizedBox(height: 16),

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
                if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: BellotaColors.blanco,
                  padding: EdgeInsets.zero,
                  minimumSize: Size(10, 36),
                ),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: textTheme.bodySmall?.copyWith(
                    color: BellotaColors.blanco.withValues(alpha: 0.85),
                    decoration: TextDecoration.underline,
                    decorationColor: BellotaColors.blanco.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),

            _BellotaButton(
              onPressed: _isLoading ? null : _handleLogin,
              isLoading: _isLoading,
              label: 'Ingresar',
            ),
            SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: Divider(color: BellotaColors.blanco.withValues(alpha: 0.3), height: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'o continúa con',
                    style: textTheme.bodySmall?.copyWith(color: BellotaColors.blanco.withValues(alpha: 0.65)),
                  ),
                ),
                Expanded(child: Divider(color: BellotaColors.blanco.withValues(alpha: 0.3), height: 1)),
              ],
            ),
            SizedBox(height: 20),

            _SocialButton(
              label: 'Continuar con Google',
              icon: Icons.g_mobiledata_rounded,
              onPressed: () {},
            ),
            SizedBox(height: 24),

            Center(
              child: RichText(
                text: TextSpan(
                  style: textTheme.bodySmall?.copyWith(color: BellotaColors.blanco.withValues(alpha: 0.75)),
                  children: [
                    TextSpan(text: '¿No tienes cuenta? '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => RegisterScreen()),
                          );
                        },
                        child: Text(
                          'Regístrate',
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

// --- COMPONENTES REUTILIZABLES ---

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
              offset: Offset(0, 6),
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
                  child: CircularProgressIndicator(color: BellotaColors.blanco, strokeWidth: 2.5),
                )
              : Text(
                  label,
                ),
        ),
      ),
    );
  }
}

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
          side: BorderSide(color: BellotaColors.blanco.withValues(alpha: 0.45), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: BellotaColors.blanco.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BellotaColors.blanco.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(size.width * 1.2, size.height * 0.2, size.width, size.height * 0.45)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.9, 0, size.height)
      ..close();
    canvas.drawPath(path2, paint..color = BellotaColors.blanco.withValues(alpha: 0.04));

    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.12), size.width * 0.18, paint..color = BellotaColors.blanco.withValues(alpha: 0.04));
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.85), size.width * 0.12, paint..color = BellotaColors.blanco.withValues(alpha: 0.03));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}