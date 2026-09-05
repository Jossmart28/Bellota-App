import '../core/constants/app_keys.dart';
import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import '../database/database_helper.dart';
import '../core/services/notification_service.dart';
import 'symptoms_selection_screen.dart';
import 'flujo_vaginal_selection_screen.dart';
import 'sexo_selection_screen.dart';
import 'patron_sangrado_screen.dart';
import 'dolor_sintomatologia_screen.dart';

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
        _userId = await DatabaseHelper.instance.getUserIdByEmail(userEmail);
        if (_userId != null) {
          await prefs.setInt(AppKeys.userId, _userId!);
        }
      }
    }

    if (_userId != null) {
      final log = await DatabaseHelper.instance.getDailyLog(_userId!, _dateKey);
      if (log != null) {
        setState(() {
          iniciaPeriodo = (log['period_start'] as int?) == 1;
          _selectedSymptoms = List<String>.from(jsonDecode(log['symptoms'] as String? ?? '[]'));
          _selectedSexo = List<String>.from(jsonDecode(log['sexo'] as String? ?? '[]'));
          _selectedFlujos = List<String>.from(jsonDecode(log['flujo'] as String? ?? '[]'));
          _notes = log['notes'] as String? ?? '';
          _notesController.text = _notes;
          
          // Load bleeding pattern from SQLite (was SharedPreferences)
          _patronSangrado = {};
          if (log['bleeding_intensity'] != null) _patronSangrado['intensidadFlujo'] = log['bleeding_intensity'];
          if (log['clots'] != null) _patronSangrado['coagulos'] = log['clots'];
          if ((log['spotting'] as int?) == 1) _patronSangrado['manchado'] = 'SÃ­';
          if (log['spotting_days'] != null) _patronSangrado['manchadoDias'] = log['spotting_days'];
          if (log['sexual_symptoms'] != null) _patronSangrado['sintomasSexuales'] = log['sexual_symptoms'];
          
          // Load pain data from SQLite (was SharedPreferences)
          _dolorSintomatologia = {};
          if (log['pain_level'] != null) _dolorSintomatologia['nivelDolor'] = log['pain_level'];
          if (log['pain_character'] != null) _dolorSintomatologia['caracterDolor'] = log['pain_character'];
          if (log['pain_days'] != null) _dolorSintomatologia['diasDolor'] = log['pain_days'];
          if (log['treatment'] != null) _dolorSintomatologia['tratamiento'] = log['treatment'];
          final physStr = log['physical_symptoms'] as String?;
          if (physStr != null && physStr != '[]') {
            _dolorSintomatologia['sintomasFisicos'] = List<String>.from(jsonDecode(physStr));
          }
          final emoStr = log['emotional_symptoms'] as String?;
          if (emoStr != null && emoStr != '[]') {
            _dolorSintomatologia['sintomasEmocionales'] = List<String>.from(jsonDecode(emoStr));
          }
          if (log['breast_exam'] != null) _dolorSintomatologia['autoexamenMama'] = log['breast_exam'];
        });
      }
    }
  }

  Future<void> _saveAndAccept() async {
    final lang = languageNotifier.currentLang;
    if (_userId != null && iniciaPeriodo) {
      final starts = await DatabaseHelper.instance.getAllPeriodStartDates(_userId!);
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
              title: Text(AppTranslations.get('symptoms_and_actions', 'recent_period_title', lang) == 'recent_period_title' ? 'Â¿Periodo reciente?' : AppTranslations.get('symptoms_and_actions', 'recent_period_title', lang)),
              content: Text(AppTranslations.get('symptoms_and_actions', 'recent_period_error', lang)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppTranslations.get('registration_form', 'no', lang), style: TextStyle(color: Theme.of(context).bellotaColors.textoMedio)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppTranslations.get('registration_form', 'yes', lang), style: TextStyle(color: Theme.of(context).bellotaColors.chilero, fontWeight: FontWeight.bold)),
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
        await DatabaseHelper.instance.saveDailyLogV2(
          userId: _userId!,
          date: _dateKey,
          periodStart: iniciaPeriodo,
          symptoms: _selectedSymptoms,
          sexo: _selectedSexo,
          flujo: _selectedFlujos,
          notes: _notes.isNotEmpty ? _notes : null,
          // Bleeding pattern data
          bleedingIntensity: _patronSangrado['intensidadFlujo'] as String?,
          clots: _patronSangrado['coagulos'] as String?,
          spotting: (_patronSangrado['manchado'] == 'SÃ­' || _patronSangrado['manchado'] == 'Yes'),
          spottingDays: _patronSangrado['manchadoDias'] as String?,
          sexualSymptoms: _patronSangrado['sintomasSexuales'] as String?,
          // Pain & symptomatology data
          painLevel: _dolorSintomatologia['nivelDolor']?.toDouble(),
          painCharacter: _dolorSintomatologia['caracterDolor'] as String?,
          painDays: _dolorSintomatologia['diasDolor'] as String?,
          treatment: _dolorSintomatologia['tratamiento'] as String?,
          physicalSymptoms: _dolorSintomatologia['sintomasFisicos'] != null 
              ? List<String>.from(_dolorSintomatologia['sintomasFisicos'])
              : [],
          emotionalSymptoms: _dolorSintomatologia['sintomasEmocionales'] != null 
              ? List<String>.from(_dolorSintomatologia['sintomasEmocionales'])
              : [],
          breastExam: _dolorSintomatologia['autoexamenMama'] as String?,
        );

        // Reprogramar notificaciones porque puede haber cambiado el inicio del periodo
        try {
          await NotificationService.instance.scheduleAllNotifications(_userId!);
        } catch (e) {
          debugPrint('Error scheduling notifications: $e');
        }
      } catch (e) {
        debugPrint('Error saving daily log: $e');
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
    final selected = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => DolorSintomatologiaScreen(initialData: _dolorSintomatologia),
      ),
    );
    if (selected != null) {
      setState(() {
        _dolorSintomatologia = selected;
      });
    }
  }

  String? _getBleedingSummary(String lang) {
    if (_patronSangrado.isEmpty) return null;
    final parts = <String>[];
    if (_patronSangrado['intensidadFlujo'] != null) parts.add(_patronSangrado['intensidadFlujo'].toString());
    if (_patronSangrado['coagulos'] != null && _patronSangrado['coagulos'] != 'Nunca' && _patronSangrado['coagulos'] != 'never' && _patronSangrado['coagulos'] != 'Never') {
      parts.add(_patronSangrado['coagulos'].toString());
    }
    if (parts.isEmpty) return AppTranslations.get('registration_form', 'saved', lang);
    return parts.join(' Â· ');
  }

  String? _getPainSummary(String lang) {
    if (_dolorSintomatologia.isEmpty) return null;
    final parts = <String>[];
    final nivel = _dolorSintomatologia['nivelDolor'];
    if (nivel != null) parts.add('EVA ${(nivel as num).toStringAsFixed(0)}/10');
    final caracter = _dolorSintomatologia['caracterDolor'];
    if (caracter != null && caracter.toString().isNotEmpty) parts.add(caracter.toString());
    final trat = _dolorSintomatologia['tratamiento'];
    if (trat != null && trat.toString().isNotEmpty && trat != 'none' && trat != 'Ninguno') parts.add(trat.toString());
    if (parts.isEmpty) return AppTranslations.get('registration_form', 'saved', lang);
    return parts.join(' Â· ');
  }

  String? _getListSummary(List<String> list) {
    if (list.isEmpty) return null;
    return list.take(3).join(', ') + (list.length > 3 ? ' +${list.length - 3}' : '');
  }

  @override
  Widget build(BuildContext context) {
    final lang = languageNotifier.currentLang;
    
    return Scaffold(
      backgroundColor: Theme.of(context).bellotaColors.basilica,
      appBar: _buildAppBar(context, lang),
      body: ListView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppTranslations.get('registration_form', 'log_progress', lang),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).bellotaColors.textoMedio, fontWeight: FontWeight.w500),
                    ),
                    Spacer(),
                    Text(
                      '${(_completionPercent * 6).toInt()}/6',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).bellotaColors.chilero, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _completionPercent,
                    minHeight: 6,
                    backgroundColor: Theme.of(context).bellotaColors.nancite,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _completionPercent >= 1.0 ? Theme.of(context).bellotaColors.chiltoma : Theme.of(context).bellotaColors.chilero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildDateHeader(context, lang),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildCard(
                  context,
                  icon: Icons.water_drop_outlined,
                  iconColor: Theme.of(context).bellotaColors.chilero,
                  title: AppTranslations.get('registration_form', 'period_starts', lang),
                  trailing: _buildSiNoToggle(
                    value: iniciaPeriodo,
                    onChanged: (val) => setState(() => iniciaPeriodo = val),
                    lang: lang,
                  ),
                ),
                SizedBox(height: 12),
                _buildCard(
                  context,
                  icon: Icons.favorite_border_rounded,
                  iconColor: Theme.of(context).bellotaColors.melon,
                  title: AppTranslations.get('registration_form', 'sex', lang),
                  subtitle: _getListSummary(_selectedSexo),
                  trailing: _buildAddButton(hasItems: _selectedSexo.isNotEmpty),
                  onTap: _openSexoSelection,
                ),
                SizedBox(height: 12),
                _buildCard(
                  context,
                  icon: Icons.medical_services_outlined,
                  iconColor: Theme.of(context).bellotaColors.asuncion,
                  title: AppTranslations.get('registration_form', 'symptoms', lang),
                  subtitle: _getListSummary(_selectedSymptoms),
                  trailing: _buildAddButton(hasItems: _selectedSymptoms.isNotEmpty),
                  onTap: _openSymptomsSelection,
                ),
                SizedBox(height: 12),
                _buildCard(
                  context,
                  icon: Icons.opacity_rounded,
                  iconColor: Color(0xFFA566C1),
                  title: AppTranslations.get('registration_form', 'vaginal_flow', lang),
                  subtitle: _getListSummary(_selectedFlujos),
                  trailing: _buildAddButton(hasItems: _selectedFlujos.isNotEmpty),
                  onTap: _openFlujoSelection,
                ),
                SizedBox(height: 12),
                _buildCard(
                  context,
                  icon: Icons.bloodtype_outlined,
                  iconColor: Theme.of(context).bellotaColors.chilero,
                  title: AppTranslations.get('registration_form', 'bleeding_pattern', lang),
                  subtitle: _getBleedingSummary(lang),
                  trailing: _buildAddButton(hasItems: _patronSangrado.isNotEmpty),
                  onTap: _openPatronSangradoSelection,
                ),
                SizedBox(height: 12),
                _buildCard(
                  context,
                  icon: Icons.healing_outlined,
                  iconColor: Theme.of(context).bellotaColors.chiltoma,
                  title: AppTranslations.get('registration_form', 'pain_and_symptoms', lang),
                  subtitle: _getPainSummary(lang),
                  trailing: _buildAddButton(hasItems: _dolorSintomatologia.isNotEmpty),
                  onTap: _openDolorSintomatologiaSelection,
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).bellotaColors.blanco,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: Theme.of(context).bellotaColors.asuncion.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(Icons.edit_note_rounded, color: Theme.of(context).bellotaColors.asuncion, size: 22),
                          ),
                          SizedBox(width: 14),
                          Text(
                            AppTranslations.get('registration_form', 'notes', lang),
                            style: TextStyle(fontSize: 15.5, color: Theme.of(context).bellotaColors.textoDark, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextField(
                        maxLines: 3,
                        minLines: 1,
                        onChanged: (v) => setState(() => _notes = v),
                        controller: _notesController,
                        style: TextStyle(fontSize: 14, color: Theme.of(context).bellotaColors.textoDark),
                        decoration: InputDecoration(
                          hintText: AppTranslations.get('registration_form', 'notes_hint', lang),
                          hintStyle: TextStyle(color: Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.6), fontSize: 13),
                          filled: true,
                          fillColor: Theme.of(context).bellotaColors.nancite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                _buildSaveButton(context, lang),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // APP BAR
  PreferredSizeWidget _buildAppBar(BuildContext context, String lang) {
    return AppBar(
      backgroundColor: Theme.of(context).bellotaColors.basilica,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).bellotaColors.blanco,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.10),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).bellotaColors.textoDark,
            size: 18,
          ),
        ),
      ),
      title: Text(
        AppTranslations.get('navigation', 'log', lang),
        style: TextStyle(
          color: Theme.of(context).bellotaColors.textoDark,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: _saveAndAccept,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppTranslations.get('onboarding', 'confirm', lang),
                style: TextStyle(
                  color: Theme.of(context).bellotaColors.chilero,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // DATE HEADER
  Widget _buildDateHeader(BuildContext context, String lang) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: Theme.of(context).bellotaColors.chilero,
          ),
        ),
        SizedBox(width: 10),
        Text(
          _formattedDate,
          style: TextStyle(
            color: Theme.of(context).bellotaColors.textoMedio,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.20),
                  Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // CARD POR ÃTEM
  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).bellotaColors.blanco,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.08),
              blurRadius: 14,
              spreadRadius: 0,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                if (subtitle != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).bellotaColors.chiltoma,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).bellotaColors.blanco, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      color: Theme.of(context).bellotaColors.textoDark,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.05,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.85),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 10),
            trailing,
          ],
        ),
      ),
    );
  }

  // TOGGLE SÃ / NO
  Widget _buildSiNoToggle({required bool value, required ValueChanged<bool> onChanged, required String lang}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bellotaColors.nancite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => onChanged(true),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: value ? Theme.of(context).bellotaColors.chilero : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: value
                    ? [BoxShadow(color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.25), blurRadius: 8, offset: Offset(0, 2))]
                    : [],
              ),
              child: Text(
                AppTranslations.get('registration_form', 'yes', lang),
                style: TextStyle(
                  color: value ? Colors.white : Theme.of(context).bellotaColors.textoMedio,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(false),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: !value ? Theme.of(context).bellotaColors.chilero : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: !value
                    ? [BoxShadow(color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.25), blurRadius: 8, offset: Offset(0, 2))]
                    : [],
              ),
              child: Text(
                AppTranslations.get('registration_form', 'no', lang),
                style: TextStyle(
                  color: !value ? Colors.white : Theme.of(context).bellotaColors.textoMedio,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BOTÃ“N AÃ‘ADIR
  Widget _buildAddButton({bool hasItems = false}) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: hasItems ? Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.12) : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).bellotaColors.chilero.withValues(alpha: hasItems ? 0.0 : 0.6),
          width: 1.5,
        ),
      ),
      child: Icon(
        hasItems ? Icons.edit_outlined : Icons.add_rounded,
        color: Theme.of(context).bellotaColors.chilero,
        size: 18,
      ),
    );
  }

  // BOTÃ“N GUARDAR
  Widget _buildSaveButton(BuildContext context, String lang) {
    return GestureDetector(
      onTap: _saveAndAccept,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: Theme.of(context).bellotaColors.buttonGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.30),
              blurRadius: 16,
              spreadRadius: 0,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              AppTranslations.get('registration_form', 'save_log', lang),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15.5,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



