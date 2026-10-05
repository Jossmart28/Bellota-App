import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import '../core/constants/nicaragua_data.dart';
import '../core/constants/app_keys.dart';
import '../database/database_helper.dart';
import '../l10n/language_notifier.dart';
import '../theme/bellota_colors.dart';
import '../widgets/bellota_top_actions.dart';
import 'dashboard_screen.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 7;

  // Step 1: Ubicación
  String? _selectedDepartment;
  String? _selectedMunicipality;
  String _locationLabel = '';
  LatLng? _locationLatLng;
  final MapController _mapController = MapController();
  bool _isLoadingMap = false;

  // Step 2: Duración del ciclo
  int _cycleDuration = 28;

  // Step 3: Duración del periodo
  int _periodDuration = 5;

  // Step 4: Medicamentos
  final List<String> _medications = AppTranslations.medicationKeys;
  final Set<String> _selectedMedications = {'none'};

  // Step 5: Condiciones médicas
  final List<String> _selectedConditions = ['none'];
  final Map<String, String> _conditionsMap = {
    'none': 'Ninguna',
    'pcos': 'SOP (Ovarios Poliquísticos)',
    'endometriosis': 'Endometriosis',
    'hypothyroidism': 'Hipotiroidismo',
    'other': 'Otra'
  };
  final Map<String, IconData> _conditionsIcons = {
    'none': Icons.check_circle_outline,
    'pcos': Icons.sync_problem_outlined,
    'endometriosis': Icons.bloodtype_outlined,
    'hypothyroidism': Icons.medication_liquid_outlined,
    'other': Icons.add_circle_outline,
  };
  final Map<String, Color> _conditionsColors = {
    'none': Colors.green,
    'pcos': Colors.orange,
    'endometriosis': Colors.red,
    'hypothyroidism': Colors.blue,
    'other': Colors.grey,
  };

  // Step 6: Método anticonceptivo
  String? _selectedContraceptive = 'none';
  final Map<String, String> _contraceptivesMap = {
    'none': 'Ninguno',
    'combined_pill': 'Píldora combinada',
    'mini_pill': 'Minipíldora',
    'copper_iud': 'DIU de cobre',
    'hormonal_iud': 'DIU hormonal',
    'implant': 'Implante',
    'ring': 'Anillo',
    'patch': 'Parche',
    'injection': 'Inyección'
  };
  final Map<String, IconData> _contraceptivesIcons = {
    'none': Icons.block_outlined,
    'combined_pill': Icons.medication_outlined,
    'mini_pill': Icons.medication_outlined,
    'copper_iud': Icons.circle_outlined,
    'hormonal_iud': Icons.circle_outlined,
    'implant': Icons.linear_scale_outlined,
    'ring': Icons.radio_button_unchecked,
    'patch': Icons.crop_square_outlined,
    'injection': Icons.vaccines_outlined,
  };

  // Step 7: Objetivo
  String? _selectedGoal = 'track_period';
  final Map<String, Map<String, dynamic>> _goalsMap = {
    'track_period': {'title': 'Seguir mi ciclo', 'desc': 'Conocer mis días fértiles y predicciones', 'icon': Icons.calendar_month_outlined},
    'understand_body': {'title': 'Entender mi cuerpo', 'desc': 'Aprender sobre mis patrones de salud', 'icon': Icons.search_rounded},
    'manage_symptoms': {'title': 'Manejar síntomas', 'desc': 'Registrar dolor, humor y flujo', 'icon': Icons.healing_outlined},
  };

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

  Future<void> _updateMapLocation() async {
    if (_selectedDepartment == null || _selectedMunicipality == null) return;
    
    setState(() => _isLoadingMap = true);
    final address = '$_selectedMunicipality, $_selectedDepartment, Nicaragua';
    
    try {
      final List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        setState(() {
          _locationLatLng = LatLng(loc.latitude, loc.longitude);
          _locationLabel = address;
        });
      }
    } catch (_) {
      // Fallback a coordenadas genéricas de Managua si falla
      setState(() {
        _locationLatLng = const LatLng(12.115, -86.236);
        _locationLabel = address;
      });
    } finally {
      if (mounted) setState(() => _isLoadingMap = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _saveAndContinue();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _saveAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppKeys.userLocation, _locationLabel);
    if (_locationLatLng != null) {
      await prefs.setDouble('user_latitude', _locationLatLng!.latitude);
      await prefs.setDouble('user_longitude', _locationLatLng!.longitude);
    }
    await prefs.setStringList('user_medications', _selectedMedications.toList());

    int? userId = prefs.getInt(AppKeys.userId);
    if (userId != null) {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'profiles',
        {
          'cycle_duration': _cycleDuration,
          'period_duration': _periodDuration,
          'medical_conditions': jsonEncode(_selectedConditions),
          'contraceptive': _selectedContraceptive == 'none' ? null : _selectedContraceptive,
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }

    if (_selectedGoal != null) {
      await prefs.setString('app_goal', _selectedGoal!);
    }

    await prefs.setBool('setup_completed', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DashboardScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD35D53), Color(0xFFEE8658), Color(0xFFFFF3E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decoraciones
            _buildDecorations(),

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

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildProgressBar(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      width: double.infinity,
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
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              onPageChanged: (idx) {
                                setState(() => _currentPage = idx);
                              },
                              children: [
                                _buildStep1Location(),
                                _buildStep2Cycle(),
                                _buildStep3Period(),
                                _buildStep4Medications(),
                                _buildStep5Conditions(),
                                _buildStep6Contraceptive(),
                                _buildStep7Goal(),
                              ],
                            ),
                          ),
                          _buildBottomNav(),
                        ],
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

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalPages, (index) {
              final isActive = index == _currentPage;
              final isPast = index < _currentPage;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive || isPast 
                        ? Theme.of(context).bellotaColors.blanco 
                        : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            "Paso ${_currentPage + 1} de $_totalPages",
            style: GoogleFonts.poppins(
              color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: _prevPage,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.8),
              ),
              child: Text(
                "← Anterior",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            )
          else
            const SizedBox(width: 80),
            
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).bellotaColors.melon, Theme.of(context).bellotaColors.chilero],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _currentPage == _totalPages - 1 ? "Listo ✓" : "Siguiente →",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).bellotaColors.blanco,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepWrapper(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: child,
    );
  }

  // --- STEPS ---

  Widget _buildStep1Location() {
    final depts = NicaraguaData.departments.keys.toList()..sort();
    List<String> munis = [];
    if (_selectedDepartment != null) {
      munis = List<String>.from(NicaraguaData.departments[_selectedDepartment!] ?? []);
      munis.sort();
    }

    return _stepWrapper(
      Column(
        children: [
          Icon(Icons.location_on_rounded, size: 48, color: Theme.of(context).bellotaColors.blanco),
          const SizedBox(height: 12),
          Text(
            "¿Dónde vives?",
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).bellotaColors.blanco),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Dropdown Departamento
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDepartment,
                hint: Text("Departamento", style: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.7))),
                isExpanded: true,
                dropdownColor: Theme.of(context).bellotaColors.chilero,
                icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).bellotaColors.blanco),
                style: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.blanco, fontSize: 16),
                items: depts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedDepartment = val;
                    _selectedMunicipality = null;
                    _locationLatLng = null;
                  });
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // Dropdown Municipio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMunicipality,
                hint: Text("Municipio", style: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.7))),
                isExpanded: true,
                dropdownColor: Theme.of(context).bellotaColors.chilero,
                icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).bellotaColors.blanco),
                style: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.blanco, fontSize: 16),
                items: munis.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: _selectedDepartment == null ? null : (val) {
                  setState(() {
                    _selectedMunicipality = val;
                  });
                  _updateMapLocation();
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Mapa Integrado (solo se muestra cuando _locationLatLng está listo)
          Expanded(
            child: _locationLatLng == null
                ? Center(
                    child: _isLoadingMap
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Selecciona tu ubicación para ver el mapa",
                            style: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.7)),
                            textAlign: TextAlign.center,
                          ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FlutterMap(
                      key: ValueKey(_locationLatLng), // fuerza rebuild para centrar
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _locationLatLng!,
                        initialZoom: 13,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.bellota.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _locationLatLng!,
                              width: 48,
                              height: 48,
                              child: Icon(Icons.location_pin, color: Theme.of(context).bellotaColors.chilero, size: 48),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Cycle() {
    return _stepWrapper(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.loop_rounded, size: 64, color: Theme.of(context).bellotaColors.blanco),
          const SizedBox(height: 24),
          Text(
            "¿Cuánto dura tu ciclo?",
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).bellotaColors.blanco),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Text(
            "$_cycleDuration",
            style: GoogleFonts.poppins(fontSize: 56, fontWeight: FontWeight.bold, color: Theme.of(context).bellotaColors.blanco, height: 1.0),
          ),
          Text(
            "días",
            style: GoogleFonts.poppins(fontSize: 20, color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 40),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).bellotaColors.blanco,
              inactiveTrackColor: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.3),
              thumbColor: Theme.of(context).bellotaColors.blanco,
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              value: _cycleDuration.toDouble(),
              min: 20,
              max: 45,
              divisions: 25,
              onChanged: (val) => setState(() => _cycleDuration = val.toInt()),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Promedio normal: 28 días",
            style: GoogleFonts.poppins(fontSize: 13, color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Period() {
    return _stepWrapper(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.water_drop_rounded, size: 64, color: Theme.of(context).bellotaColors.melon),
          const SizedBox(height: 24),
          Text(
            "¿Cuánto dura tu menstruación?",
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).bellotaColors.blanco),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Text(
            "$_periodDuration",
            style: GoogleFonts.poppins(fontSize: 56, fontWeight: FontWeight.bold, color: Theme.of(context).bellotaColors.melon, height: 1.0),
          ),
          Text(
            "días",
            style: GoogleFonts.poppins(fontSize: 20, color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 40),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).bellotaColors.melon,
              inactiveTrackColor: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.3),
              thumbColor: Theme.of(context).bellotaColors.melon,
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              value: _periodDuration.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (val) => setState(() => _periodDuration = val.toInt()),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Promedio normal: 5 días",
            style: GoogleFonts.poppins(fontSize: 13, color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Medications() {
    return _stepWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medication_outlined, size: 48, color: Theme.of(context).bellotaColors.blanco),
          const SizedBox(height: 16),
          Text(
            "¿Tomas algún medicamento regularmente?",
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).bellotaColors.blanco),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _medications.map((med) {
                  final isSelected = _selectedMedications.contains(med);
                  final label = AppTranslations.get('registration_form', med, languageNotifier.currentLang, context: context);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (med == 'none') {
                          _selectedMedications.clear();
                          _selectedMedications.add('none');
                        } else {
                          _selectedMedications.remove('none');
                          if (isSelected) {
                            _selectedMedications.remove(med);
                            if (_selectedMedications.isEmpty) _selectedMedications.add('none');
                          } else {
                            _selectedMedications.add(med);
                          }
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2) : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).bellotaColors.blanco : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Icon(Icons.check, color: Theme.of(context).bellotaColors.blanco, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).bellotaColors.blanco,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5Conditions() {
    return _stepWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_outlined, size: 48, color: Theme.of(context).bellotaColors.blanco),
          const SizedBox(height: 16),
          Text(
            "¿Tienes alguna condición de salud diagnosticada?",
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).bellotaColors.blanco),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: _conditionsMap.entries.map((e) {
                  final key = e.key;
                  final label = e.value;
                  final isSelected = _selectedConditions.contains(key);
                  final icon = _conditionsIcons[key]!;
                  final color = _conditionsColors[key]!;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (key == 'none') {
                            _selectedConditions.clear();
                            _selectedConditions.add('none');
                          } else {
                            _selectedConditions.remove('none');
                            if (isSelected) {
                              _selectedConditions.remove(key);
                              if (_selectedConditions.isEmpty) _selectedConditions.add('none');
                            } else {
                              _selectedConditions.add(key);
                            }
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2) : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Theme.of(context).bellotaColors.blanco : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                label,
                                style: GoogleFonts.poppins(
                                  color: Theme.of(context).bellotaColors.blanco,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: Theme.of(context).bellotaColors.blanco),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep6Contraceptive() {
    return _stepWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 48, color: Theme.of(context).bellotaColors.blanco),
          const SizedBox(height: 16),
          Text(
            "¿Usas algún método anticonceptivo?",
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).bellotaColors.blanco),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: _contraceptivesMap.entries.map((e) {
                  final key = e.key;
                  final label = e.value;
                  final isSelected = _selectedContraceptive == key;
                  final icon = _contraceptivesIcons[key]!;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedContraceptive = key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2) : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Theme.of(context).bellotaColors.blanco : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: Theme.of(context).bellotaColors.blanco, size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                label,
                                style: GoogleFonts.poppins(
                                  color: Theme.of(context).bellotaColors.blanco,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Radio<String>(
                              value: key,
                              groupValue: _selectedContraceptive,
                              onChanged: (v) => setState(() => _selectedContraceptive = v),
                              activeColor: Theme.of(context).bellotaColors.blanco,
                              fillColor: WidgetStateProperty.resolveWith((states) => Theme.of(context).bellotaColors.blanco),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep7Goal() {
    return _stepWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.flag_outlined, size: 48, color: Theme.of(context).bellotaColors.blanco),
          const SizedBox(height: 16),
          Text(
            "¿Cuál es tu objetivo principal?",
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).bellotaColors.blanco),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: _goalsMap.entries.map((e) {
                  final key = e.key;
                  final map = e.value;
                  final isSelected = _selectedGoal == key;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGoal = key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2) : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Theme.of(context).bellotaColors.blanco : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(map['icon'], color: Theme.of(context).bellotaColors.blanco, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    map['title'],
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).bellotaColors.blanco,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    map['desc'],
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorations() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: Container(width: 150, height: 150, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle)),
          ),
          Positioned(
            top: 200,
            right: -80,
            child: Container(width: 200, height: 200, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), shape: BoxShape.circle)),
          ),
          Positioned(
            bottom: -60,
            left: -30,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(width: 150, height: 150, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(40))),
            ),
          ),
        ],
      ),
    );
  }
}
