 import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';

/// Widget de diálogo estilo RPG con efecto typewriter.
/// Muestra el avatar de Bella a la izquierda y el texto se va revelando
/// caracter por caracter, tal como en los juegos RPG clásicos.
class RpgHelpDialog extends StatefulWidget {
  /// Texto que Bella dirá.
  final String message;

  /// Nombre que aparece en la placa.
  final String speakerName;

  /// Callback cuando el diálogo se cierra.
  final VoidCallback onDismiss;

  /// Velocidad del typewriter en milisegundos por caracter.
  final int charDelayMs;

  const RpgHelpDialog({
    super.key,
    required this.message,
    this.speakerName = 'Bella',
    required this.onDismiss,
    this.charDelayMs = 35,
  });

  @override
  State<RpgHelpDialog> createState() => _RpgHelpDialogState();
}

class _RpgHelpDialogState extends State<RpgHelpDialog>
    with SingleTickerProviderStateMixin {
  String _displayedText = '';
  int _charIndex = 0;
  Timer? _typeTimer;
  bool _isComplete = false;

  // Animación del triángulo parpadeante ▼
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _startTypewriter();
  }

  void _startTypewriter() {
    _typeTimer = Timer.periodic(
      Duration(milliseconds: widget.charDelayMs),
      (timer) {
        if (_charIndex < widget.message.length) {
          setState(() {
            _charIndex++;
            _displayedText = widget.message.substring(0, _charIndex);
          });
        } else {
          timer.cancel();
          setState(() {
            _isComplete = true;
          });
        }
      },
    );
  }

  void _onTap() {
    if (!_isComplete) {
      // Completar el texto instantáneamente al tocar
      _typeTimer?.cancel();
      setState(() {
        _displayedText = widget.message;
        _charIndex = widget.message.length;
        _isComplete = true;
      });
    } else {
      // Cerrar el diálogo
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).bellotaColors;

    // Colores del cuadro de diálogo acorde con la app
    final boxColor = colors.textoDark.withValues(alpha: 0.92);
    final borderColor = colors.chilero;
    final nameColor = colors.melon;
    final textColor = colors.nancite;
    final triangleColor = colors.melon;

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withValues(alpha: 0.25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Placa del nombre del personaje ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: boxColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                      border: Border(
                        top: BorderSide(color: borderColor, width: 2.5),
                        left: BorderSide(color: borderColor, width: 2.5),
                        right: BorderSide(color: borderColor, width: 2.5),
                      ),
                    ),
                    child: Text(
                      widget.speakerName,
                      style: TextStyle(
                        fontFamily: 'Estrella',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: nameColor,
                        letterSpacing: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Cuerpo del diálogo RPG ──
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 110),
                    decoration: BoxDecoration(
                      color: boxColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      border: Border.all(color: borderColor, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: borderColor.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // ── Avatar de Bella a la izquierda ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: borderColor.withValues(alpha: 0.6),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/bella_mascot.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        // ── Texto con efecto typewriter ──
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 14, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _displayedText,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    color: textColor,
                                    height: 1.45,
                                    letterSpacing: 0.3,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        offset: const Offset(0.5, 0.5),
                                        blurRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Triángulo parpadeante ▼ (estilo RPG) ──
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: AnimatedBuilder(
                        animation: _blinkAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _isComplete ? _blinkAnimation.value : 0.0,
                            child: Icon(
                              Icons.arrow_drop_down,
                              color: triangleColor,
                              size: 28,
                            ),
                          );
                        },
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
}
