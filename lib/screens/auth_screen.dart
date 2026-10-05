import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/bellota_colors.dart';

class AuthScreen extends StatefulWidget {
  final Widget targetScreen;
  const AuthScreen({super.key, required this.targetScreen});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _message = 'Protegiendo tu privacidad...';

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _message = 'Autenticando...';
      });

      authenticated = await auth.authenticate(
        localizedReason: 'Desbloquea Bellota para ver tu registro',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      
      setState(() {
        _isAuthenticating = false;
      });
      
    } on PlatformException catch (e) {
      debugPrint("Error de autenticaci�n biom�trica: $e");
      setState(() {
        _isAuthenticating = false;
        _message = 'Error al autenticar.\nPresiona el candado para reintentar.';
      });
      return;
    }

    if (!mounted) return;

    if (authenticated) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: 600.ms,
          pageBuilder: (_, __, ___) => widget.targetScreen,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      setState(() {
        _message = 'Autenticaci�n cancelada.\nPresiona el candado para reintentar.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<BellotaColors>() ?? BellotaColors.light;
    
    return Scaffold(
      backgroundColor: colors.chilero, // Fondo suave de privacidad
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Candado o mascota interactiva
            GestureDetector(
              onTap: _isAuthenticating ? null : _authenticate,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: colors.blanco,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.textoDark.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/bella_mascot.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ).animate(target: _isAuthenticating ? 1 : 0)
               .shimmer(duration: 1.seconds, color: colors.melon)
               .scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05)),
            ),
            const SizedBox(height: 32),
            Text(
              "¡Bienvenida de vuelta!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colors.blanco,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.5, end: 0),
            const SizedBox(height: 12),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.blanco.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
          ],
        ),
      ),
    );
  }
}

