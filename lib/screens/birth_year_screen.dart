import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/language_notifier.dart';
import '../theme/bellota_colors.dart';
import '../widgets/bellota_top_actions.dart';
import '../navigation/navigation_service.dart';
import 'onboarding_screen.dart';

class BirthYearScreen extends StatefulWidget {
  const BirthYearScreen({super.key});

  @override
  State<BirthYearScreen> createState() => _BirthYearScreenState();
}

class _BirthYearScreenState extends State<BirthYearScreen> {
  late int _selectedYear;
  final int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    // Default to roughly 25 years old
    _selectedYear = _currentYear - 25;
    
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _handleContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('birth_year', _selectedYear);
    // Also save age for backward compatibility
    await prefs.setString('user_age', (_currentYear - _selectedYear).toString());
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const OnboardingScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final years = List.generate(61, (index) => _currentYear - 70 + index).reversed.toList();
    final initialIndex = years.indexOf(_selectedYear);

    return Scaffold(
      backgroundColor: Theme.of(context).bellotaColors.chilero,
      body: Stack(
        children: [
          // Fondo decorativo
          Positioned.fill(
            child: CustomPaint(painter: _BackgroundPainter(Theme.of(context).bellotaColors.blanco)),
          ),

          // Top Actions
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: BellotaTopActions(
                showSettings: false,
                onLanguagePressed: () => languageNotifier.toggle(),
                onTalkBackPressed: () {},
              ),
            ),
          ),

          // Main Content
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
                      children: [
                        Text(
                          "¿En qué año naciste?",
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).bellotaColors.blanco,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Esto nos ayuda a personalizar tu experiencia",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.75),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        
                        // Wheel Picker
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Centro selector highlight (glassmorphism sutil)
                              Container(
                                height: 56,
                                width: size.width * 0.6,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2)),
                                ),
                              ),
                              ListWheelScrollView.useDelegate(
                                itemExtent: 56,
                                diameterRatio: 2.5,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    _selectedYear = years[index];
                                  });
                                  HapticFeedback.selectionClick();
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  builder: (context, index) {
                                    final year = years[index];
                                    final isSelected = year == _selectedYear;
                                    return Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: 200.ms,
                                        style: GoogleFonts.poppins(
                                          fontSize: isSelected ? 32 : 22,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected 
                                            ? Theme.of(context).bellotaColors.blanco 
                                            : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.5),
                                        ),
                                        child: Text(year.toString()),
                                      ),
                                    );
                                  },
                                  childCount: years.length,
                                ),
                                controller: FixedExtentScrollController(initialItem: initialIndex),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // CTA Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).bellotaColors.melon,
                                  Theme.of(context).bellotaColors.chilero,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.5),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _handleContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              ),
                              child: Text(
                                "Continuar",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).bellotaColors.blanco,
                                ),
                              ),
                            ),
                          ),
                        ),
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
