import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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
import '../core/services/role_guard.dart';
import '../core/services/user_role.dart';
import '../core/services/navigation_service.dart';
import 'admin_panel_screen.dart';
import 'audit_dashboard_screen.dart';

/// Pantalla de Perfil de usuario — Bellota App
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
    final email = prefs.getString('userEmail') ?? 'correo@ejemplo.com';
    
    final userId = await DatabaseHelper.instance.getUserIdByEmail(email);
    if (userId != null) {
      final profile = await DatabaseHelper.instance.getProfile(userId);
      if (profile != null) {
        setState(() {
          _currentUser = user;
          _userId = userId;
          _userName = profile['username'] ?? prefs.getString('userName') ?? 'UsuarioApp';
          _userEmail = email;
          _cycleDuration = profile['cycle_duration'] ?? 28;
          _periodDuration = profile['period_duration'] ?? 7;
          _profileImagePath = profile['profile_image_path'] ?? prefs.getString('profileImagePath');
        });
        return;
      }
    }
    
    // Fallback
    setState(() {
      _currentUser = user;
      _userEmail = email;
      _userName = prefs.getString('userName') ?? 'UsuarioApp';
      _cycleDuration = prefs.getInt('cycleDuration') ?? 28;
      _periodDuration = prefs.getInt('periodDuration') ?? 7;
      _profileImagePath = prefs.getString('profileImagePath');
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
                color: BellotaColors.textoDark,
              ),
            ),
          ],
        ),
        content: Text(
          AppTranslations.get('profile_and_report', 'logout_confirm', languageNotifier.currentLang).replaceAll('\\n', '\n'),
          style: GoogleFonts.poppins(fontSize: 13, color: BellotaColors.textoMedio),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppTranslations.get('profile_and_report', 'cancel', languageNotifier.currentLang),
              style: GoogleFonts.poppins(color: BellotaColors.textoMedio, fontWeight: FontWeight.w500),
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
      await prefs.remove('userEmail');
      await prefs.remove('userId');

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
                  color: BellotaColors.textoDark,
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: BellotaColors.melon.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library_outlined,
                      color: BellotaColors.melon),
                ),
                title: Text(AppTranslations.get('profile_and_report', 'gallery', languageNotifier.currentLang),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: BellotaColors.textoDark)),
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
                    color: BellotaColors.chilero.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt_outlined,
                      color: BellotaColors.chilero),
                ),
                title: Text(AppTranslations.get('profile_and_report', 'camera', languageNotifier.currentLang),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: BellotaColors.textoDark)),
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
                    setState(() => _profileImagePath = null);
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
        setState(() => _profileImagePath = image.path);
      }
    } catch (e) {
      // Error silencioso si el usuario cancela
    }
  }

  // ── Generar Informe Médico en JSON ──
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
        content: Row(children: [
          CircularProgressIndicator(),
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

      final String userAge = prefs.getString('user_age') ?? '';
      final String userLocation = prefs.getString('user_location') ?? '';
      final List<String> medications = prefs.getStringList('user_medications') ?? [];

      final List<Map<String, dynamic>> allLogs = await DatabaseHelper.instance.getAllDailyLogs(_userId!);
      final List<DateTime> periodStarts = await DatabaseHelper.instance.getAllPeriodStartDates(_userId!);
      final DateTime? lastPeriod = await DatabaseHelper.instance.getLastPeriodStart(_userId!);
      final DateTime? firstPeriod = await DatabaseHelper.instance.getFirstPeriodStart(_userId!);
      final lang = languageNotifier.currentLang;
      final notSpec = AppTranslations.get('profile_and_report', 'not_specified', lang);

      String fum = lastPeriod != null
          ? '${lastPeriod.day.toString().padLeft(2, '0')}/${lastPeriod.month.toString().padLeft(2, '0')}/${lastPeriod.year}'
          : notSpec;
      String rangoInicio = lastPeriod != null
          ? '${lastPeriod.day.toString().padLeft(2, '0')}/${lastPeriod.month.toString().padLeft(2, '0')}/${lastPeriod.year}'
          : notSpec;
      String rangoFin = lastPeriod != null
          ? () {
              final end = lastPeriod.add(Duration(days: _cycleDuration));
              return '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
            }()
          : fechaHoy;

      // Promedio ciclo
      double? promCiclo = _cycleDuration.toDouble();
      String estadoCiclo = (promCiclo >= 21 && promCiclo <= 35) ? AppTranslations.get('profile_and_report', 'normal', lang) : AppTranslations.get('profile_and_report', 'irregular', lang);
      final sortedPeriods = List<DateTime>.from(periodStarts)..sort();

      double promSangrado = _periodDuration.toDouble();
      String estadoSangrado = promSangrado >= 3 && promSangrado <= 7 ? AppTranslations.get('profile_and_report', 'normal', lang) : (promSangrado > 7 ? AppTranslations.get('profile_and_report', 'prolonged', lang) : AppTranslations.get('profile_and_report', 'short', lang));

      // Flujo más frecuente en el ciclo actual
      Map<String, int> flujoCount = {};
      DateTime? endOfCycle = lastPeriod?.add(Duration(days: _cycleDuration));
      
      for (final log in allLogs) {
        if (lastPeriod != null && endOfCycle != null) {
          try {
            final d = DateTime.parse(log['date'] as String);
            if (d.isAfter(lastPeriod.subtract(Duration(days: 1))) && d.isBefore(endOfCycle.add(Duration(days: 1)))) {
              for (final f in (jsonDecode(log['flujo'] as String? ?? '[]') as List)) {
                flujoCount[f.toString()] = (flujoCount[f.toString()] ?? 0) + 1;
              }
            }
          } catch (e) {
            // ignore parse errors
          }
        }
      }
      final flujoMasFrecuente = flujoCount.isNotEmpty
          ? flujoCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key
          : null;

      // Síntomas más frecuentes
      Map<String, int> sympCount = {};
      for (final log in allLogs) {
        for (final s in (jsonDecode(log['symptoms'] as String? ?? '[]') as List)) {
          sympCount[s.toString()] = (sympCount[s.toString()] ?? 0) + 1;
        }
      }
      final topSyms = (sympCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5).map((e) => e.key).toList();

      // Patrón de sangrado y dolor más recientes
      Map<String, dynamic> patron = {};
      Map<String, dynamic> dolor = {};
      for (final log in allLogs.reversed) {
        final dk = log['date'] as String;
        if (patron.isEmpty) {
          final p = prefs.getString('patron_sangrado_$dk');
          if (p != null) patron = jsonDecode(p);
        }
        if (dolor.isEmpty) {
          final d = prefs.getString('dolor_sintomatologia_$dk');
          if (d != null) dolor = jsonDecode(d);
        }
        if (patron.isNotEmpty && dolor.isNotEmpty) break;
      }


      // Alertas automáticas
      List<Map<String, String>> alertas = [];
      String irregStr = AppTranslations.get('profile_and_report', 'irregular_cycles', lang);
      if (promCiclo != null && (promCiclo < 21 || promCiclo > 35)) {
        alertas.add({'tipo': irregStr, 'detalle': lang == 'mi' ? 'Alerta: ${promCiclo.toStringAsFixed(0)} yu (pain 21-35 yu)' : (lang == 'en' ? 'Alert: ${promCiclo.toStringAsFixed(0)} days (normal 21-35 days)' : 'Alerta: ${promCiclo.toStringAsFixed(0)} días (normal 21-35 días)')});
      } else if (promCiclo != null) {
        alertas.add({'tipo': irregStr, 'detalle': lang == 'mi' ? 'Luhka pain: ${promCiclo.toStringAsFixed(0)} yu' : (lang == 'en' ? 'Normal duration: ${promCiclo.toStringAsFixed(0)} days' : 'Duración normal: ${promCiclo.toStringAsFixed(0)} días')});
      }
      String prolonStr = AppTranslations.get('profile_and_report', 'prolonged_bleeding', lang);
      if (promSangrado > 7) {
        alertas.add({'tipo': prolonStr, 'detalle': lang == 'mi' ? 'Alerta: ${promSangrado.toInt()} yu (máx. 7 yu)' : (lang == 'en' ? 'Alert: ${promSangrado.toInt()} consecutive days (max 7 days)' : 'Alerta: ${promSangrado.toInt()} días consecutivos (máx. 7 días)')});
      } else {
        alertas.add({'tipo': prolonStr, 'detalle': lang == 'mi' ? 'Luhka pain: ${promSangrado.toInt()} yu' : (lang == 'en' ? 'Normal duration: ${promSangrado.toInt()} days' : 'Duración normal: ${promSangrado.toInt()} días')});
      }
      String ameStr = AppTranslations.get('profile_and_report', 'amenorrhea', lang);
      if (lastPeriod == null) {
        alertas.add({'tipo': ameStr, 'detalle': lang == 'mi' ? 'Alerta: ulbanka apia. Kati balras.' : (lang == 'en' ? 'Alert: no log. Possible delay without pregnancy confirmed.' : 'Alerta: sin registro. Posible retraso sin confirmación de embarazo.')});
      } else {
        alertas.add({'tipo': ameStr, 'detalle': lang == 'mi' ? 'Alerta apia. Kati ta: $fum' : (lang == 'en' ? 'No alert. Last period logged: $fum' : 'Sin alerta. Última menstruación registrada: $fum')});
      }
      final nivelD = dolor['nivelDolor'];
      String alertPStr = AppTranslations.get('profile_and_report', 'alert_pain', lang);
      if (nivelD != null && (nivelD as num) >= 8) {
        alertas.add({'tipo': alertPStr, 'detalle': lang == 'mi' ? 'Alerta: latwan tara ${nivelD.toStringAsFixed(0)}/10' : (lang == 'en' ? 'Alert: severe pain ${nivelD.toStringAsFixed(0)}/10 that does not subside' : 'Alerta: dolor severo ${nivelD.toStringAsFixed(0)}/10 que no cede')});
      } else {
        alertas.add({'tipo': alertPStr, 'detalle': nivelD != null ? (lang == 'mi' ? 'Latwan pain: ${(nivelD as num).toStringAsFixed(0)}/10' : (lang == 'en' ? 'Pain in normal range: ${(nivelD as num).toStringAsFixed(0)}/10' : 'Dolor dentro del rango: ${(nivelD as num).toStringAsFixed(0)}/10')) : (lang == 'mi' ? 'Latwan ulbanka apia' : (lang == 'en' ? 'No pain logged' : 'Sin registro de dolor'))});
      }

      // ─── Construcción del JSON final (sin nulos) ───
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
          'aviso': 'Este reporte no sustituye una valoración médica profesional.',
        },
        'seccion_1_informacion_general': filterNulls({
          'paciente': _userName,
          'edad': userAge.isNotEmpty ? '$userAge años' : notSpec,
          'ubicacion': userLocation.isNotEmpty ? userLocation : notSpec,
          'fecha_generacion': fechaHoy,
          'rango_analizado': lastPeriod != null ? '$rangoInicio al $rangoFin' : notSpec,
          'total_ciclos': periodStarts.length,
          'anticonceptivos_medicamentos': medications.isNotEmpty ? medications.join(', ') : notSpec,
          'fum': fum,
        }),
        'seccion_2_resumen_estadistico': filterNulls({
          'promedio_ciclo': promCiclo != null ? {
            'valor': '${promCiclo.toStringAsFixed(0)} días',
            'referencia': '21 a 35 días',
            'estado': estadoCiclo,
          } : {'valor': notSpec, 'referencia': '21 a 35 días', 'estado': notSpec},
          'promedio_sangrado': {
            'valor': '${promSangrado.toInt()} días',
            'referencia': '3 a 6 días (máx. 7 días)',
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
          if ((patron['manchadoDias'] as String?)?.isNotEmpty == true)
            'manchado_dias': patron['manchadoDias'],
          'sintomas_relaciones_sexuales': patron['sintomasSexuales'],
        }),
        if (dolor.isNotEmpty) 'seccion_4_dolor_sintomatologia': filterNulls({
          'nivel_dolor_eva': dolor['nivelDolor'] != null ? '${(dolor['nivelDolor'] as num).toStringAsFixed(0)}/10' : null,
          'caracter': dolor['caracterDolor'],
          if ((dolor['diasDolor'] as String?)?.isNotEmpty == true)
            'dias_dolor_critico': dolor['diasDolor'],
          'tratamiento': dolor['tratamiento'],
          if ((dolor['sintomasFisicos'] as List?)?.isNotEmpty == true)
            'sintomas_fisicos': dolor['sintomasFisicos'],
          if ((dolor['sintomasEmocionales'] as List?)?.isNotEmpty == true)
            'sintomas_emocionales': dolor['sintomasEmocionales'],
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
            builder: (context) => MedicalReportPreviewScreen(reportData: report, filePath: file.path),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar informe: $e'), backgroundColor: Colors.red),
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
                    color: BellotaColors.textoDark,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  AppTranslations.get('profile_and_report', 'adjust_cycle', languageNotifier.currentLang),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: BellotaColors.textoMedio,
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
                        BellotaColors.melon.withValues(alpha: 0.15),
                        BellotaColors.chilero.withValues(alpha: 0.10),
                      ],
                    ),
                    border: Border.all(
                      color: BellotaColors.melon.withValues(alpha: 0.3),
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
                          color: BellotaColors.melon,
                        ),
                      ),
                      Text(
                        AppTranslations.get('profile_and_report', 'days', languageNotifier.currentLang),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: BellotaColors.textoMedio,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                // Slider
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: BellotaColors.melon,
                    inactiveTrackColor:
                        BellotaColors.melon.withValues(alpha: 0.15),
                    thumbColor: Colors.white,
                    overlayColor:
                        BellotaColors.melon.withValues(alpha: 0.15),
                    thumbShape: _CustomThumbShape(),
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
                              color: BellotaColors.textoMedio)),
                      Text('45 ${AppTranslations.get('profile_and_report', 'days', languageNotifier.currentLang)}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: BellotaColors.textoMedio)),
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
                      backgroundColor: BellotaColors.chilero,
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
                    color: BellotaColors.textoDark,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  AppTranslations.get('profile_and_report', 'adjust_period', languageNotifier.currentLang),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: BellotaColors.textoMedio,
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
                        BellotaColors.chilero.withValues(alpha: 0.15),
                        BellotaColors.melon.withValues(alpha: 0.10),
                      ],
                    ),
                    border: Border.all(
                      color: BellotaColors.chilero.withValues(alpha: 0.3),
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
                          color: BellotaColors.chilero,
                        ),
                      ),
                      Text(
                        tempValue == 1 ? AppTranslations.get('profile_and_report', 'day', languageNotifier.currentLang) : AppTranslations.get('profile_and_report', 'days', languageNotifier.currentLang),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: BellotaColors.textoMedio,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                // Slider
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: BellotaColors.chilero,
                    inactiveTrackColor:
                        BellotaColors.chilero.withValues(alpha: 0.15),
                    thumbColor: Colors.white,
                    overlayColor:
                        BellotaColors.chilero.withValues(alpha: 0.15),
                    thumbShape: _CustomThumbShape(),
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
                              color: BellotaColors.textoMedio)),
                      Text('10 ${AppTranslations.get('profile_and_report', 'days', languageNotifier.currentLang)}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: BellotaColors.textoMedio)),
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
                      backgroundColor: BellotaColors.chilero,
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
    return SingleChildScrollView(
      physics: ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            SizedBox(height: 12),
            // ── Header icons (top right) ──
            _buildTopIcons(),
            SizedBox(height: 8),
            // ── Avatar + Name + Email ──
            _buildAvatarSection(),
            SizedBox(height: 28),
            // ── Divider ──
            Container(
              height: 1,
              color: Color(0xFFE0D0C0).withValues(alpha: 0.5),
            ),
            SizedBox(height: 20),
            // ── Perfil de salud ──
            _buildHealthSection(),
            SizedBox(height: 28),
            // ── Divider ──
            Container(
              height: 1,
              color: Color(0xFFE0D0C0).withValues(alpha: 0.5),
            ),
            SizedBox(height: 20),
            // ── Preferencia de la aplicación ──
            _buildPreferencesSection(),
            
            if (_currentUser != null && (_currentUser!.isAdmin || _currentUser!.isAuditor)) ...[
              SizedBox(height: 28),
              Container(
                height: 1,
                color: Color(0xFFE0D0C0).withValues(alpha: 0.5),
              ),
              SizedBox(height: 20),
              _buildAdminSection(),
            ],

            SizedBox(height: 28),
            // ── Divider ──
            Container(
              height: 1,
              color: Colors.red.withValues(alpha: 0.15),
            ),
            SizedBox(height: 20),
            // ── Botón Cerrar Sesión ──
            _buildLogoutButton(),
            SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // ── Admin Section ─────────────────────────────────────────────────────────
  Widget _buildAdminSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Administración',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: BellotaColors.textoDark,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        if (_currentUser!.isAdmin)
          _buildHealthRow(
            title: 'Panel de Administrador',
            value: 'Gestionar usuarios',
            onTap: () {
              NavigationService.goTo(context, const AdminPanelScreen());
            },
          ),
        if (_currentUser!.isAdmin) SizedBox(height: 8),
        if (_currentUser!.isAdmin || _currentUser!.isAuditor)
          _buildHealthRow(
            title: 'Registro de Auditoría',
            value: 'Ver logs',
            onTap: () {
              NavigationService.goTo(context, const AuditDashboardScreen());
            },
          ),
      ],
    );
  }

  // ── Logout Button ─────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _handleLogout,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            SizedBox(width: 10),
            Text(
              AppTranslations.get('profile_and_report', 'logout', languageNotifier.currentLang),
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Icons (traducción + sonido) ──
  Widget _buildTopIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () {}, // Sin función
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.translate_rounded,
                size: 18, color: BellotaColors.textoDark),
          ),
        ),
        SizedBox(width: 10),
        GestureDetector(
          onTap: () {}, // Sin función
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BellotaColors.chilero,
              boxShadow: [
                BoxShadow(
                  color: BellotaColors.chilero.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child:
                Icon(Icons.volume_up_rounded, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ── Avatar circular + nombre + email ──
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
                    color: BellotaColors.melon.withValues(alpha: 0.4),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BellotaColors.melon.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _profileImagePath != null &&
                          File(_profileImagePath!).existsSync()
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
                    color: BellotaColors.chilero,
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
            color: BellotaColors.textoDark,
          ),
        ),
        SizedBox(height: 2),
        // Email
        Text(
          _userEmail,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: BellotaColors.textoMedio,
          ),
        ),
        if (_currentUser != null && _currentUser!.role != UserRole.usuario) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _currentUser!.isAdmin ? BellotaColors.chilero.withValues(alpha: 0.15) : BellotaColors.asuncion.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _currentUser!.isAdmin ? Icons.admin_panel_settings : Icons.manage_search,
                  size: 14,
                  color: _currentUser!.isAdmin ? BellotaColors.chilero : BellotaColors.asuncion,
                ),
                SizedBox(width: 4),
                Text(
                  RolePermissions.roleName(_currentUser!.role),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _currentUser!.isAdmin ? BellotaColors.chilero : BellotaColors.asuncion,
                  ),
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }

  // ── Perfil de salud ──
  Widget _buildHealthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + cat icon
        Row(
          children: [
            Expanded(
              child: Text(
                AppTranslations.get('profile_and_report', 'health_profile', languageNotifier.currentLang),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: BellotaColors.textoDark,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        // Duración del ciclo
        _buildHealthRow(
          title: AppTranslations.get('profile_and_report', 'cycle_duration', languageNotifier.currentLang),
          value: '$_cycleDuration ${AppTranslations.get('profile_and_report', 'days', languageNotifier.currentLang)}',
          onTap: _showCycleDurationPicker,
        ),
        SizedBox(height: 8),
        // Duración de la menstruación
        _buildHealthRow(
          title: AppTranslations.get('profile_and_report', 'period_duration', languageNotifier.currentLang),
          value: '$_periodDuration ${AppTranslations.get('profile_and_report', 'days', languageNotifier.currentLang)}',
          onTap: _showPeriodDurationPicker,
        ),
        SizedBox(height: 8),
        // Informe médico
        _buildHealthRow(
          title: AppTranslations.get('profile_and_report', 'medical_report', languageNotifier.currentLang),
          value: AppTranslations.get('profile_and_report', 'generate', languageNotifier.currentLang),
          onTap: _generateMedicalReport,
        ),
      ],
    );
  }

  Widget _buildHealthRow({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: BellotaColors.textoDark,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BellotaColors.melon,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: BellotaColors.melon.withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Preferencia de la aplicación ──
  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.get('profile_and_report', 'app_preferences', languageNotifier.currentLang),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BellotaColors.textoDark,
          ),
        ),
        SizedBox(height: 14),
        // Recordatorios y notificaciones
        _buildPreferenceRow(
          title: AppTranslations.get('profile_and_report', 'reminders_notifications', languageNotifier.currentLang),
          value: null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationsSettingsScreen(),
              ),
            );
          },
        ),
        SizedBox(height: 8),
        // Política de privacidad
        _buildPreferenceRow(
          title: AppTranslations.get('profile_and_report', 'privacy_policy', languageNotifier.currentLang),
          value: null,
          onTap: () {}, // Sin función
        ),
        SizedBox(height: 8),
        // Idioma
        _buildPreferenceRow(
          title: AppTranslations.get('profile_and_report', 'language', languageNotifier.currentLang),
          value: languageNotifier.currentLang == 'es' ? 'Español' : (languageNotifier.currentLang == 'mi' ? 'Miskito' : 'English'),
          onTap: () {}, // Sin función
        ),
        SizedBox(height: 8),
        // Apariencia — Toggle Modo Oscuro
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (_, mode, _) {
            final isDark = mode == ThemeMode.dark;
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.get('profile_and_report', 'appearance', languageNotifier.currentLang),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: BellotaColors.textoDark,
                          ),
                        ),
                        Text(
                          isDark ? AppTranslations.get('profile_and_report', 'dark_mode', languageNotifier.currentLang) : AppTranslations.get('profile_and_report', 'light_mode', languageNotifier.currentLang),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: BellotaColors.textoMedio,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        size: 18,
                        color: isDark ? Color(0xFF9B7FD4) : BellotaColors.melon,
                      ),
                      SizedBox(width: 8),
                      Switch(
                        value: isDark,
                        onChanged: (_) => themeNotifier.toggle(),
                        activeThumbColor: Color(0xFF9B7FD4),
                        activeTrackColor: Color(0xFF9B7FD4).withValues(alpha: 0.3),
                        inactiveThumbColor: BellotaColors.melon,
                        inactiveTrackColor: BellotaColors.melon.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPreferenceRow({
    required String title,
    String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: BellotaColors.textoDark,
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BellotaColors.melon,
                ),
              ),
            SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: BellotaColors.textoMedio.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Slider Thumb ──
class _CustomThumbShape extends SliderComponentShape {
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
        ..color = sliderTheme.activeTrackColor ?? BellotaColors.melon
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Inner dot
    canvas.drawCircle(
      center,
      5,
      Paint()..color = sliderTheme.activeTrackColor ?? BellotaColors.melon,
    );
  }
}

