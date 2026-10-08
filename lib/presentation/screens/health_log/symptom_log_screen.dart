import 'package:bellotadevelopment/core/errors/app_logger.dart';
import 'package:bellotadevelopment/core/constants/app_keys.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';
import 'package:bellotadevelopment/database/database_helper.dart';
import 'package:bellotadevelopment/core/services/notification_service.dart';
import 'package:bellotadevelopment/presentation/screens/health_log/symptoms_selection_screen.dart';
import 'package:bellotadevelopment/presentation/screens/health_log/flujo_vaginal_selection_screen.dart';
import 'package:bellotadevelopment/presentation/screens/health_log/sexo_selection_screen.dart';
import 'package:bellotadevelopment/presentation/screens/health_log/patron_sangrado_screen.dart';
import 'package:bellotadevelopment/presentation/screens/health_log/dolor_sintomatologia_screen.dart';
import 'package:bellotadevelopment/core/services/clinical_analysis_service.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';
import 'package:bellotadevelopment/core/di/injection_container.dart';
import 'package:bellotadevelopment/domain/repositories/auth_repository.dart';
import 'package:bellotadevelopment/domain/repositories/user_repository.dart';
import 'package:bellotadevelopment/domain/repositories/profile_repository.dart';
import 'package:bellotadevelopment/domain/repositories/audit_repository.dart';
import 'package:bellotadevelopment/domain/repositories/daily_log_repository.dart';
import 'package:bellotadevelopment/data/datasources/database_provider.dart';


class SymptomLogScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const SymptomLogScreen({super.key, this.selectedDate});

  @override
  State<SymptomLogScreen> createState() => _SymptomLogScreenState();
}

class _SymptomLogScreenState extends State<SymptomLogScreen> {
  bool iniciaPeriodo = false;
  List<String> _selectedSymptoms = [];
  List<String> _selectedFlujos = [];
  List<String> _selectedSexo = [];
  Map<String, dynamic> _patronSangrado = {};
  Map<String, dynamic> _dolorSintomatologia = {};
  String _notes = '';
  double? _basalTemp;
  String? _lhTestResult;
  String? _cervicalPosition;
  String? _mood;
  late TextEditingController _notesController;
  late DateTime _date;
  int? _userId;

  final List<String> _monthNames = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];

  @override
  void initState() {
    super.initState();
    _date = widget.selectedDate ?? DateTime.now();
    _notesController = TextEditingController(text: _notes);
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String get _dateKey => '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  String get _formattedDate => '${_date.day} de ${_monthNames[_date.month - 1]} ${_date.year}';

  double get _completionPercent {
    int filled = 0;
    if (_selectedSexo.isNotEmpty) filled++;
    if (_selectedSymptoms.isNotEmpty) filled++;
    if (_selectedFlujos.isNotEmpty) filled++;
    if (_patronSangrado.isNotEmpty) filled++;
    if (_dolorSintomatologia.isNotEmpty) filled++;
    if (_notes.isNotEmpty) filled++;
    return filled / 6.0;
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt(AppKeys.userId);

    if (_userId == null) {
      String userEmail = prefs.getString(AppKeys.userEmail) ?? '';
      if (userEmail.isNotEmpty) {
        _userId = await sl<AuthRepository>().getUserIdByEmail(userEmail);
        if (_userId != null) {
          await prefs.setInt(AppKeys.userId, _userId!);
        }
      }
    }

    if (_userId != null) {
      final log = await sl<DailyLogRepository>().getDailyLog(_userId!, _dateKey);
      if (log != null) {
        setState(() {
          iniciaPeriodo = (log.periodStart as int?) == 1;
          _selectedSymptoms = List<String>.from(log.symptoms);
          _selectedSexo = List<String>.from(log.sexo);
          _selectedFlujos = List<String>.from(log.flujo);
          _notes = log.notes as String? ?? '';
          _notesController.text = _notes;
          
          if (log.basalTemp != null) _basalTemp = (log.basalTemp as num).toDouble();
          _lhTestResult = log.lhTestResult as String?;
          _cervicalPosition = log.cervicalPosition as String?;
          _mood = log.mood as String?;

          // Load bleeding pattern from SQLite (was SharedPreferences)
          _patronSangrado = {};
          if (log.bleedingIntensity != null) _patronSangrado['intensidadFlujoKey'] = log.bleedingIntensity;
          if (log.clots != null) _patronSangrado['coagulosKey'] = log.clots;
          if ((log.spotting as int?) == 1) _patronSangrado['manchadoKey'] = 'yes';
          if (log.spottingDays != null) _patronSangrado['manchadoDias'] = log.spottingDays;
          if (log.sexualSymptoms != null) {
            _patronSangrado['sintomasSexualesKeys'] = (log.sexualSymptoms as String).split(', ');
          }
          
          // Load pain data from SQLite (was SharedPreferences)
          _dolorSintomatologia = {};
          if (log.painLevel != null) _dolorSintomatologia['nivelDolor'] = log.painLevel;
          if (log.painCharacter != null) _dolorSintomatologia['caracterDolor'] = log.painCharacter;
          if (log.painDays != null) _dolorSintomatologia['diasDolor'] = log.painDays;
          if (log.treatment != null) _dolorSintomatologia['tratamiento'] = log.treatment;
          final physStr = log.physicalSymptoms as String?;
          if (physStr != null && physStr != '[]') {
            _dolorSintomatologia['sintomasFisicos'] = List<String>.from(jsonDecode(physStr));
          }
          final emoStr = log.emotionalSymptoms as String?;
          if (emoStr != null && emoStr != '[]') {
            _dolorSintomatologia['sintomasEmocionales'] = List<String>.from(jsonDecode(emoStr));
          }
          if (log.breastExam != null) _dolorSintomatologia['autoexamenMama'] = log.breastExam;
        });
      }
    }
  }


  Future<void> _saveAndAccept() async {
    if (_userId != null && iniciaPeriodo) {
      final starts = await sl<DailyLogRepository>().getAllPeriodStartDates(_userId!);
      bool hasRecentPeriod = false;
      for (var d in starts) {
        if (d.year == _date.year && d.month == _date.month && d.day == _date.day) continue;
        if ((d.difference(_date).inDays).abs() <= 15) {
          hasRecentPeriod = true;
          break;
        }
      }

      if (hasRecentPeriod) {
        bool confirm = false;
        if (mounted) {
          confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.symptomsAndActionsRecentPeriodTitle == 'recent_period_title' ? 'Ã‚Â¿Periodo reciente?' : AppLocalizations.of(context)!.symptomsAndActionsRecentPeriodTitle),
              content: Text(AppLocalizations.of(context)!.symptomsAndActionsRecentPeriodError),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)!.registrationFormNo, style: TextStyle(color: Theme.of(context).bellotaColors.textoMedio)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context)!.registrationFormYes, style: TextStyle(color: Theme.of(context).bellotaColors.chilero, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ) ?? false;
        }
        if (!confirm) {
          return;
        }
      }
    }

    if (_userId != null) {
      try {
        await sl<DailyLogRepository>().saveDailyLogV2(
          userId: _userId!,
          date: _dateKey,
          periodStart: iniciaPeriodo,
          symptoms: _selectedSymptoms,
          sexo: _selectedSexo,
          flujo: _selectedFlujos,
          notes: _notes.isNotEmpty ? _notes : null,
          basalTemp: _basalTemp,
          lhTestResult: _lhTestResult,
          cervicalPosition: _cervicalPosition,
          mood: _mood,
          // Bleeding pattern data
          bleedingIntensity: _patronSangrado['intensidadFlujoKey'] as String?,
          clots: _patronSangrado['coagulosKey'] as String?,
          spotting: (_patronSangrado['manchadoKey'] == 'yes'),
          spottingDays: _patronSangrado['manchadoDias'] as String?,
          sexualSymptoms: _patronSangrado['sintomasSexualesKeys'] != null 
              ? (_patronSangrado['sintomasSexualesKeys'] as List<String>).join(', ') 
              : null,
          // Pain & symptomatology data
          painLevel: _dolorSintomatologia['nivelDolor']?.toDouble(),
          painCharacter: _dolorSintomatologia['caracterDolorKey'] as String?,
          painDays: _dolorSintomatologia['diasDolor'] as String?,
          treatment: _dolorSintomatologia['tratamientoKey'] as String?,
          physicalSymptoms: _dolorSintomatologia['sintomasFisicosKeys'] != null 
              ? List<String>.from(_dolorSintomatologia['sintomasFisicosKeys'])
              : [],
          emotionalSymptoms: _dolorSintomatologia['sintomasEmocionalKeys'] != null 
              ? List<String>.from(_dolorSintomatologia['sintomasEmocionalKeys'])
              : [],
          breastExam: _dolorSintomatologia['autoexamenMamaKey'] as String?,
        );

        // Reprogramar notificaciones porque puede haber cambiado el inicio del periodo
        try {
          await NotificationService.instance.scheduleAllNotifications(_userId!);
        } catch (e) {
          AppLogger.d('Error scheduling notifications: $e');
        }

        // Evaluar estado clÃ­nico para disparar notificaciÃ³n push
        try {
          final alerts = await ClinicalAnalysisService.instance.analyzeHealthState(_userId!);
          final highAlert = alerts.where((a) => a.severity == 'high').firstOrNull;
          if (highAlert != null) {
            await NotificationService.instance.showUrgentAlert(
              title: 'ðŸš¨ Bellota',
              body: highAlert.triggerSymptoms.join(', '),
            );
          }
        } catch (e) {
          AppLogger.d('Error evaluating clinical state: $e');
        }
      } catch (e) {
        AppLogger.d('Error saving daily log: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Registro guardado para $_formattedDate', style: TextStyle(color: Colors.white))),
            ],
          ),
          backgroundColor: Theme.of(context).bellotaColors.chiltoma,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _openSymptomsSelection() async {
    final selected = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => SymptomsSelectionScreen(initialSelectedSymptoms: _selectedSymptoms),
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedSymptoms = selected;
      });
    }
  }

  Future<void> _openFlujoSelection() async {
    final selected = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => FlujoVaginalSelectionScreen(initialSelectedFlujos: _selectedFlujos),
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedFlujos = selected;
      });
    }
  }

  Future<void> _openSexoSelection() async {
    final selected = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => SexoSelectionScreen(initialSelectedSexo: _selectedSexo),
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedSexo = selected;
      });
    }
  }

  Future<void> _openPatronSangradoSelection() async {
    final selected = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => PatronSangradoScreen(initialData: _patronSangrado),
      ),
    );
    if (selected != null) {
      setState(() {
        _patronSangrado = selected;
      });
    }
  }

  Future<void> _openDolorSintomatologiaSelection() async {
    final Map<String, dynamic> initialMap = Map.from(_dolorSintomatologia);
    initialMap['basalTemp'] = _basalTemp;
    initialMap['lhTestResult'] = _lhTestResult;
    initialMap['cervicalPosition'] = _cervicalPosition;
    
    final selected = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => DolorSintomatologiaScreen(initialData: initialMap),
      ),
    );
    if (selected != null) {
      setState(() {
        _basalTemp = selected['basalTemp'] as double?;
        _lhTestResult = selected['lhTestResult'] as String?;
        _cervicalPosition = selected['cervicalPosition'] as String?;
        _dolorSintomatologia = selected;
      });
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
          body: ListView(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildRedHeader(context, colors),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    _buildInicioPeriodoCard(context, colors),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildGridCard(
                          context, colors, 
                          title: 'Sexo', 
                          hasData: _selectedSexo.isNotEmpty,
                          icon: Icons.favorite_rounded, 
                          iconColor: colors.melon, 
                          onTap: _openSexoSelection
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _buildGridCard(
                          context, colors, 
                          title: 'Síntomas', 
                          hasData: _selectedSymptoms.isNotEmpty,
                          icon: Icons.medical_services_rounded, 
                          iconColor: colors.chiltoma, 
                          onTap: _openSymptomsSelection
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildGridCard(
                          context, colors, 
                          title: 'Flujo vaginal', 
                          hasData: _selectedFlujos.isNotEmpty,
                          icon: Icons.water_drop_rounded, 
                          iconColor: const Color(0xFF7E9EC9), 
                          onTap: _openFlujoSelection
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _buildGridCard(
                          context, colors, 
                          title: 'Patrón de\nsangrado', 
                          hasData: _patronSangrado.isNotEmpty,
                          icon: Icons.water_drop_rounded, 
                          iconColor: colors.chilero, 
                          onTap: _openPatronSangradoSelection
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDolorCard(context, colors),
                    const SizedBox(height: 16),
                    _buildNotasCard(context, colors),
                    const SizedBox(height: 32),
                    _buildSaveButton(context, lang),
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

  // ─────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────

  Widget _buildRedHeader(BuildContext context, dynamic colors) {
    int filled = 0;
    if (_selectedSexo.isNotEmpty) filled++;
    if (_selectedSymptoms.isNotEmpty) filled++;
    if (_selectedFlujos.isNotEmpty) filled++;
    if (_patronSangrado.isNotEmpty) filled++;
    if (_dolorSintomatologia.isNotEmpty) filled++;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFDA6A62), // Reddish base
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -60,
            top: -40,
            child: Opacity(opacity: 0.15, child: Image.asset('assets/images/bellota_outline_white.png', width: 220, height: 220)),
          ),
          Positioned(
            right: 80,
            top: 40,
            child: Opacity(opacity: 0.1, child: Image.asset('assets/images/bellota_outline_white.png', width: 140, height: 140)),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registro de hoy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      Text(
                        _formattedDate,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Image.asset(
                          'assets/images/bellota_outline_white.png',
                          width: 16, height: 16,
                          color: index < filled ? Colors.white : Colors.white.withOpacity(0.3),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '$filled de 5 secciones',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // CARDS
  // ─────────────────────────────────────────────────────────────────

  Widget _buildInicioPeriodoCard(BuildContext context, dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.chilero.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: colors.chilero.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.water_drop_rounded, color: colors.chilero, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inicio del período',
                      style: TextStyle(
                        color: colors.textoDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      iniciaPeriodo ? '1 fecha marcada' : 'No marcado',
                      style: TextStyle(
                        color: colors.textoMedio,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
                            Container(
                decoration: BoxDecoration(
                  color: colors.basilica ?? const Color(0xFFFDF6EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => iniciaPeriodo = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: iniciaPeriodo ? colors.chilero : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Sí',
                          style: TextStyle(
                            color: iniciaPeriodo ? Colors.white : colors.textoMedio,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => iniciaPeriodo = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: !iniciaPeriodo ? colors.chilero : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'No',
                          style: TextStyle(
                            color: !iniciaPeriodo ? Colors.white : colors.textoMedio,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (iniciaPeriodo) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECD4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.water_drop_rounded, color: colors.chilero, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    '${_date.day} ${_monthNames[_date.month - 1].substring(0, 3)}',
                    style: TextStyle(
                      color: colors.chilero,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context, dynamic colors, {
    required String title,
    required bool hasData,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Image.asset(
                'assets/images/bellota_outline_white.png',
                width: 80,
                height: 80,
                color: colors.basilica?.withOpacity(0.6) ?? const Color(0xFFFAF1E3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 22),
                      ),
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hasData ? iconColor : colors.textoMedio.withOpacity(0.3),
                            width: 1.5,
                          ),
                          color: hasData ? iconColor.withOpacity(0.1) : Colors.transparent,
                        ),
                        child: Icon(
                          hasData ? Icons.check_rounded : Icons.add_rounded,
                          color: hasData ? iconColor : colors.textoMedio.withOpacity(0.5),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textoDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Outfit',
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasData ? 'Registrado' : 'Toca para agregar',
                    style: TextStyle(
                      color: colors.textoMedio,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildDolorCard(BuildContext context, dynamic colors) {
    final hasData = _dolorSintomatologia.isNotEmpty;
    return GestureDetector(
      onTap: _openDolorSintomatologiaSelection,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.chiltoma.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -20,
              child: Image.asset(
                'assets/images/bellota_outline_white.png',
                width: 100,
                height: 100,
                color: colors.basilica?.withOpacity(0.6) ?? const Color(0xFFFAF1E3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: colors.chiltoma.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.healing_rounded, color: colors.chiltoma, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dolor y sintomatología',
                          style: TextStyle(
                            color: colors.textoDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasData ? 'Registrado' : 'Toca para agregar',
                          style: TextStyle(
                            color: colors.textoMedio,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasData ? colors.chiltoma : colors.textoMedio.withOpacity(0.3),
                        width: 1.5,
                      ),
                      color: hasData ? colors.chiltoma.withOpacity(0.1) : Colors.transparent,
                    ),
                    child: Icon(
                      hasData ? Icons.check_rounded : Icons.add_rounded,
                      color: hasData ? colors.chiltoma : colors.textoMedio.withOpacity(0.5),
                      size: 16,
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

  Widget _buildNotasCard(BuildContext context, dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.textoMedio.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDDFC6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_note_rounded, color: Color(0xFF8B6C4F), size: 24),
              ),
              const SizedBox(width: 14),
              Text(
                'Notas personales',
                style: TextStyle(
                  color: colors.textoDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: colors.basilica ?? const Color(0xFFFDF6EC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.textoMedio.withOpacity(0.1)),
            ),
            child: TextField(
              maxLines: 3,
              minLines: 2,
              onChanged: (v) => setState(() => _notes = v),
              controller: _notesController,
              style: TextStyle(fontSize: 14, color: colors.textoDark),
              decoration: InputDecoration(
                hintText: 'Escribe observaciones del día...',
                hintStyle: TextStyle(color: colors.textoMedio.withOpacity(0.6), fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, String lang) {
    final colors = Theme.of(context).bellotaColors;
    return GestureDetector(
      onTap: _saveAndAccept,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: colors.chilero,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: colors.chilero.withOpacity(0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)?.registrationFormSaveLog ?? 'Guardar registro',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.3,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
