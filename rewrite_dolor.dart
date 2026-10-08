import 'dart:io';

void main() {
  final file = File('lib/presentation/screens/health_log/dolor_sintomatologia_screen.dart');
  final content = file.readAsStringSync();

  final buildStartIndex = content.indexOf('  Widget build(BuildContext context) {');
  if (buildStartIndex == -1) {
    print("Could not find build method.");
    return;
  }

  final newBuildMethod = '''
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        final colors = Theme.of(context).bellotaColors;
        return Scaffold(
          backgroundColor: colors.basilica,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(colors),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      // Pain Card
                      _buildPainCard(colors),
                      const SizedBox(height: 12),
                      
                      // Tratamiento Card
                      _buildTratamientoCard(colors, lang),
                      const SizedBox(height: 12),
                      
                      // Otros datos Card
                      _buildOtrosDatosCard(colors, lang),
                      const SizedBox(height: 12),
                      
                      // Autoexamen Card
                      _buildAutoexamenCard(colors, lang),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BellotaColors colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.chilero,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.chilero.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
          Text(
            'Dolor y síntomas',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          GestureDetector(
            onTap: _save,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Confirmar',
                style: GoogleFonts.poppins(color: colors.chilero, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPainCard(BellotaColors colors) {
    // Determine color based on pain level
    Color headerColor = colors.textoMedio;
    String textDesc = 'Sin dolor';
    if (_nivelDolor > 0 && _nivelDolor <= 3) { headerColor = Colors.orange; textDesc = 'Leve'; }
    else if (_nivelDolor > 3 && _nivelDolor <= 6) { headerColor = colors.melon; textDesc = 'Moderado'; }
    else if (_nivelDolor > 6) { headerColor = colors.chilero; textDesc = 'Fuerte'; }
    if (_nivelDolor == 0) headerColor = Colors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colors.textoMedio.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ¿Cuánto duele?
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('¿Cuánto duele?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textoDark)),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: '\$textDesc • ', style: GoogleFonts.poppins(color: headerColor, fontWeight: FontWeight.w600, fontSize: 13)),
                    TextSpan(text: '\${_nivelDolor.toInt()}', style: GoogleFonts.poppins(color: headerColor, fontWeight: FontWeight.bold, fontSize: 18)),
                    TextSpan(text: '/10', style: GoogleFonts.poppins(color: headerColor.withOpacity(0.6), fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Acorn slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(10, (index) {
              final val = index + 1;
              final isSelected = val <= _nivelDolor;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _nivelDolor = val.toDouble());
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/bellota_outline_white.png',
                        width: 22,
                        height: 22,
                        color: isSelected ? const Color(0xFFDAB398) : colors.textoMedio.withOpacity(0.2),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$val',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? const Color(0xFFDAB398) : colors.textoMedio.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          
          // Carácter
          Text('CARÁCTER', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: colors.textoDark)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _caracterDolorKey = 'incapacitating'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _caracterDolorKey == 'incapacitating' ? colors.nancite : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _caracterDolorKey == 'incapacitating' ? const Color(0xFFDAB398) : colors.nancite),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.block_rounded, color: _caracterDolorKey == 'incapacitating' ? const Color(0xFF6B3A22) : colors.textoMedio, size: 18),
                        const SizedBox(width: 8),
                        Text('Incapacitante', style: GoogleFonts.poppins(color: _caracterDolorKey == 'incapacitating' ? const Color(0xFF6B3A22) : colors.textoMedio, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _caracterDolorKey = 'not_incapacitating'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _caracterDolorKey == 'not_incapacitating' ? colors.nancite : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _caracterDolorKey == 'not_incapacitating' ? const Color(0xFFDAB398) : colors.nancite),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_walk_rounded, color: _caracterDolorKey == 'not_incapacitating' ? const Color(0xFF6B3A22) : colors.textoMedio, size: 18),
                        const SizedBox(width: 8),
                        Text('No incapacitante', style: GoogleFonts.poppins(color: _caracterDolorKey == 'not_incapacitating' ? const Color(0xFF6B3A22) : colors.textoMedio, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionCard({
    required BellotaColors colors,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colors.textoMedio.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          iconColor: colors.textoDark,
          collapsedIconColor: colors.textoDark,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: colors.textoDark),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTratamientoCard(BellotaColors colors, String lang) {
    return _buildAccordionCard(
      colors: colors,
      title: 'Tratamiento',
      icon: Icons.medication_rounded,
      iconColor: colors.chilero.withOpacity(0.8),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: _tratamientoOptions.map((opt) {
            final isSelected = _tratamientoKey == opt;
            return GestureDetector(
              onTap: () => setState(() => _tratamientoKey = opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.nancite : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? const Color(0xFFDAB398) : colors.nancite),
                ),
                child: Text(
                  AppTranslations.get('registration_form', opt, lang, context: context),
                  style: GoogleFonts.poppins(
                    color: isSelected ? const Color(0xFF6B3A22) : colors.textoDark,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOtrosDatosCard(BellotaColors colors, String lang) {
    return _buildAccordionCard(
      colors: colors,
      title: 'Otros datos',
      icon: Icons.science_rounded,
      iconColor: colors.melon,
      children: [
        Text('Temperatura basal', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: colors.textoDark)),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: _basalTemp?.toString() ?? ''),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Ej: 36.5',
            suffixText: '°C',
            filled: true,
            fillColor: colors.nancite,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (val) {
            final numVal = double.tryParse(val.replaceAll(',', '.'));
            if (numVal != null && numVal >= 35.0 && numVal <= 42.0) _basalTemp = numVal;
            else if (val.isEmpty) _basalTemp = null;
          },
        ),
        const SizedBox(height: 16),
        Text('Test LH', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: colors.textoDark)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _lhTestOptions.map((opt) {
            final isSelected = _lhTestResult == opt;
            String label = opt == 'negative' ? 'Negativo' : opt == 'positive' ? 'Positivo' : 'Pico';
            return FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => setState(() => _lhTestResult = isSelected ? null : opt),
              selectedColor: colors.melon.withOpacity(0.2),
              backgroundColor: colors.nancite,
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAutoexamenCard(BellotaColors colors, String lang) {
    return _buildAccordionCard(
      colors: colors,
      title: 'Autoexamen de mama',
      icon: Icons.favorite_rounded,
      iconColor: const Color(0xFFDE8B90),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFDE8B90).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFB45A61), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cada mes, 7 a 10 días después del inicio del período.',
                  style: GoogleFonts.poppins(color: const Color(0xFFB45A61), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: _autoexamenMamaOptions.map((opt) {
            final isSelected = _autoexamenMamaKey == opt;
            IconData iconData = Icons.circle_outlined;
            if (opt == 'breast_normal') iconData = Icons.check_circle_rounded;
            else if (opt == 'breast_lump') iconData = Icons.warning_amber_rounded;
            else if (opt == 'breast_localized_pain') iconData = Icons.location_on_rounded;
            else if (opt == 'breast_skin_change') iconData = Icons.layers_rounded;
            else if (opt == 'breast_discharge') iconData = Icons.water_drop_rounded;
            else if (opt == 'breast_pending') iconData = Icons.schedule_rounded;

            return GestureDetector(
              onTap: () => setState(() => _autoexamenMamaKey = opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? (opt == 'breast_normal' ? Colors.green.withOpacity(0.1) : const Color(0xFFDE8B90).withOpacity(0.1)) : colors.nancite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? (opt == 'breast_normal' ? Colors.green.withOpacity(0.3) : const Color(0xFFB45A61).withOpacity(0.3)) : colors.nancite),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      iconData, 
                      color: isSelected ? (opt == 'breast_normal' ? Colors.green : const Color(0xFFB45A61)) : colors.textoMedio, 
                      size: 16
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppTranslations.get('registration_form', opt, lang, context: context),
                      style: GoogleFonts.poppins(
                        color: isSelected ? (opt == 'breast_normal' ? Colors.green.shade800 : const Color(0xFFB45A61)) : colors.textoDark,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
''';

  final newContent = content.substring(0, buildStartIndex) + newBuildMethod;
  file.writeAsStringSync(newContent);
  print("Updated dolor_sintomatologia_screen.dart successfully.");
}
