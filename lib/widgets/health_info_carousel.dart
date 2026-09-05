import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/bellota_colors.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Modelo de artÃ­culo
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ArticleData {
  final String source;
  final String title;
  final String summary;
  final String url;
  final Color accentColor;
  // Ruta del banner. Coloca tus imÃ¡genes en: assets/images/
  // Nombres esperados: banner_minsa.png  banner_el19.png  banner_pddh.png
  final String bannerAsset;

  const _ArticleData({
    required this.source,
    required this.title,
    required this.summary,
    required this.url,
    required this.accentColor,
    required this.bannerAsset,
  });
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Datos de los tres artÃ­culos
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final List<_ArticleData> _articles = [
  _ArticleData(
    source: 'MINSA',
    title: 'Atenciones en el Centro de AtenciÃ³n a la Mujer',
    summary:
        'Conoce los servicios de salud que el MINSA brinda gratuitamente a la mujer nicaragÃ¼ense en sus centros especializados de atenciÃ³n integral.',
    url:
        'https://www.minsa.gob.ni/centro-de-medios/noticias/estas-son-las-atenciones-brindadas-en-el-centro-de-atencion-la-mujer',
    accentColor: const Color(0xFFD35D53),
    bannerAsset: 'assets/images/banner_minsa.png',
  ),
  _ArticleData(
    source: 'El 19 Digital',
    title: 'RestituciÃ³n del derecho en la salud de la mujer',
    summary:
        'La revoluciÃ³n tiene rostro de mujer: Nicaragua avanza en la restituciÃ³n de derechos en salud femenina a travÃ©s de polÃ­ticas pÃºblicas.',
    url:
        'https://www.el19digital.com/articulos/ver/149975-restitucion-del-derecho-en-la-salud-de-la-mujer-la-revolucion-tiene-rostro-de-mujer',
    accentColor: const Color(0xFFEE8658),
    bannerAsset: 'assets/images/banner_minsa.png',
  ),
  _ArticleData(
    source: 'PDDH',
    title: 'Derechos de la mujer en salud â€” ProcuradurÃ­a',
    summary:
        'La ProcuradurÃ­a para la Defensa de los Derechos Humanos aborda el marco normativo que garantiza el derecho a la salud integral de la mujer.',
    url: 'https://www.pddh.gob.ni/?p=4652',
    accentColor: const Color(0xFF7E8F6F),
    bannerAsset: 'assets/images/banner_pddh.png',
  ),
];

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Widget principal: HealthInfoCarousel
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class HealthInfoCarousel extends StatefulWidget {
  const HealthInfoCarousel({super.key});

  @override
  State<HealthInfoCarousel> createState() => _HealthInfoCarouselState();
}

class _HealthInfoCarouselState extends State<HealthInfoCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _articles.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  static Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // â”€â”€ Carrusel â”€â”€
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _articles.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) => _ArticleCard(
              data: _articles[index],
              onReadPressed: () => _openUrl(_articles[index].url),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // â”€â”€ Puntos indicadores â”€â”€
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _articles.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _currentPage ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == _currentPage
                    ? Theme.of(context).bellotaColors.chilero
                    : Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Tarjeta individual
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ArticleCard extends StatelessWidget {
  final _ArticleData data;
  final VoidCallback onReadPressed;

  const _ArticleCard({required this.data, required this.onReadPressed});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: 14, left: 2, top: 2, bottom: 2),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bellotaColors.blanco,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: data.accentColor.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Banner de imagen â”€â”€
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 118,
                    width: double.infinity,
                    child: Image.asset(
                      data.bannerAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => Container(
                        color: data.accentColor.withValues(alpha: 0.13),
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 38,
                            color: data.accentColor.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Chip de fuente sobre la imagen
                  Positioned(
                    top: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: data.accentColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        data.source,
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // â”€â”€ Cuerpo: tÃ­tulo + resumen + botÃ³n â”€â”€
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).bellotaColors.textoDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        data.summary,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                          height: 1.5,
                          color: Theme.of(context).bellotaColors.textoMedio,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // BotÃ³n "Leer completo" con Material+InkWell
                    Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: onReadPressed,
                          borderRadius: BorderRadius.circular(20),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).bellotaColors.melon,
                                  Theme.of(context).bellotaColors.chilero,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).bellotaColors.chilero
                                      .withValues(alpha: 0.30),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Leer completo',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
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

