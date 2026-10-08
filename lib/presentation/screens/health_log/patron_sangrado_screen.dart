import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';

class PatronSangradoScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const PatronSangradoScreen({super.key, required this.initialData});

  @override
  State<PatronSangradoScreen> createState() => _PatronSangradoScreenState();
}

class _PatronSangradoScreenState extends State<PatronSangradoScreen> {
  late String _intensidadFlujoKey;
  late String _coagulosKey;
  late String _manchadoKey;
  late TextEditingController _manchadoDiasController;
  late Set<String> _sintomasSexualesKeys;
  late String _colorSangradoKey;

  final List<Map<String, dynamic>> _sections = [
    {
      'titleKey': 'Intensidad del Flujo Menstrual',
      'options': ['light_flow', 'moderate_flow', 'heavy_flow'],
      'isSingleChoice': true,
      'field': 'intensidadFlujoKey',
    },
    {
      'titleKey': 'Color del Sangrado',
      'options': ['bright_red', 'dark_red', 'brown', 'pink'],
      'isSingleChoice': true,
      'field': 'colorSangradoKey',
    },
    {
      'titleKey': 'CoÃ¡gulos',
      'options': ['never', 'occasional', 'frequent'],
      'isSingleChoice': true,
      'field': 'coagulosKey',
    },
    {
      'titleKey': 'Manchado Intermenstrual',
      'options': ['no', 'yes'],
      'isSingleChoice': true,
      'field': 'manchadoKey',
    }
  ];

  @override
  void initState() {
    super.initState();
    _intensidadFlujoKey = widget.initialData['intensidadFlujoKey'] ?? 'moderate_flow';
    _coagulosKey = widget.initialData['coagulosKey'] ?? 'never';
    _manchadoKey = widget.initialData['manchadoKey'] ?? 'no';
    _manchadoDiasController = TextEditingController(text: widget.initialData['manchadoDias'] ?? '');
    
    if (widget.initialData['sintomasSexualesKeys'] != null) {
      _sintomasSexualesKeys = Set<String>.from(widget.initialData['sintomasSexualesKeys']);
    } else {
      _sintomasSexualesKeys = {'none'};
    }
    _colorSangradoKey = widget.initialData['colorSangradoKey'] ?? 'bright_red';
  }

  @override
  void dispose() {
    _manchadoDiasController.dispose();
    super.dispose();
  }

  void _save() {
    final lang = languageNotifier.currentLang;
    Navigator.pop(context, {
      'intensidadFlujoKey': _intensidadFlujoKey,
      'coagulosKey': _coagulosKey,
      'manchadoKey': _manchadoKey,
      'manchadoDias': _manchadoDiasController.text.trim(),
      'sintomasSexualesKeys': _sintomasSexualesKeys.toList(),
      'colorSangradoKey': _colorSangradoKey,
      // Backwards compatibility if still needed somewhere
      'intensidadFlujo': AppTranslations.get('registration_form', _intensidadFlujoKey, lang, context: context),
      'coagulos': AppTranslations.get('registration_form', _coagulosKey, lang, context: context),
      'manchado': AppTranslations.get('registration_form', _manchadoKey, lang, context: context),
      'sintomasSexuales': _sintomasSexualesKeys.map((k) => AppTranslations.get('registration_form', k, lang, context: context)).join(', '),
    });
  }

  void _setIntensity(String key) => _toggleOption('intensidadFlujoKey', key, true);
  void _setClots(String key) => _toggleOption('coagulosKey', key, true);
  void _toggleSpotting(String key) => _toggleOption('manchadoKey', key, true);

  void _toggleOption(String field, String key, bool isSingleChoice) {
    HapticFeedback.lightImpact();
    setState(() {
      if (isSingleChoice) {
        switch (field) {
          case 'intensidadFlujoKey': _intensidadFlujoKey = key; break;
          case 'colorSangradoKey': _colorSangradoKey = key; break;
          case 'coagulosKey': _coagulosKey = key; break;
          case 'manchadoKey': _manchadoKey = key; break;
        }
      } else {
        if (key == 'none') {
          _sintomasSexualesKeys.clear();
          _sintomasSexualesKeys.add('none');
        } else {
          _sintomasSexualesKeys.remove('none');
          if (_sintomasSexualesKeys.contains(key)) {
            _sintomasSexualesKeys.remove(key);
            if (_sintomasSexualesKeys.isEmpty) _sintomasSexualesKeys.add('none');
          } else {
            _sintomasSexualesKeys.add(key);
          }
        }
      }
    });
  }

  bool _isSelected(String field, String key, bool isSingleChoice) {
    if (isSingleChoice) {
      switch (field) {
        case 'intensidadFlujoKey': return _intensidadFlujoKey == key;
        case 'colorSangradoKey': return _colorSangradoKey == key;
        case 'coagulosKey': return _coagulosKey == key;
        case 'manchadoKey': return _manchadoKey == key;
        default: return false;
      }
    } else {
      return _sintomasSexualesKeys.contains(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        final colors = Theme.of(context).bellotaColors;
        
        return Scaffold(
          backgroundColor: const Color(0xFFFCF3E5),
          body: Column(
            children: [
              _buildHeader(context, colors),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  children: [
                    _buildSectionHeader(
                      title: 'Intensidad del flujo menstrual',
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFFBC5854),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        _buildOptionRow(
                          title: 'Leve',
                          subtitle: 'Menos de 3 protectores al día',
                          isSelected: _intensidadFlujoKey == 'light_flow',
                          onTap: () => _setIntensity('light_flow'),
                          leading: _buildDrops(1, colors),
                          isFirst: true,
                        ),
                        _buildDivider(),
                        _buildOptionRow(
                          title: 'Moderado',
                          subtitle: 'De 3 a 5 protectores al día',
                          isSelected: _intensidadFlujoKey == 'moderate_flow',
                          onTap: () => _setIntensity('moderate_flow'),
                          leading: _buildDrops(2, colors),
                        ),
                        _buildDivider(),
                        _buildOptionRow(
                          title: 'Abundante',
                          subtitle: 'Más de 5 protectores al día',
                          isSelected: _intensidadFlujoKey == 'heavy_flow',
                          onTap: () => _setIntensity('heavy_flow'),
                          leading: _buildDrops(3, colors),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader(
                      title: 'Color del sangrado',
                      icon: Icons.bloodtype_rounded,
                      color: const Color(0xFF9E3A39),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        _buildOptionRow(
                          title: 'Rojo brillante',
                          isSelected: _colorSangradoKey == 'bright_red',
                          onTap: () => _toggleOption('colorSangradoKey', 'bright_red', true),
                          leading: _buildColorCircle(const Color(0xFFE04F43)),
                          isFirst: true,
                        ),
                        _buildDivider(),
                        _buildOptionRow(
                          title: 'Rojo oscuro',
                          isSelected: _colorSangradoKey == 'dark_red',
                          onTap: () => _toggleOption('colorSangradoKey', 'dark_red', true),
                          leading: _buildColorCircle(const Color(0xFF7C1B1E)),
                        ),
                        _buildDivider(),
                        _buildOptionRow(
                          title: 'Marrón',
                          isSelected: _colorSangradoKey == 'brown',
                          onTap: () => _toggleOption('colorSangradoKey', 'brown', true),
                          leading: _buildColorCircle(const Color(0xFF673D26)),
                        ),
                        _buildDivider(),
                        _buildOptionRow(
                          title: 'Rosado',
                          isSelected: _colorSangradoKey == 'pink',
                          onTap: () => _toggleOption('colorSangradoKey', 'pink', true),
                          leading: _buildColorCircle(const Color(0xFFF3A6B4)),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader(
                      title: 'Coágulos',
                      icon: Icons.grain_rounded,
                      color: const Color(0xFF673D26),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        _buildOptionRow(
                          title: 'Nunca',
                          subtitle: 'Sin coágulos',
                          isSelected: _coagulosKey == 'never',
                          onTap: () => _setClots('never'),
                          isFirst: true,
                        ),
                        _buildDivider(),
                        _buildOptionRow(
                          title: 'Ocasional',
                          subtitle: 'Pequeños, de vez en cuando',
                          isSelected: _coagulosKey == 'occasional',
                          onTap: () => _setClots('occasional'),
                        ),
                        _buildDivider(),
                        _buildOptionRow(
                          title: 'Frecuente',
                          subtitle: 'Grandes o seguidos',
                          isSelected: _coagulosKey == 'frequent',
                          onTap: () => _setClots('frequent'),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader(
                      title: 'Manchado intermenstrual',
                      subtitle: 'Sangrado leve fuera de tu período',
                      icon: Icons.water_drop_outlined,
                      color: const Color(0xFFE3885C),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        _buildOptionRow(
                          title: 'No',
                          isSelected: _manchadoKey == 'no',
                          onTap: () => _toggleSpotting('no'),
                          isFirst: true,
                        ),
                        _buildDivider(),
                        _buildOptionRow(
                          title: 'Sí',
                          isSelected: _manchadoKey == 'yes',
                          onTap: () => _toggleSpotting('yes'),
                          isLast: true,
                        ),
                      ],
                    ),
                    if (_manchadoKey == 'yes') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: colors.textoMedio.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: TextField(
                          controller: _manchadoDiasController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Días de manchado',
                            hintText: 'Ej. 3',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, dynamic colors) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFDA6A62),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const Text(
            'Patrón de\nsangrado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              height: 1.1,
              fontFamily: 'Outfit',
            ),
          ),
          GestureDetector(
            onTap: _save,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Confirmar',
                style: TextStyle(color: Color(0xFFDA6A62), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, String? subtitle, required IconData icon, required Color color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF4A342E),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  fontFamily: 'Outfit',
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8A6C62),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 20, endIndent: 20, color: Colors.black.withOpacity(0.06));
  }

  Widget _buildOptionRow({
    required String title,
    String? subtitle,
    Widget? leading,
    required bool isSelected,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(24) : Radius.zero,
          bottom: isLast ? const Radius.circular(24) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              if (leading != null) ...[
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, val, child) {
                    return Transform.scale(scale: val, child: child);
                  },
                  child: leading,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF4A342E),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF8A6C62),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.circle_outlined,
                color: isSelected ? const Color(0xFFBC5854) : Colors.black.withOpacity(0.15),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrops(int filledCount, dynamic colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Icon(
          Icons.water_drop_rounded,
          color: index < filledCount ? const Color(0xFFBC5854) : const Color(0xFFBC5854).withOpacity(0.3),
          size: 20,
        );
      }),
    );
  }

  Widget _buildColorCircle(Color color) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 4),
      ),
    );
  }
}
