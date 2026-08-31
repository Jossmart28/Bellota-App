import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_translations.dart';
import '../l10n/language_notifier.dart';
import '../theme/bellota_colors.dart';
import '../widgets/bellota_top_actions.dart';
import '../database/database_helper.dart';
import 'dashboard_screen.dart';
import 'location_picker_screen.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // 1. Datos Personales
  final _ageController = TextEditingController();
  String _locationLabel = '';
  LatLng? _locationLatLng;

  final List<String> _medications = AppTranslations.medicationKeys;
  final Set<String> _selectedMedications = {'none'};

  // 2. Ciclo Menstrual
  int _cycleDuration = 28;
  int _periodDuration = 5;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState?.validate() ?? false) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_age', _ageController.text.trim());
      await prefs.setString('user_location', _locationLabel);
      if (_locationLatLng != null) {
        await prefs.setDouble('user_latitude', _locationLatLng!.latitude);
        await prefs.setDouble('user_longitude', _locationLatLng!.longitude);
      }
      await prefs.setStringList('user_medications', _selectedMedications.toList());

      int? userId = prefs.getInt('userId');
      if (userId != null) {
        final db = await DatabaseHelper.instance.database;
        await db.update(
          'profiles',
          {'cycle_duration': _cycleDuration, 'period_duration': _periodDuration},
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      }

      await prefs.setBool('setup_completed', true);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => DashboardScreen(),
            transitionsBuilder: (_, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: Duration(milliseconds: 600),
          ),
        );
      }
    }
  }

  void _toggleMedication(String med) {
    setState(() {
      if (med == 'none') {
        _selectedMedications.clear();
        _selectedMedications.add('none');
      } else {
        _selectedMedications.remove('none');
        if (_selectedMedications.contains(med)) {
          _selectedMedications.remove(med);
          if (_selectedMedications.isEmpty) _selectedMedications.add('none');
        } else {
          _selectedMedications.add(med);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          body: Stack(
            children: [
              // ── Fondo degradado ──
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFD35D53), Color(0xFFEE8658), Color(0xFFFFF3E0)],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              // ── Círculos decorativos ──
              _buildDecorations(size),

              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        // ── Header ──
                        _buildHeader(lang),

                        // ── Contenido ──
                        Expanded(
                          child: SingleChildScrollView(
                            physics: BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildCard(
                                    icon: Icons.person_outline_rounded,
                                    title: AppTranslations.get('onboarding_and_auth', 'personal_data', lang),
                                    number: '1',
                                    child: _buildPersonalSection(lang),
                                  ),
                                  SizedBox(height: 16),
                                  _buildCard(
                                    icon: Icons.calendar_today_rounded,
                                    title: AppTranslations.get('onboarding_and_auth', 'your_cycle', lang),
                                    number: '2',
                                    child: _buildCycleSection(lang),
                                  ),
                                  SizedBox(height: 28),
                                  _buildCTAButton(lang),
                                  SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(String lang) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          Image.asset('assets/images/logo_white.png', height: 30,
              errorBuilder: (_, _, _) => Icon(Icons.circle, color: Colors.white54, size: 30)),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.get('onboarding_and_auth', 'tell_us', lang),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  AppTranslations.get('onboarding_and_auth', 'only_once', lang),
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          BellotaTopActions(
            showSettings: false,
            onTalkBackPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── TARJETA SECCIÓN ──────────────────────────────────────────────────────────
  Widget _buildCard({
    required IconData icon,
    required String title,
    required String number,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: BellotaColors.chilero.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la tarjeta
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD35D53), Color(0xFFEE8658)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Icon(icon, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Contenido
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: child,
          ),
        ],
      ),
    );
  }

  // ── SECCIÓN DATOS PERSONALES ───────────────────────────────────────────
  Widget _buildPersonalSection(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(AppTranslations.get('onboarding_and_auth', 'age', lang), Icons.cake_rounded),
        SizedBox(height: 8),
        TextFormField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(color: BellotaColors.textoDark, fontSize: 15),
          decoration: _inputDecoration(AppTranslations.get('onboarding_and_auth', 'age_hint', lang), Icons.numbers_rounded),
          validator: (val) {
            if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
              return AppTranslations.get('onboarding_and_auth', 'invalid_number', lang);
            }
            return null;
          },
        ),

        SizedBox(height: 20),
        _buildFieldLabel(AppTranslations.get('onboarding_and_auth', 'location', lang), Icons.place_rounded),
        SizedBox(height: 8),
        _buildLocationPicker(lang),

        SizedBox(height: 20),
        _buildFieldLabel(AppTranslations.get('onboarding_and_auth', 'medications', lang), Icons.medication_rounded),
        SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _medications.map((med) {
            final isSelected = _selectedMedications.contains(med);
            final medLabel = AppTranslations.getMedLabel(med, lang);
            return AnimatedContainer(
              duration: Duration(milliseconds: 200),
              child: FilterChip(
                label: Text(medLabel),
                selected: isSelected,
                onSelected: (_) => _toggleMedication(med),
                selectedColor: BellotaColors.chilero,
                backgroundColor: Color(0xFFF7EACC),
                checkmarkColor: Colors.white,
                labelStyle: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : BellotaColors.textoDark,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? BellotaColors.chilero : Colors.transparent,
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── SECCIÓN CICLO ─────────────────────────────────────────────────────────
  Widget _buildCycleSection(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSliderBlock(
          label: AppTranslations.get('onboarding_and_auth', 'cycle_duration', lang),
          value: _cycleDuration,
          unit: AppTranslations.get('profile_and_report', 'days', lang),
          min: 20,
          max: 45,
          color: BellotaColors.chilero,
          icon: Icons.loop_rounded,
          onChanged: (v) => setState(() {
            _cycleDuration = v.round();
            if (_periodDuration > _cycleDuration) _periodDuration = _cycleDuration;
          }),
        ),
        SizedBox(height: 20),
        _buildSliderBlock(
          label: AppTranslations.get('onboarding_and_auth', 'period_duration', lang),
          value: _periodDuration,
          unit: AppTranslations.get('profile_and_report', 'days', lang),
          min: 1,
          max: 10,
          color: BellotaColors.melon,
          icon: Icons.water_drop_rounded,
          onChanged: (v) => setState(() {
            _periodDuration = v.round();
            if (_periodDuration > _cycleDuration) _cycleDuration = _periodDuration;
          }),
        ),
        SizedBox(height: 16),
        // Info chip
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BellotaColors.basilica,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BellotaColors.nancite),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: BellotaColors.textoMedio),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${AppTranslations.get('onboarding_and_auth', 'cycle', lang)}: $_cycleDuration ${AppTranslations.get('profile_and_report', 'days', lang)}  •  ${AppTranslations.get('onboarding_and_auth', 'menstruation', lang)}: $_periodDuration ${AppTranslations.get('profile_and_report', 'days', lang)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: BellotaColors.textoMedio,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── SLIDER BLOCK ─────────────────────────────────────────────────────────────
  Widget _buildSliderBlock({
    required String label,
    required int value,
    required String unit,
    required double min,
    required double max,
    required Color color,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: BellotaColors.textoDark,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$value $unit',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.15),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.15),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 5,
          ),
          child: Slider(
            value: value.toDouble(),
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ── LOCATION PICKER ──────────────────────────────────────────────────────────
  Widget _buildLocationPicker(String lang) {
    final hasLocation = _locationLabel.isNotEmpty;
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (_) => LocationPickerScreen(initialPosition: _locationLatLng),
          ),
        );
        if (result != null && mounted) {
          setState(() {
            _locationLabel = result['label'] as String;
            _locationLatLng = result['position'] as LatLng;
          });
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasLocation
              ? BellotaColors.chilero.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasLocation ? BellotaColors.chilero.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hasLocation
                    ? BellotaColors.chilero.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasLocation ? Icons.place_rounded : Icons.map_outlined,
                color: hasLocation ? BellotaColors.chilero : Colors.grey,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasLocation ? AppTranslations.get('onboarding_and_auth', 'location_selected', lang) : AppTranslations.get('onboarding_and_auth', 'select_on_map', lang),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: hasLocation ? BellotaColors.chilero : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    hasLocation ? _locationLabel : AppTranslations.get('onboarding_and_auth', 'tap_to_open_map', lang),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: hasLocation ? FontWeight.w600 : FontWeight.normal,
                      color: hasLocation ? BellotaColors.textoDark : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: hasLocation ? BellotaColors.chilero : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }


  // ── BOTÓN CONTINUAR ──
  Widget _buildCTAButton(String lang) {
    return GestureDetector(
      onTap: _saveAndContinue,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD35D53), Color(0xFFEE8658)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: BellotaColors.chilero.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppTranslations.get('onboarding_and_auth', 'finish_registration', lang),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────────
  Widget _buildFieldLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: BellotaColors.chilero),
        SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: BellotaColors.textoDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.withValues(alpha: 0.5), fontSize: 14),
      prefixIcon: Icon(icon, color: BellotaColors.chilero.withValues(alpha: 0.6), size: 20),
      filled: true,
      fillColor: Colors.grey.withValues(alpha: 0.06),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: BellotaColors.chilero, width: 1.5),
      ),
    );
  }

  Widget _buildDecorations(Size size) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -size.width * 0.25,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.75,
              height: size.width * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.1,
            left: -size.width * 0.15,
            child: Container(
              width: size.width * 0.45,
              height: size.width * 0.45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.06,
            right: size.width * 0.1,
            child: Transform.rotate(
              angle: math.pi / 5,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
