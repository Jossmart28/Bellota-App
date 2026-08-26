import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import 'calendar_tour_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  final List<_OnboardSlide> _slides = const [
    _OnboardSlide(
      accentColor: BellotaColors.chilero,
      title: 'Conoce tu ciclo',
      subtitle: 'Registra cada día de tu ciclo y descubre los patrones que tu cuerpo te comunica.',
    ),
    _OnboardSlide(
      accentColor: BellotaColors.melon,
      title: 'Registra tus síntomas',
      subtitle: 'Anota cómo te sientes cada día. Síntomas, flujo y más — todo en un solo lugar.',
    ),
    _OnboardSlide(
      accentColor: BellotaColors.asuncion,
      title: 'Predicciones inteligentes',
      subtitle: 'Bellota aprende de tu historial y te avisa cuándo esperar tu próximo período.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _slides.length,
      (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 600)),
    );
    _fadeAnims = _controllers.map((c) =>
      CurvedAnimation(parent: c, curve: Curves.easeOut) as Animation<double>).toList();
    _slideAnims = _controllers.map((c) =>
      Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic))).toList();

    _controllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const CalendarTourScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BellotaColors.basilica,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ──
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, right: 20),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Saltar',
                    style: TextStyle(
                      color: BellotaColors.textoMedio.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // ── Slides ──
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  _controllers[index].forward(from: 0);
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return FadeTransition(
                    opacity: _fadeAnims[index],
                    child: SlideTransition(
                      position: _slideAnims[index],
                      child: _buildSlide(context, slide),
                    ),
                  );
                },
              ),
            ),

            // ── Dots + Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? _slides[_currentPage].accentColor
                              : _slides[_currentPage].accentColor.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // CTA Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _slides[_currentPage].accentColor,
                          _slides[_currentPage].accentColor.withOpacity(0.75),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _slides[_currentPage].accentColor.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: _goToNext,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(
                        _currentPage < _slides.length - 1 ? 'Continuar' : 'Empezar',
                        style: const TextStyle(
                          color: BellotaColors.blanco,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(BuildContext context, _OnboardSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image placeholder
          SizedBox(
            width: 220,
            height: 220,
            child: Image.asset(
              'assets/images/bellu_ginecologa.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            slide.title,
            style: TextStyle(
              color: BellotaColors.textoDark,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            slide.subtitle,
            style: TextStyle(
              color: BellotaColors.textoMedio.withOpacity(0.85),
              fontSize: 15,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardSlide {
  final Color accentColor;
  final String title;
  final String subtitle;

  const _OnboardSlide({
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });
}
