import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/language_notifier.dart';
import '../database/database_helper.dart';
import '../theme/bellota_colors.dart';
import '../navigation/navigation_service.dart';
import '../core/constants/app_keys.dart';

/// Pantalla de seleccion de idioma de la cuenta.
/// Se muestra una sola vez, justo despues del registro y antes de la
/// Politica de Privacidad. El idioma queda grabado en la base de datos.
class AccountLanguageScreen extends StatefulWidget {
  const AccountLanguageScreen({super.key});

  @override
  State<AccountLanguageScreen> createState() => _AccountLanguageScreenState();
}

class _AccountLanguageScreenState extends State<AccountLanguageScreen> {
  bool _loading = false;

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
    if (_loading) return;

    if (lang == 'mi') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Idioma en Construcción',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Text(
            'La traducción completa al idioma Miskito se encuentra actualmente en desarrollo y se agregará en próximas actualizaciones.\n\nPor el momento, algunas secciones podrían mostrarse en español. ¿Deseas continuar?',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Elegir otro', style: TextStyle(color: Theme.of(context).bellotaColors.textoMedio)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).bellotaColors.chilero,
                foregroundColor: Theme.of(context).bellotaColors.blanco,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _loading = true);
    await languageNotifier.setLanguage(lang);
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(AppKeys.userId);
    if (userId != null) {
      await DatabaseHelper.instance.updateLanguagePref(userId, lang);
    }
    
    await prefs.setBool('account_language_done', true);
    if (!mounted) return;
    
    final destination = NavigationService.resolveHomeScreen(prefs);
    NavigationService.goReplace(context, destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).bellotaColors.chilero,
      body: Stack(
        children: [
          // Fondo decorativo idéntico al LanguageSelectionScreen original
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
                    ),
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
                      // Border idéntico a LanguageSelectionScreen
                      border: Border(
                        top: BorderSide(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.25), width: 1),
                        left: BorderSide(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.25), width: 1),
                        right: BorderSide(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.25), width: 1),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Chip "Paso 1 de 5"
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Paso 1 de 5',
                            style: GoogleFonts.poppins(
                              fontSize: 12, 
                              color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.9), 
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Elige el idioma para tu cuenta",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).bellotaColors.blanco,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Esta será la configuración permanente",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.75),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 36),
                        
                        _buildLangCard('es', 'Español', 'Hola'),
                        const SizedBox(height: 16),
                        _buildLangCard('mi', 'Miskitu', 'Naksa'),
                        
                        const Spacer(),
                        if (_loading)
                          Center(
                            child: SizedBox(
                              height: 24, 
                              width: 24, 
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5, 
                                color: Theme.of(context).bellotaColors.blanco,
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
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).bellotaColors.blanco,
                      ),
                    ),
                    if (code == 'mi') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2), 
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: Text(
                          'Próximamente', 
                          style: GoogleFonts.poppins(
                            fontSize: 10, 
                            color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.9), 
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      ),
                    ],
                  ],
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
