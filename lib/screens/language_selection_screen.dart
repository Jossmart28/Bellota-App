import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/language_notifier.dart';
import '../theme/bellota_colors.dart';
import '../navigation/navigation_service.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _selectLanguage(String lang) async {
    await languageNotifier.setLanguage(lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_setup_done', true);

    if (!mounted) return;
    final destination = NavigationService.resolveRootScreen(prefs);
    NavigationService.goReplace(context, destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).bellotaColors.chilero,
      body: Stack(
        children: [
          // Fondo decorativo
          Positioned.fill(
            child: CustomPaint(painter: _BackgroundPainter(Theme.of(context).bellotaColors.blanco)),
          ),

          // Contenido Principal
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: const Image(
                      image: AssetImage('assets/images/logo_white.png'),
                      width: 180,
                      fit: BoxFit.contain,
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.12),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                      border: Border(
                        top: BorderSide(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.25), width: 1),
                        left: BorderSide(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.25), width: 1),
                        right: BorderSide(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.25), width: 1),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Elige tu idioma",
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).bellotaColors.blanco,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Choose your language",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.75),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        
                        _buildLangCard('es', 'Español', 'Hola'),
                        const SizedBox(height: 16),
                        _buildLangCard('en', 'English', 'Hello'),
                        const SizedBox(height: 16),
                        _buildLangCard('mi', 'Miskitu', 'Naksa'),
                        
                        const Spacer(),
                      ],
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.4, curve: Curves.easeOutCubic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangCard(String code, String name, String subtitle) {
    return GestureDetector(
      onTap: () => _selectLanguage(code),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).bellotaColors.blanco,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Theme.of(context).bellotaColors.blanco, size: 20),
          ],
        ),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final Color overlayColor;
  const _BackgroundPainter(this.overlayColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = overlayColor.withValues(alpha: 0.05)
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
    canvas.drawPath(path2, paint..color = overlayColor.withValues(alpha: 0.04));

    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.12), size.width * 0.18, paint..color = overlayColor.withValues(alpha: 0.04));
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.85), size.width * 0.12, paint..color = overlayColor.withValues(alpha: 0.03));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
