import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BreastExamGuideOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const BreastExamGuideOverlay({super.key, required this.onClose});

  @override
  State<BreastExamGuideOverlay> createState() => _BreastExamGuideOverlayState();
}

class _BreastExamGuideOverlayState extends State<BreastExamGuideOverlay> {
  final List<Map<String, String>> _steps = [
    {
      "text": "¡Hola! Hacerte el autoexamen de mama es muy importante y súper fácil. Te explicaré cómo hacerlo paso a paso.",
      "image": "assets/images/mascot_happy.png"
    },
    {
      "text": "Primero, ponte frente a un espejo con los brazos a los lados. Observa si hay cambios en el tamaño, forma o color de la piel.",
      "image": "assets/images/mascot_presenting.png"
    },
    {
      "text": "Luego, levanta los brazos y busca los mismos cambios. Fíjate si sale algún líquido extraño de los pezones.",
      "image": "assets/images/mascot_thinking.png"
    },
    {
      "text": "Ahora, acuéstate. Usa tu mano derecha para examinar la mama izquierda, y la mano izquierda para la derecha.",
      "image": "assets/images/mascot_presenting.png"
    },
    {
      "text": "Usa las yemas de los tres dedos de en medio. Haz movimientos circulares desde afuera hacia el centro, tocando toda la mama con firmeza.",
      "image": "assets/images/mascot_happy.png"
    },
    {
      "text": "Finalmente, repite este mismo proceso de pie, idealmente en la ducha. ¡El agua y el jabón facilitan mucho sentir cualquier anomalía!",
      "image": "assets/images/mascot_happy.png"
    },
    {
      "text": "¡Eso es todo! Recuerda hacerlo cada mes, unos 7 a 10 días después de que inicie tu período. Si notas algo raro, consulta a tu médico.",
      "image": "assets/images/mascot_presenting.png"
    }
  ];

  int _currentStepIndex = 0;
  String _displayedText = "";
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _typingTimer?.cancel();
    _displayedText = "";
    _isTyping = true;
    
    final fullText = _steps[_currentStepIndex]["text"]!;
    int charIndex = 0;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (charIndex < fullText.length) {
        setState(() {
          _displayedText += fullText[charIndex];
          charIndex++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTyping = false;
        });
      }
    });
  }

  void _completeTyping() {
    _typingTimer?.cancel();
    setState(() {
      _displayedText = _steps[_currentStepIndex]["text"]!;
      _isTyping = false;
    });
  }

  void _nextStep() {
    if (_isTyping) {
      _completeTyping();
    } else {
      if (_currentStepIndex < _steps.length - 1) {
        setState(() {
          _currentStepIndex++;
        });
        _startTyping();
      } else {
        widget.onClose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _nextStep,
      child: Container(
        color: Colors.black.withValues(alpha:0.75),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Text Box
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ]
                ),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayedText,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: AnimatedOpacity(
                        opacity: _isTyping ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentStepIndex == _steps.length - 1 ? "Finalizar" : "Siguiente",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.orange,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Image Container
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Image.asset(
                      _steps[_currentStepIndex]["image"]!,
                      key: ValueKey<int>(_currentStepIndex),
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
