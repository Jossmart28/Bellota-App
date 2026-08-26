import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  late AnimationController _bgController;
  late AnimationController _contentController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ─── Contenido de los slides ───
  final List<_SlideData> _slides = const [
    _SlideData(
      gradient: [Color(0xFFD35D53), Color(0xFFE8897A)],
      icon: Icons.favorite_rounded,
      emoji: '🌸',
      title: 'Conoce tu ciclo',
      subtitle: 'Registra cada día y descubre\nlos patrones que tu cuerpo te comunica.',
      decoration1: Color(0xFFFF8A80),
      decoration2: Color(0xFFFFCDD2),
    ),
    _SlideData(
      gradient: [Color(0xFFEE8658), Color(0xFFF7AD78)],
      icon: Icons.edit_note_rounded,
      emoji: '📝',
      title: 'Registra cómo te sientes',
      subtitle: 'Síntomas, flujo, humor y más —\ntodo en un solo lugar, cada día.',
      decoration1: Color(0xFFFFCC80),
      decoration2: Color(0xFFFFF3E0),
    ),
    _SlideData(
      gradient: [Color(0xFF7A9EB5), Color(0xFFB0C4D8)],
      icon: Icons.insights_rounded,
      emoji: '✨',
      title: 'Predicciones inteligentes',
      subtitle: 'Bellota aprende de tu historial\ny te avisa cuándo esperar tu próximo período.',
      decoration1: Color(0xFF90CAF9),
      decoration2: Color(0xFFE3F2FD),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _contentController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic));

    _bgController.forward();
    _contentController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _contentController.dispose();
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
    final slide = _slides[_currentPage];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: slide.gradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Fondo Cottagecore decorativo ──
              _buildCottagecoreBg(size, slide),

              Column(
                children: [
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo pequeño
                        Image.asset('assets/images/logo_white.png', height: 32,
                            errorBuilder: (_, __, ___) => const Icon(Icons.circle, color: Colors.white30, size: 32)),
                        // Saltar
                        TextButton(
                          onPressed: _finish,
                          child: Text(
                            'Saltar',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Slides ──
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        _contentController.forward(from: 0);
                      },
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        return FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: _buildSlideContent(_slides[index], size),
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Dots + Botón ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                    child: Column(
                      children: [
                        // Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_slides.length, (i) {
                            final isActive = i == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 32 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 28),

                        // Botón CTA
                        GestureDetector(
                          onTap: _goToNext,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            height: 58,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentPage < _slides.length - 1 ? 'Continuar' : 'Comenzar',
                                    style: GoogleFonts.poppins(
                                      color: slide.gradient.first,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _currentPage < _slides.length - 1
                                        ? Icons.arrow_forward_rounded
                                        : Icons.check_circle_rounded,
                                    color: slide.gradient.first,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlideContent(_SlideData slide, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Imagen directa (sin cuadrado) ──
          Image.asset(
            'assets/images/bellu_ginecologa.png',
            height: size.width * 0.6,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Text(
              slide.emoji,
              style: const TextStyle(fontSize: 130),
            ),
          ),

          const SizedBox(height: 50),

          // ── Título ──
          Text(
            slide.title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // ── Subtítulo ──
          Text(
            slide.subtitle,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 15,
              height: 1.65,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Fondo de Flores Cottagecore ──
  Widget _buildCottagecoreBg(Size size, _SlideData slide) {
    return IgnorePointer(
      child: Stack(
        children: [
          _buildFloatingFlower(size, '🌸', 0.05, 0.08, 0.2, 50),
          _buildFloatingFlower(size, '🌿', 0.8, 0.12, -0.3, 60),
          _buildFloatingFlower(size, '🌼', 0.15, 0.65, 0.15, 45),
          _buildFloatingFlower(size, '🍄', 0.85, 0.55, -0.2, 40),
          _buildFloatingFlower(size, '🌷', -0.05, 0.35, 0.4, 70),
          _buildFloatingFlower(size, '🌿', 0.9, 0.3, -0.4, 55),
          _buildFloatingFlower(size, '🌻', 0.45, -0.05, 0.1, 80),
          _buildFloatingFlower(size, '🦋', 0.25, 0.85, -0.1, 35),
          _buildFloatingFlower(size, '🌾', 0.75, 0.8, 0.2, 50),
        ],
      ),
    );
  }

  Widget _buildFloatingFlower(Size size, String emoji, double leftRatio, double topRatio, double angle, double iconSize) {
    return Positioned(
      left: size.width * leftRatio,
      top: size.height * topRatio,
      child: Transform.rotate(
        angle: angle,
        child: Opacity(
          opacity: 0.2, // translúcido para que sea un fondo sutil
          child: Text(
            emoji,
            style: TextStyle(fontSize: iconSize),
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  final List<Color> gradient;
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final Color decoration1;
  final Color decoration2;

  const _SlideData({
    required this.gradient,
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.decoration1,
    required this.decoration2,
  });
}
