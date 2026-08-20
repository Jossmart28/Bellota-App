import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import '../database/database_helper.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

/// Pantalla de Inicio de Sesión - Bellota Calendario Menstrual
/// Diseño: fondo sólido Chilero con formulario flotante, campos con bordes blancos
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
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

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      try {
        final user = await DatabaseHelper.instance.loginUser(email, password);
        
        if (user != null) {
          // Guardar sesión
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userName', user['name']);
          await prefs.setString('userEmail', user['email']);
          
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          }
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Credenciales incorrectas.', style: GoogleFonts.poppins()),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al iniciar sesión.', style: GoogleFonts.poppins())),
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
        // Fondo sólido Chilero (igual al panel derecho de la imagen de referencia)
        color: BellotaColors.chilero,
        child: Stack(
          children: [
            // === PATRÓN DECORATIVO DE FONDO ===
            Positioned.fill(
              child: CustomPaint(
                painter: _LoginBackgroundPainter(),
              ),
            ),

            // === CONTENIDO SCROLLABLE ===
            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // -------- SECCIÓN SUPERIOR: Logo --------
                        Expanded(
                          flex: 3,
                          child: _buildLogoSection(),
                        ),

                        // -------- SECCIÓN INFERIOR: Formulario --------
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

  // ============================================================
  // SECCIÓN LOGO
  // ============================================================
  Widget _buildLogoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Center(
        child: Image.asset(
          'assets/images/logo_white.png',
          width: 220,
          fit: BoxFit.contain,
        ),
      ),
    );
  }


  // ============================================================
  // SECCIÓN FORMULARIO
  // ============================================================
  Widget _buildFormSection(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
      decoration: BoxDecoration(
        // Panel blanco semi-transparente con bordes redondeados arriba
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(36),
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.25), width: 1),
          left: BorderSide(color: Colors.white.withValues(alpha: 0.25), width: 1),
          right: BorderSide(color: Colors.white.withValues(alpha: 0.25), width: 1),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              'Iniciar Sesión',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bienvenida de vuelta 🌸',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),

            const SizedBox(height: 28),

            // === CAMPO EMAIL ===
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

            // === CAMPO CONTRASEÑA ===
            _BellotaTextField(
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
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),

            const SizedBox(height: 12),

            // Olvidaste tu contraseña
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(10, 36),
                ),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.85),
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // === BOTÓN INGRESAR ===
            _BellotaButton(
              onPressed: _isLoading ? null : _handleLogin,
              isLoading: _isLoading,
              label: 'Ingresar',
            ),

            const SizedBox(height: 20),

            // === DIVIDER ===
            Row(
              children: [
                Expanded(
                  child: Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'o continúa con',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // === BOTÓN GOOGLE ===
            _SocialButton(
              label: 'Continuar con Google',
              icon: Icons.g_mobiledata_rounded,
              onPressed: () {},
            ),

            const SizedBox(height: 24),

            // Enlace registro
            Center(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                  children: [
                    const TextSpan(text: '¿No tienes cuenta? '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: Text(
                          'Regístrate',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
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

// ============================================================
// WIDGET: Campo de texto estilo Bellota
// ============================================================
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
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 15,
      ),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: Colors.white.withValues(alpha: 0.75)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: GoogleFonts.poppins(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.poppins(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 14,
        ),
        errorStyle: GoogleFonts.poppins(
          color: const Color(0xFFFFD0CC),
          fontSize: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFFD0CC), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFFD0CC), width: 2),
        ),
      ),
    );
  }
}

// ============================================================
// WIDGET: Botón principal Bellota con gradiente Melón → Chilero
// ============================================================
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
          gradient: const LinearGradient(
            colors: [Color(0xFFEE8658), Color(0xFFD35D53)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD35D53).withValues(alpha: 0.5),
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
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

// ============================================================
// WIDGET: Botón Social (Google, etc.)
// ============================================================
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
        icon: Icon(icon, color: Colors.white, size: 24),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.45), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}




// ============================================================
// PAINTER: Ondas decorativas del fondo del Login
// ============================================================
class _LoginBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Onda superior derecha
    final path1 = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(
          size.width * 1.2, size.height * 0.2, size.width, size.height * 0.45)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path1, paint);

    // Onda inferior izquierda
    final path2 = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.9, 0, size.height)
      ..close();
    canvas.drawPath(path2, paint..color = Colors.white.withValues(alpha: 0.04));

    // Círculos decorativos
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.12),
      size.width * 0.18,
      paint..color = Colors.white.withValues(alpha: 0.04),
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.85),
      size.width * 0.12,
      paint..color = Colors.white.withValues(alpha: 0.03),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
