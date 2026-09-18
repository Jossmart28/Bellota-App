import '../core/constants/app_keys.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import '../theme/theme_notifier.dart';
import 'notifications_settings_screen.dart';
import '../database/database_helper.dart';
import 'login_screen.dart';
import 'medical_report_preview_screen.dart';
import '../l10n/app_translations.dart';
import '../l10n/language_notifier.dart';
import '../core/models/user_model.dart';
import '../core/services/auth_service.dart';
import '../core/models/user_role.dart';
import '../navigation/navigation_service.dart';
import '../core/services/sync_service.dart';
import 'admin_panel_screen.dart';
import 'audit_dashboard_screen.dart';
import '../widgets/botanical_divider.dart';
import '../widgets/cozy_row_item.dart';
import '../widgets/cozy_section_header.dart';

/// Diseño fiel al mockup de referencia con paleta de colores Bellota.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  String _userName = 'UsuarioApp';
  String _userEmail = 'correo@ejemplo.com';
  int _cycleDuration = 28;
  int _periodDuration = 7;
  String? _profileImagePath;
  bool _profileImageExists = false;
  int? _userId;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await AuthService.instance.currentSessionUser();
    
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(AppKeys.userEmail) ?? 'correo@ejemplo.com';
    
    final userId = await DatabaseHelper.instance.getUserIdByEmail(email);
    if (userId != null) {
      final profile = await DatabaseHelper.instance.getProfile(userId);
      if (profile != null) {
        bool imageExists = false;
        if (profile['profile_image_path'] != null) {
          imageExists = File(profile['profile_image_path']).existsSync();
        }
        setState(() {
          _currentUser = user;
          _userId = userId;
          _userName = profile['username'] ?? 'UsuarioApp';
          _userEmail = email;
          _cycleDuration = profile['cycle_duration'] ?? 28;
          _periodDuration = profile['period_duration'] ?? 7;
          _profileImagePath = profile['profile_image_path'];
          _profileImageExists = imageExists;
        });
        return;
      }
    }
    
    // Fallback
    setState(() {
      _currentUser = user;
      _userName = 'UsuarioApp';
      _userEmail = email;
      _profileImagePath = null;
      _profileImageExists = false;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              AppTranslations.get('profile_and_report', 'logout', languageNotifier.currentLang),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Theme.of(context).bellotaColors.textoDark,
              ),
            ),
          ],
        ),
        content: Text(
          AppTranslations.get('profile_and_report', 'logout_confirm', languageNotifier.currentLang),
          style: GoogleFonts.poppins(fontSize: 13, color: Theme.of(context).bellotaColors.textoMedio),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppTranslations.get('profile_and_report', 'cancel', languageNotifier.currentLang),
              style: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.textoMedio, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: Size(0, 38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppTranslations.get('profile_and_report', 'logout', languageNotifier.currentLang), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      // Mantenemos datos médicos en la BD; solo limpiamos sesión activa
      await prefs.remove(AppKeys.userEmail);
      await prefs.remove(AppKeys.userId);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => LoginScreen(),
            transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
            transitionDuration: Duration(milliseconds: 600),
          ),
          (route) => false,
        );
      }
    }
  }


  Future<void> _saveCycleDuration(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cycleDuration', value);
    if (_userId != null) {
      await DatabaseHelper.instance.updateProfileField(_userId!, 'cycle_duration', value);
    }
  }

  Future<void> _savePeriodDuration(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('periodDuration', value);
    if (_userId != null) {
      await DatabaseHelper.instance.updateProfileField(_userId!, 'period_duration', value);
    }
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Color(0xFFD4C4B0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                AppTranslations.get('profile_and_report', 'change_photo', languageNotifier.currentLang),
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).bellotaColors.textoDark,
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library_outlined,
                      color: Theme.of(context).bellotaColors.melon),
                ),
                title: Text(AppTranslations.get('profile_and_report', 'gallery', languageNotifier.currentLang),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).bellotaColors.textoDark)),
                onTap: () {
                  Navigator.pop(ctx);
                  _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt_outlined,
                      color: Theme.of(context).bellotaColors.chilero),
                ),
                title: Text(AppTranslations.get('profile_and_report', 'camera', languageNotifier.currentLang),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).bellotaColors.textoDark)),
                onTap: () {
                  Navigator.pop(ctx);
                  _getImage(ImageSource.camera);
                },
              ),
              if (_profileImagePath != null)
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: Text(AppTranslations.get('profile_and_report', 'delete_photo', languageNotifier.currentLang),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500, color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('profileImagePath');
                    if (_userId != null) {
                      await DatabaseHelper.instance.updateProfileField(_userId!, 'profile_image_path', null);
                    }
                    setState(() {
                      _profileImagePath = null;
                      _profileImageExists = false;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImagePath', image.path);
        if (_userId != null) {
          await DatabaseHelper.instance.updateProfileField(_userId!, 'profile_image_path', image.path);
        }
        bool exists = File(image.path).existsSync();
        setState(() {
          _profileImagePath = image.path;
          _profileImageExists = exists;
        });
      }
    } catch (e) {
      // Error silencioso si el usuario cancela
    }
  }

  Future<void> _generateMedicalReport() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se encontró usuario.'), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(children: [
          CircularProgressIndicator(color: Theme.of(context).bellotaColors.chilero),
          SizedBox(width: 20),
          Text(AppTranslations.get('profile_and_report', 'generating_report', languageNotifier.currentLang)),
        ]),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final String fechaHoy = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final String reportId = (now.millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0');

      final String userAge = prefs.getString(AppKeys.userAge) ?? '';
      final String userLocation = prefs.getString(AppKeys.userLocation) ?? '';
      final List<String> medications = prefs.getStringList('user_medications') ?? [];

      final List<Map<String, dynamic>> allLogs = await DatabaseHelper.instance.getAllDailyLogs(_userId!);
      final List<DateTime> periodStarts = await DatabaseHelper.instance.getAllPeriodStartDates(_userId!);
      final DateTime? lastPeriod = await DatabaseHelper.instance.getLastPeriodStart(_userId!);
      final lang = languageNotifier.currentLang;
      final notSpec = AppTranslations.get('profile_and_report', 'not_specified', lang);

      final cycleStats = await DatabaseHelper.instance.getCycleStatistics(_userId!);
      final double? promCicloReal = cycleStats['averageCycleLength'] as double?;
      final double promCiclo = promCicloReal ?? _cycleDuration.toDouble();
      final double? promSangradoReal = await DatabaseHelper.instance.getRealBleedingAverage(_userId!);
      final double promSangrado = promSangradoReal ?? _periodDuration.toDouble();

      final String estadoCiclo = (promCiclo >= 21 && promCiclo <= 35)
          ? AppTranslations.get('profile_and_report', 'normal', lang)
          : AppTranslations.get('profile_and_report', 'irregular', lang);
      final String estadoSangrado = promSangrado >= 3 && promSangrado <= 7
          ? AppTranslations.get('profile_and_report', 'normal', lang)
          : (promSangrado > 7
              ? AppTranslations.get('profile_and_report', 'prolonged', lang)
              : AppTranslations.get('profile_and_report', 'short', lang));

      String fum = lastPeriod != null
          ? '${lastPeriod.day.toString().padLeft(2, '0')}/${lastPeriod.month.toString().padLeft(2, '0')}/${lastPeriod.year}'
          : notSpec;
      String rangoInicio = fum;
      String rangoFin = lastPeriod != null
          ? () {
              final end = lastPeriod.add(Duration(days: promCiclo.toInt()));
              return '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
            }()
          : fechaHoy;

      Map<String, int> flujoCount = {};
      final endOfCycle = lastPeriod?.add(Duration(days: promCiclo.toInt()));
      for (final log in allLogs) {
        if (lastPeriod != null && endOfCycle != null) {
          try {
            final d = DateTime.parse(log['date'] as String);
            if (d.isAfter(lastPeriod.subtract(Duration(days: 1))) && d.isBefore(endOfCycle.add(Duration(days: 1)))) {
              for (final f in (jsonDecode(log['flujo'] as String? ?? '[]') as List)) {
                flujoCount[f.toString()] = (flujoCount[f.toString()] ?? 0) + 1;
              }
            }
          } catch (_) {}
        }
      }
      final flujoMasFrecuente = flujoCount.isNotEmpty
          ? flujoCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key
          : null;

      Map<String, int> sympCount = {};
      for (final log in allLogs) {
        for (final s in (jsonDecode(log['symptoms'] as String? ?? '[]') as List)) {
          sympCount[s.toString()] = (sympCount[s.toString()] ?? 0) + 1;
        }
      }
      final topSyms = (sympCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5).map((e) => e.key).toList();

      Map<String, dynamic> patron = {};
      Map<String, dynamic> dolor = {};
      for (final log in allLogs.reversed) {
        if (patron.isEmpty && log['bleeding_intensity'] != null) {
          patron = {
            'intensidadFlujo': log['bleeding_intensity'],
            'coagulos': log['clots'],
            'manchado': (log['spotting'] as int?) == 1
                ? AppTranslations.get('registration_form', 'yes', lang)
                : AppTranslations.get('registration_form', 'no', lang),
            'manchadoDias': log['spotting_days'],
            'sintomasSexuales': log['sexual_symptoms'],
          };
        }
        if (dolor.isEmpty && log['pain_level'] != null) {
          final physList = <String>[];
          try {
            final decoded = jsonDecode(log['physical_symptoms'] as String? ?? '[]');
            if (decoded is List) physList.addAll(decoded.map((e) => e.toString()));
          } catch (_) {}
          final emoList = <String>[];
          try {
            final decoded = jsonDecode(log['emotional_symptoms'] as String? ?? '[]');
            if (decoded is List) emoList.addAll(decoded.map((e) => e.toString()));
          } catch (_) {}
          dolor = {
            'nivelDolor': log['pain_level'],
            'caracterDolor': log['pain_character'],
            'diasDolor': log['pain_days'],
            'tratamiento': log['treatment'],
            'sintomasFisicos': physList,
            'sintomasEmocionales': emoList,
            'autoexamenMama': log['breast_exam'],
          };
        }
        if (patron.isNotEmpty && dolor.isNotEmpty) break;
      }

      List<Map<String, String>> alertas = [];
      final String irregStr = AppTranslations.get('profile_and_report', 'irregular_cycles', lang);
      if (promCiclo < 21 || promCiclo > 35) {
        alertas.add({'tipo': irregStr, 'detalle': AppTranslations.get('registration_form', 'alert_irregular_detail', lang).replaceAll('{value}', promCiclo.toStringAsFixed(0))});
      } else {
        alertas.add({'tipo': irregStr, 'detalle': AppTranslations.get('registration_form', 'normal_duration_detail', lang).replaceAll('{value}', promCiclo.toStringAsFixed(0))});
      }
      final String prolonStr = AppTranslations.get('profile_and_report', 'prolonged_bleeding', lang);
      if (promSangrado > 7) {
        alertas.add({'tipo': prolonStr, 'detalle': AppTranslations.get('registration_form', 'alert_bleeding_detail', lang).replaceAll('{value}', promSangrado.toInt().toString())});
      } else {
        alertas.add({'tipo': prolonStr, 'detalle': AppTranslations.get('registration_form', 'normal_duration_detail', lang).replaceAll('{value}', promSangrado.toInt().toString())});
      }
      final String ameStr = AppTranslations.get('profile_and_report', 'amenorrhea', lang);
      if (lastPeriod == null) {
        alertas.add({'tipo': ameStr, 'detalle': AppTranslations.get('registration_form', 'alert_amenorrhea_detail', lang)});
      } else {
        alertas.add({'tipo': ameStr, 'detalle': AppTranslations.get('registration_form', 'no_alert_amenorrhea', lang).replaceAll('{value}', fum)});
      }
      final nivelD = dolor['nivelDolor'];
      final String alertPStr = AppTranslations.get('profile_and_report', 'alert_pain', lang);
      if (nivelD != null && (nivelD as num) >= 8) {
        alertas.add({'tipo': alertPStr, 'detalle': AppTranslations.get('registration_form', 'alert_severe_pain_detail', lang).replaceAll('{value}', (nivelD).toStringAsFixed(0))});
      } else if (nivelD != null) {
        alertas.add({'tipo': alertPStr, 'detalle': AppTranslations.get('registration_form', 'pain_normal_range', lang).replaceAll('{value}', (nivelD).toStringAsFixed(0))});
      } else {
        alertas.add({'tipo': alertPStr, 'detalle': AppTranslations.get('registration_form', 'no_pain_logged', lang)});
      }

      Map<String, dynamic> filterNulls(Map<String, dynamic> m) {
        return Map.fromEntries(m.entries.where((e) => e.value != null && e.value != ''));
      }

      final report = {
        'metadata': {
          'numero_reporte': reportId,
          'fecha_generacion': fechaHoy,
          'version': '1.0',
          'app': 'Bellota - Calendario Menstrual',
          'tipo': 'Reporte de salud menstrual y clínico ginecológico',
          'uso': 'Seguimiento y apoyo para consulta profesional',
          'aviso': AppTranslations.get('registration_form', 'report_disclaimer', lang),
        },
        'seccion_1_informacion_general': filterNulls({
          'paciente': _userName,
          'edad': userAge.isNotEmpty ? '$userAge ${lang == 'en' ? 'years' : 'años'}' : notSpec,
          'ubicacion': userLocation.isNotEmpty ? userLocation : notSpec,
          'fecha_generacion': fechaHoy,
          'rango_analizado': lastPeriod != null ? '$rangoInicio al $rangoFin' : notSpec,
          'total_ciclos': periodStarts.length,
          'anticonceptivos_medicamentos': medications.isNotEmpty ? medications.join(', ') : notSpec,
          'fum': fum,
        }),
        'seccion_2_resumen_estadistico': filterNulls({
          'promedio_ciclo': {
            'valor': '${promCiclo.toStringAsFixed(0)} ${AppTranslations.get('profile_and_report', 'days', lang)}',
            'referencia': '21-35 ${AppTranslations.get('profile_and_report', 'days', lang)}',
            'estado': estadoCiclo,
          },
          'promedio_sangrado': {
            'valor': '${promSangrado.toInt()} ${AppTranslations.get('profile_and_report', 'days', lang)}',
            'referencia': '3-7 ${AppTranslations.get('profile_and_report', 'days', lang)}',
            'estado': estadoSangrado,
          },
          'fum': fum,
          'flujo_mas_frecuente': flujoMasFrecuente ?? notSpec,
          if (topSyms.isNotEmpty) 'sintomas_mas_frecuentes': topSyms,
        }),
        if (patron.isNotEmpty) 'seccion_3_patron_sangrado_flujo': filterNulls({
          'intensidad_flujo': patron['intensidadFlujo'],
          'coagulos': patron['coagulos'],
          'manchado_intermenstrual': patron['manchado'],
          if ((patron['manchadoDias'] as String?)?.isNotEmpty == true) 'manchado_dias': patron['manchadoDias'],
          'sintomas_relaciones_sexuales': patron['sintomasSexuales'],
        }),
        if (dolor.isNotEmpty) 'seccion_4_dolor_sintomatologia': filterNulls({
          'nivel_dolor_eva': dolor['nivelDolor'] != null ? '${(dolor['nivelDolor'] as num).toStringAsFixed(0)}/10' : null,
          'caracter': dolor['caracterDolor'],
          if ((dolor['diasDolor'] as String?)?.isNotEmpty == true) 'dias_dolor_critico': dolor['diasDolor'],
          'tratamiento': dolor['tratamiento'],
          if ((dolor['sintomasFisicos'] as List?)?.isNotEmpty == true)
            'sintomas_fisicos': (dolor['sintomasFisicos'] as List).join(', '),
          if ((dolor['sintomasEmocionales'] as List?)?.isNotEmpty == true)
            'sintomas_emocionales': (dolor['sintomasEmocionales'] as List).join(', '),
          'autoexamen_mama': dolor['autoexamenMama'],
        }),
        'seccion_5_alertas_automaticas': alertas,
      };

      // Guardar en documentos
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'bellota_informe_$reportId.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(JsonEncoder.withIndent('  ').convert(report));

      if (mounted) Navigator.of(context).pop(); // Cerrar loader
      
      // JSON invisible guardado, ahora navegamos a la vista previa
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicalReportPreviewScreen(reportData: report),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppTranslations.get('profile_and_report', 'generating_report', languageNotifier.currentLang)} - Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCycleDurationPicker() {
    int tempValue = _cycleDuration;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color(0xFFD4C4B0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  AppTranslations.get('profile_and_report', 'cycle_duration', languageNotifier.currentLang),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).bellotaColors.textoDark,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  AppTranslations.get('profile_and_report', 'adjust_cycle', languageNotifier.currentLang),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Theme.of(context).bellotaColors.textoMedio,
                  ),
                ),
                SizedBox(height: 30),
                // Value display
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).bellotaColors.melon.withValues(alpha: 0.15),
                        Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.10),
                      ],
                    ),
                    border: Border.all(
                      color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$tempValue',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).bellotaColors.melon,
                        ),
                      ),
                      Text(
                        AppTranslations.get('profile_and_report', 'days', languageNotifier.currentLang),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).bellotaColors.textoMedio,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                // Slider
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Theme.of(context).bellotaColors.melon,
                    inactiveTrackColor:
                        Theme.of(context).bellotaColors.melon.withValues(alpha: 0.15),
                    thumbColor: Colors.white,
                    overlayColor:
                        Theme.of(context).bellotaColors.melon.withValues(alpha: 0.15),
                    thumbShape: _CustomThumbShape(thumbColor: Theme.of(context).bellotaColors.melon),
                    trackHeight: 6,
                    trackShape: RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: tempValue.toDouble(),
                    min: 20,
                    max: 45,
                    divisions: 25,
                    label: '$tempValue ${AppTranslations.get('profile_and_report', 'days', languageNotifier.currentLang)}',
                    onChanged: (val) {
                      setModalState(() => tempValue = val.round());
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('20 ${AppTranslations.get('profile_and_report', 'days', languageNotifier.currentLang)}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Theme.of(context).bellotaColors.textoMedio)),
                      Text('45 ${AppTranslations.get('profile_and_report', 'days', languageNotifier.currentLang)}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Theme.of(context).bellotaColors.textoMedio)),
                    ],
                  ),
                ),
                SizedBox(height: 28),
                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _cycleDuration = tempValue);
                      _saveCycleDuration(tempValue);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).bellotaColors.chilero,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      AppTranslations.get('profile_and_report', 'save', languageNotifier.currentLang),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPeriodDurationPicker() {
    int tempValue = _periodDuration;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color(0xFFD4C4B0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  AppTranslations.get('profile_and_report', 'period_duration', languageNotifier.currentLang),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).bellotaColors.textoDark,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  AppTranslations.get('profile_and_report', 'adjust_period', languageNotifier.currentLang),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Theme.of(context).bellotaColors.textoMedio,
                  ),
                ),
                SizedBox(height: 30),
                // Value display
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.15),
                        Theme.of(context).bellotaColors.melon.withValues(alpha: 0.10),
                      ],
                    ),
                    border: Border.all(
                      color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$tempValue',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).bellotaColors.chilero,
                        ),
                      ),
                      Text(
                        tempValue == 1 ? AppTranslations.get('profile_and_report', 'day', languageNotifier.currentLang) : AppTranslations.get('profile_and_report', 'days', languageNotifier.currentLang),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).bellotaColors.textoMedio,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                // Slider
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Theme.of(context).bellotaColors.chilero,
                    inactiveTrackColor:
                        Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.15),
                    thumbColor: Colors.white,
                    overlayColor:
                        Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.15),
                    thumbShape: _CustomThumbShape(thumbColor: Theme.of(context).bellotaColors.melon),
                    trackHeight: 6,
                    trackShape: RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: tempValue.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$tempValue ${tempValue == 1 ? AppTranslations.get('profile_and_report', 'day', languageNotifier.currentLang) : AppTranslations.get('profile_and_report', 'days', languageNotifier.currentLang)}',
                    onChanged: (val) {
                      setModalState(() => tempValue = val.round());
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 ${AppTranslations.get('profile_and_report', 'day', languageNotifier.currentLang)}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Theme.of(context).bellotaColors.textoMedio)),
                      Text('10 ${AppTranslations.get('profile_and_report', 'days', languageNotifier.currentLang)}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Theme.of(context).bellotaColors.textoMedio)),
                    ],
                  ),
                ),
                SizedBox(height: 28),
                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _periodDuration = tempValue);
                      _savePeriodDuration(tempValue);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).bellotaColors.chilero,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      AppTranslations.get('profile_and_report', 'save', languageNotifier.currentLang),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        final colors = Theme.of(context).bellotaColors;
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // ── Banner Header Cozy ──────────────────────────
              _buildCozyProfileBanner(context, colors),
              // ── Secciones con divisores botánicos ───────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    const BotanicalDivider(),
                    const SizedBox(height: 20),
                    _buildHealthSection(),
                    const SizedBox(height: 20),
                    const BotanicalDivider(),
                    const SizedBox(height: 20),
                    _buildPreferencesSection(),
                    if (_currentUser != null && (_currentUser!.isAdmin || _currentUser!.isAuditor)) ...[
                      const SizedBox(height: 20),
                      const BotanicalDivider(),
                      const SizedBox(height: 20),
                      _buildAdminSection(),
                    ],
                    const SizedBox(height: 20),
                    const BotanicalDivider(),
                    const SizedBox(height: 20),
                    _buildDataSection(),
                    const SizedBox(height: 20),
                    const BotanicalDivider(opacity: 0.25),
                    const SizedBox(height: 20),
                    _buildLogoutButton(),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Banner superior del perfil — tarjeta cozy con borde de color y esquina decorativa
  Widget _buildCozyProfileBanner(BuildContext context, BellotaColors colors) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: colors.nancite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.melon.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.melon.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Franja decorativa superior (como el borde de una postal)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                gradient: LinearGradient(
                  colors: [colors.melon.withValues(alpha: 0.7), colors.chilero.withValues(alpha: 0.7)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: SvgPicture.asset(
              'assets/decorations/profile_corner_deco.svg',
              width: 52,
              height: 52,
              colorFilter: ColorFilter.mode(colors.chiltoma.withValues(alpha: 0.6), BlendMode.srcIn),
            ),
          ),
          // Contenido del banner
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.blanco.withValues(alpha: 0.7),
                          border: Border.all(color: colors.nancite, width: 1),
                        ),
                        child: Icon(Icons.translate_rounded, size: 16, color: colors.textoDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.chilero,
                          boxShadow: [BoxShadow(color: colors.chilero.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: const Icon(Icons.volume_up_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAvatarSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildAdminSection() {
    final colors = Theme.of(context).bellotaColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CozySectionHeader(
          title: 'Administración',
        ),
        const SizedBox(height: 14),
        if (_currentUser!.isAdmin)
          CozyRowItem(
            title: 'Panel de Administrador',
            value: 'Gestionar usuarios',
            onTap: () {
              NavigationService.goTo(context, const AdminPanelScreen());
            },
            icon: Icons.admin_panel_settings_rounded,
            iconBackgroundColor: colors.chilero.withValues(alpha: 0.10),
            iconColor: colors.chilero,
          ),
        if (_currentUser!.isAdmin) const SizedBox(height: 8),
        if (_currentUser!.isAdmin || _currentUser!.isAuditor)
          CozyRowItem(
            title: 'Registro de Auditoría',
            value: 'Ver logs',
            onTap: () {
              NavigationService.goTo(context, const AuditDashboardScreen());
            },
            icon: Icons.list_alt_rounded,
            iconBackgroundColor: colors.asuncion.withValues(alpha: 0.10),
            iconColor: colors.asuncion,
          ),
      ],
    );
  }
  
  Widget _buildDataSection() {
    final colors = Theme.of(context).bellotaColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CozySectionHeader(
          title: 'Mis Datos',
        ),
        const SizedBox(height: 14),
        CozyRowItem(
          title: 'Exportar Backup',
          value: 'Guardar mis datos',
          onTap: () async {
            if (_userId != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generando backup...')),
              );
              await SyncService.instance.exportAndShareBackup(_userId!);
            }
          },
          icon: Icons.cloud_download_rounded,
          iconBackgroundColor: colors.chilero.withValues(alpha: 0.10),
          iconColor: colors.chilero,
        ),
        const SizedBox(height: 8),
        CozyRowItem(
          title: 'Importar Backup',
          value: 'Restaurar datos',
          onTap: () async {
            if (_userId != null) {
              final result = await SyncService.instance.importBackup(_userId!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result ? 'Datos restaurados con éxito' : 'Error al restaurar datos'),
                    backgroundColor: result ? Colors.green : Colors.red,
                  ),
                );
                if (result) _loadProfile(); // recargar datos
              }
            }
          },
          icon: Icons.cloud_upload_rounded,
          iconBackgroundColor: colors.asuncion.withValues(alpha: 0.10),
          iconColor: colors.asuncion,
        ),
      ],
    );
  }


  Widget _buildLogoutButton() {
    bool isPressed = false;
    return StatefulBuilder(
      builder: (context, setState) {
        
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) {
            setState(() => isPressed = false);
            _handleLogout();
          },
          onTapCancel: () => setState(() => isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isPressed ? Colors.red.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: Colors.red.withValues(alpha: 0.35),
                radius: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedRotation(
                    turns: isPressed ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppTranslations.get('profile_and_report', 'logout', languageNotifier.currentLang),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }




  Widget _buildAvatarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        Center(
          child: GestureDetector(
          onTap: _pickProfileImage,
          child: Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.4),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _profileImageExists && _profileImagePath != null
                      ? Image.file(
                          File(_profileImagePath!),
                          fit: BoxFit.cover,
                          width: 110,
                          height: 110,
                        )
                      : Image.asset(
                          'assets/images/default_avatar.png',
                          fit: BoxFit.cover,
                          width: 110,
                          height: 110,
                        ),
                ),
              ),
              // Camera icon overlay
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).bellotaColors.chilero,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
        ),
        SizedBox(height: 14),
        // Username
        Text(
          _userName,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).bellotaColors.textoDark,
          ),
        ),
        SizedBox(height: 2),
        // Email
        Text(
          _userEmail,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).bellotaColors.textoMedio,
          ),
        ),
        if (_currentUser != null && _currentUser!.role != UserRole.usuario) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _currentUser!.isAdmin ? Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.15) : Theme.of(context).bellotaColors.asuncion.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _currentUser!.isAdmin ? Icons.admin_panel_settings : Icons.manage_search,
                  size: 14,
                  color: _currentUser!.isAdmin ? Theme.of(context).bellotaColors.chilero : Theme.of(context).bellotaColors.asuncion,
                ),
                SizedBox(width: 4),
                Text(
                  RolePermissions.roleName(_currentUser!.role),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _currentUser!.isAdmin ? Theme.of(context).bellotaColors.chilero : Theme.of(context).bellotaColors.asuncion,
                  ),
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildHealthSection() {
    final colors = Theme.of(context).bellotaColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CozySectionHeader(
          title: AppTranslations.get('profile_and_report', 'health_profile', languageNotifier.currentLang),
        ),
        const SizedBox(height: 14),
        CozyRowItem(
          title: AppTranslations.get('profile_and_report', 'cycle_duration', languageNotifier.currentLang),
          value: '$_cycleDuration ${AppTranslations.get('profile_and_report', 'days', languageNotifier.currentLang)}',
          onTap: _showCycleDurationPicker,
          icon: Icons.autorenew_rounded,
          iconBackgroundColor: colors.melon.withValues(alpha: 0.10),
          iconColor: colors.melon,
        ),
        const SizedBox(height: 8),
        CozyRowItem(
          title: AppTranslations.get('profile_and_report', 'period_duration', languageNotifier.currentLang),
          value: '$_periodDuration ${AppTranslations.get('profile_and_report', 'days', languageNotifier.currentLang)}',
          onTap: _showPeriodDurationPicker,
          icon: Icons.water_drop_outlined,
          iconBackgroundColor: colors.chilero.withValues(alpha: 0.10),
          iconColor: colors.chilero,
        ),
        const SizedBox(height: 8),
        CozyRowItem(
          title: AppTranslations.get('profile_and_report', 'medical_report', languageNotifier.currentLang),
          value: AppTranslations.get('profile_and_report', 'generate', languageNotifier.currentLang),
          onTap: _generateMedicalReport,
          icon: Icons.picture_as_pdf_outlined,
          iconBackgroundColor: colors.chiltoma.withValues(alpha: 0.10),
          iconColor: colors.chiltoma,
        ),
      ],
    );
  }


  Widget _buildPreferencesSection() {
    final colors = Theme.of(context).bellotaColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CozySectionHeader(
          title: AppTranslations.get('profile_and_report', 'app_preferences', languageNotifier.currentLang),
        ),
        const SizedBox(height: 14),
        // Recordatorios y notificaciones
        CozyRowItem(
          title: AppTranslations.get('profile_and_report', 'reminders_notifications', languageNotifier.currentLang),
          value: '',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsSettingsScreen(),
              ),
            );
          },
          icon: Icons.notifications_none_rounded,
          iconBackgroundColor: colors.melon.withValues(alpha: 0.10),
          iconColor: colors.melon,
        ),
        const SizedBox(height: 8),
        // Política de privacidad
        CozyRowItem(
          title: AppTranslations.get('profile_and_report', 'privacy_policy', languageNotifier.currentLang),
          value: '',
          onTap: () {}, // Sin función
          icon: Icons.shield_outlined,
          iconBackgroundColor: colors.chiltoma.withValues(alpha: 0.10),
          iconColor: colors.chiltoma,
        ),
        const SizedBox(height: 8),
        // Idioma
        CozyRowItem(
          title: AppTranslations.get('profile_and_report', 'language', languageNotifier.currentLang),
          value: languageNotifier.currentLang == 'es' ? 'Español' : (languageNotifier.currentLang == 'mi' ? 'Miskito' : 'English'),
          onTap: () {}, // Sin función
          icon: Icons.language_rounded,
          iconBackgroundColor: colors.asuncion.withValues(alpha: 0.10),
          iconColor: colors.asuncion,
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (_, mode, _) {
            final isDark = mode == ThemeMode.dark;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: colors.blanco,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.nancite.withValues(alpha: 0.6),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Ícono de apariencia
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark 
                        ? const Color(0xFF9B7FD4).withValues(alpha: 0.10) 
                        : colors.melon.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      size: 18,
                      color: isDark ? const Color(0xFF9B7FD4) : colors.melon,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.get('profile_and_report', 'appearance', languageNotifier.currentLang),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.textoDark,
                          ),
                        ),
                        Text(
                          isDark 
                            ? AppTranslations.get('profile_and_report', AppKeys.darkMode, languageNotifier.currentLang) 
                            : AppTranslations.get('profile_and_report', 'light_mode', languageNotifier.currentLang),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                            color: colors.textoMedio,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isDark,
                    onChanged: (_) {
                      HapticFeedback.lightImpact();
                      themeNotifier.toggle();
                    },
                    activeThumbColor: const Color(0xFF9B7FD4),
                    activeTrackColor: const Color(0xFF9B7FD4).withValues(alpha: 0.3),
                    inactiveThumbColor: colors.melon,
                    inactiveTrackColor: colors.melon.withValues(alpha: 0.3),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

}

class _CustomThumbShape extends SliderComponentShape {
  final Color thumbColor;
  
  const _CustomThumbShape({required this.thumbColor});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size(24, 24);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Shadow
    canvas.drawCircle(
      center + Offset(0, 1),
      13,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.10)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3),
    );

    // White fill
    canvas.drawCircle(
      center,
      12,
      Paint()..color = Colors.white,
    );

    // Colored border
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = sliderTheme.activeTrackColor ?? thumbColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Inner dot
    canvas.drawCircle(
      center,
      5,
      Paint()..color = sliderTheme.activeTrackColor ?? thumbColor,
    );
  }
}

// ──────────────────────────────────────────────────────
// Painter para el borde discontinuo (dashed) del botón
// ──────────────────────────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
      
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), 
        Radius.circular(radius)
      ));

    const double dashWidth = 5;
    const double dashSpace = 4;
    double distance = 0;
    
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}






