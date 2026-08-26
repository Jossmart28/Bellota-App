   import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import 'notifications_settings_screen.dart';
import '../database/database_helper.dart';

/// Pantalla de Perfil de usuario — Bellota App
/// Diseño fiel al mockup de referencia con paleta de colores Bellota.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'UsuarioApp';
  String _userEmail = 'correo@ejemplo.com';
  String _gmail = '';
  int _cycleDuration = 28;
  int _periodDuration = 7;
  String? _profileImagePath;
  int? _userId;

  final TextEditingController _gmailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail') ?? 'correo@ejemplo.com';
    
    final userId = await DatabaseHelper.instance.getUserIdByEmail(email);
    if (userId != null) {
      final profile = await DatabaseHelper.instance.getProfile(userId);
      if (profile != null) {
        setState(() {
          _userId = userId;
          _userName = profile['username'] ?? prefs.getString('userName') ?? 'UsuarioApp';
          _userEmail = email;
          _gmail = profile['gmail'] ?? '';
          _gmailController.text = _gmail;
          _cycleDuration = profile['cycle_duration'] ?? 28;
          _periodDuration = profile['period_duration'] ?? 7;
          _profileImagePath = profile['profile_image_path'] ?? prefs.getString('profileImagePath');
        });
        return;
      }
    }
    
    // Fallback
    setState(() {
      _userEmail = email;
      _userName = prefs.getString('userName') ?? 'UsuarioApp';
      _cycleDuration = prefs.getInt('cycleDuration') ?? 28;
      _periodDuration = prefs.getInt('periodDuration') ?? 7;
      _profileImagePath = prefs.getString('profileImagePath');
    });
  }

  Future<void> _saveGmail(String val) async {
    if (_userId != null) {
      await DatabaseHelper.instance.updateProfileField(_userId!, 'gmail', val.trim());
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4C4B0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cambiar foto de perfil',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: BellotaColors.textoDark,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: BellotaColors.melon.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: BellotaColors.melon),
                ),
                title: Text('Galería',
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
                  child: const Icon(Icons.camera_alt_outlined,
                      color: BellotaColors.chilero),
                ),
                title: Text('Cámara',
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
                        const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: Text('Eliminar foto',
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

  void _showCycleDurationPicker() {
    int tempValue = _cycleDuration;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4C4B0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Duración del ciclo',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: BellotaColors.textoDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajusta la duración promedio de tu ciclo menstrual',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: BellotaColors.textoMedio,
                  ),
                ),
                const SizedBox(height: 30),
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
                        'días',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: BellotaColors.textoMedio,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: tempValue.toDouble(),
                    min: 20,
                    max: 45,
                    divisions: 25,
                    label: '$tempValue días',
                    onChanged: (val) {
                      setModalState(() => tempValue = val.round());
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('20 días',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: BellotaColors.textoMedio)),
                      Text('45 días',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: BellotaColors.textoMedio)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
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
                      'Guardar',
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4C4B0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Duración de la menstruación',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: BellotaColors.textoDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajusta cuántos días dura tu menstruación',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: BellotaColors.textoMedio,
                  ),
                ),
                const SizedBox(height: 30),
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
                        'días',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: BellotaColors.textoMedio,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: tempValue.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$tempValue días',
                    onChanged: (val) {
                      setModalState(() => tempValue = val.round());
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 día',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: BellotaColors.textoMedio)),
                      Text('10 días',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: BellotaColors.textoMedio)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
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
                      'Guardar',
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
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // ── Header icons (top right) ──
            _buildTopIcons(),
            const SizedBox(height: 8),
            // ── Avatar + Name + Email ──
            _buildAvatarSection(),
            const SizedBox(height: 28),
            // ── Divider ──
            Container(
              height: 1,
              color: const Color(0xFFE0D0C0).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            // ── Perfil de salud ──
            _buildHealthSection(),
            const SizedBox(height: 28),
            // ── Divider ──
            Container(
              height: 1,
              color: const Color(0xFFE0D0C0).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            // ── Preferencia de la aplicación ──
            _buildPreferencesSection(),
            const SizedBox(height: 30),
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
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.translate_rounded,
                size: 18, color: BellotaColors.textoDark),
          ),
        ),
        const SizedBox(width: 10),
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
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                const Icon(Icons.volume_up_rounded, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ── Avatar circular + nombre + email ──
  Widget _buildAvatarSection() {
    return Column(
      children: [
        // Avatar
        GestureDetector(
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
                      offset: const Offset(0, 4),
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
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Username
        Text(
          _userName,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: BellotaColors.textoDark,
          ),
        ),
        const SizedBox(height: 2),
        // Email
        Text(
          _userEmail,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: BellotaColors.textoMedio,
          ),
        ),
        const SizedBox(height: 12),
        // Gmail Field
        SizedBox(
          width: 250,
          child: TextField(
            controller: _gmailController,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: BellotaColors.textoDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Añadir cuenta de Gmail',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: BellotaColors.textoMedio.withValues(alpha: 0.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: BellotaColors.melon, width: 1.5),
              ),
            ),
            onChanged: (val) => _gmail = val,
            onSubmitted: (val) => _saveGmail(val),
          ),
        ),
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
                'Perfil de salud',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: BellotaColors.textoDark,
                ),
              ),
            ),
            // Pixel art cat lying down (yellow/orange)
            SizedBox(
              width: 60,
              height: 40,
              child: CustomPaint(
                painter: _PixelCatPainter(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Duración del ciclo
        _buildHealthRow(
          title: 'Duración del ciclo',
          value: '$_cycleDuration días',
          onTap: _showCycleDurationPicker,
        ),
        const SizedBox(height: 8),
        // Duración de la menstruación
        _buildHealthRow(
          title: 'Duración de la menstruación',
          value: '$_periodDuration días',
          onTap: _showPeriodDurationPicker,
        ),
        const SizedBox(height: 8),
        // Informe médico
        _buildHealthRow(
          title: 'Informe medico',
          value: 'Generar',
          onTap: () {}, // Sin función
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
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
            const SizedBox(width: 4),
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
          'Preferencia de la aplicación',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BellotaColors.textoDark,
          ),
        ),
        const SizedBox(height: 14),
        // Recordatorios y notificaciones
        _buildPreferenceRow(
          title: 'Recordatorios y notificaciones',
          value: null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsSettingsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Política de privacidad
        _buildPreferenceRow(
          title: 'Política de privacidad',
          value: null,
          onTap: () {}, // Sin función
        ),
        const SizedBox(height: 8),
        // Idioma
        _buildPreferenceRow(
          title: 'Idioma',
          value: 'Español',
          onTap: () {}, // Sin función
        ),
        const SizedBox(height: 8),
        // Apariencia
        _buildPreferenceRow(
          title: 'Apariencia',
          value: 'Claro',
          onTap: () {}, // Sin función
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
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
            const SizedBox(width: 4),
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
      const Size(24, 24);

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
      center + const Offset(0, 1),
      13,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
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

// ── Pixel Art Cat Painter (lying yellow/orange cat) ──
class _PixelCatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double px = size.width / 16; // pixel size

    // Colors
    final orangeDark = Paint()..color = const Color(0xFFD4882C);
    final orangeLight = Paint()..color = const Color(0xFFE8A845);
    final orangeMid = Paint()..color = const Color(0xFFDB9535);
    final cream = Paint()..color = const Color(0xFFF5D89A);
    final dark = Paint()..color = const Color(0xFF6B4226);
    final nose = Paint()..color = const Color(0xFFDB6B5E);
    final white = Paint()..color = const Color(0xFFFFF8E7);

    void px2(Paint p, double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x * px, y * px, px, px), p);
    }

    // Ears (row 0-1)
    px2(orangeDark, 2, 0);
    px2(orangeDark, 3, 0);
    px2(orangeDark, 11, 0);
    px2(orangeDark, 12, 0);

    px2(orangeDark, 1, 1);
    px2(orangeLight, 2, 1);
    px2(orangeLight, 3, 1);
    px2(orangeDark, 4, 1);
    px2(orangeDark, 10, 1);
    px2(orangeLight, 11, 1);
    px2(orangeLight, 12, 1);
    px2(orangeDark, 13, 1);

    // Head top (row 2)
    px2(orangeDark, 1, 2);
    px2(cream, 2, 2);
    px2(orangeLight, 3, 2);
    px2(orangeDark, 4, 2);
    px2(orangeMid, 5, 2);
    px2(orangeMid, 6, 2);
    px2(orangeMid, 7, 2);
    px2(orangeMid, 8, 2);
    px2(orangeMid, 9, 2);
    px2(orangeDark, 10, 2);
    px2(orangeLight, 11, 2);
    px2(cream, 12, 2);
    px2(orangeDark, 13, 2);

    // Eyes row (row 3)
    px2(orangeMid, 2, 3);
    px2(orangeLight, 3, 3);
    px2(dark, 4, 3); // left eye
    px2(orangeLight, 5, 3);
    px2(cream, 6, 3);
    px2(cream, 7, 3);
    px2(cream, 8, 3);
    px2(orangeLight, 9, 3);
    px2(dark, 10, 3); // right eye
    px2(orangeLight, 11, 3);
    px2(orangeMid, 12, 3);

    // Nose/mouth row (row 4)
    px2(orangeMid, 2, 4);
    px2(orangeLight, 3, 4);
    px2(cream, 4, 4);
    px2(cream, 5, 4);
    px2(cream, 6, 4);
    px2(nose, 7, 4); // nose
    px2(cream, 8, 4);
    px2(cream, 9, 4);
    px2(cream, 10, 4);
    px2(orangeLight, 11, 4);
    px2(orangeMid, 12, 4);

    // Chin (row 5)
    px2(orangeMid, 3, 5);
    px2(orangeLight, 4, 5);
    px2(cream, 5, 5);
    px2(white, 6, 5);
    px2(white, 7, 5);
    px2(white, 8, 5);
    px2(cream, 9, 5);
    px2(orangeLight, 10, 5);
    px2(orangeMid, 11, 5);

    // Body (rows 6-8) — lying down
    for (int x = 1; x <= 14; x++) {
      px2(orangeLight, x.toDouble(), 6);
    }
    for (int x = 0; x <= 15; x++) {
      px2(x % 2 == 0 ? orangeMid : orangeLight, x.toDouble(), 7);
    }

    // Paws + tail (row 8)
    px2(cream, 0, 8);
    px2(cream, 1, 8);
    px2(orangeMid, 2, 8);
    px2(orangeLight, 3, 8);
    px2(orangeLight, 4, 8);
    px2(orangeLight, 5, 8);
    px2(orangeLight, 6, 8);
    px2(orangeLight, 7, 8);
    px2(orangeLight, 8, 8);
    px2(orangeLight, 9, 8);
    px2(orangeLight, 10, 8);
    px2(orangeMid, 11, 8);
    px2(cream, 12, 8);
    px2(cream, 13, 8);
    // tail
    px2(orangeDark, 14, 8);
    px2(orangeDark, 15, 8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
