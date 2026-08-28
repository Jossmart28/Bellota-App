import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import '../database/database_helper.dart';
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
    _loadData();
  }

  String get _dateKey => '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  String get _formattedDate => '${_date.day} de ${_monthNames[_date.month - 1]} ${_date.year}';

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');

    if (_userId == null) {
      String userEmail = prefs.getString('userEmail') ?? '';
      if (userEmail.isNotEmpty) {
        _userId = await DatabaseHelper.instance.getUserIdByEmail(userEmail);
        if (_userId != null) {
          await prefs.setInt('userId', _userId!);
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
        });
      }
      final String? patronStr = prefs.getString('patron_sangrado_$_dateKey');
      if (patronStr != null) {
        setState(() {
          _patronSangrado = jsonDecode(patronStr);
        });
      }
      final String? dolorStr = prefs.getString('dolor_sintomatologia_$_dateKey');
      if (dolorStr != null) {
        setState(() {
          _dolorSintomatologia = jsonDecode(dolorStr);
        });
      }
    }
  }

  Future<void> _saveAndAccept() async {
    if (_userId != null) {
      await DatabaseHelper.instance.saveDailyLog(
        userId: _userId!,
        date: _dateKey,
        periodStart: iniciaPeriodo,
        symptoms: _selectedSymptoms,
        sexo: _selectedSexo,
        flujo: _selectedFlujos,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('patron_sangrado_$_dateKey', jsonEncode(_patronSangrado));
      await prefs.setString('dolor_sintomatologia_$_dateKey', jsonEncode(_dolorSintomatologia));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registro guardado para $_formattedDate'),
          backgroundColor: BellotaColors.chilero,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BellotaColors.basilica,
      appBar: _buildAppBar(context),
      body: ListView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildDateHeader(context),
          SizedBox(height: 20),
          _buildCard(
            context,
            icon: Icons.water_drop_outlined,
            iconColor: BellotaColors.chilero,
            title: 'Inicia el período',
            trailing: _buildSiNoToggle(
              value: iniciaPeriodo,
              onChanged: (val) => setState(() => iniciaPeriodo = val),
            ),
          ),
          SizedBox(height: 12),
          _buildCard(
            context,
            icon: Icons.favorite_border_rounded,
            iconColor: BellotaColors.melon,
            title: 'Sexo',
            subtitle: _selectedSexo.isNotEmpty ? _selectedSexo.join(', ') : null,
            trailing: _buildAddButton(hasItems: _selectedSexo.isNotEmpty),
            onTap: _openSexoSelection,
          ),
          SizedBox(height: 12),
          _buildCard(
            context,
            icon: Icons.medical_services_outlined,
            iconColor: BellotaColors.asuncion,
            title: 'Síntomas',
            subtitle: _selectedSymptoms.isNotEmpty ? _selectedSymptoms.join(', ') : null,
            trailing: _buildAddButton(hasItems: _selectedSymptoms.isNotEmpty),
            onTap: _openSymptomsSelection,
          ),
          SizedBox(height: 12),
          _buildCard(
            context,
            icon: Icons.opacity_rounded,
            iconColor: Color(0xFFA566C1),
            title: 'Flujo vaginal',
            subtitle: _selectedFlujos.isNotEmpty ? _selectedFlujos.join(', ') : null,
            trailing: _buildAddButton(hasItems: _selectedFlujos.isNotEmpty),
            onTap: _openFlujoSelection,
          ),
          SizedBox(height: 12),
          _buildCard(
            context,
            icon: Icons.bloodtype_outlined,
            iconColor: BellotaColors.chilero,
            title: 'Patrón de sangrado',
            subtitle: _patronSangrado.isNotEmpty ? 'Registrado ✓' : null,
            trailing: _buildAddButton(hasItems: _patronSangrado.isNotEmpty),
            onTap: _openPatronSangradoSelection,
          ),
          SizedBox(height: 12),
          _buildCard(
            context,
            icon: Icons.healing_outlined,
            iconColor: BellotaColors.chiltoma,
            title: 'Dolor y sintomatología',
            subtitle: _dolorSintomatologia.isNotEmpty ? 'Registrado ✓' : null,
            trailing: _buildAddButton(hasItems: _dolorSintomatologia.isNotEmpty),
            onTap: _openDolorSintomatologiaSelection,
          ),
          SizedBox(height: 32),
          _buildSaveButton(context),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // APP BAR
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: BellotaColors.basilica,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: BellotaColors.blanco,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: BellotaColors.melon.withValues(alpha: 0.10),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: BellotaColors.textoDark,
            size: 18,
          ),
        ),
      ),
      title: Text(
        'Registro',
        style: TextStyle(
          color: BellotaColors.textoDark,
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
                color: BellotaColors.chilero.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Guardar',
                style: TextStyle(
                  color: BellotaColors.chilero,
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
  Widget _buildDateHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: BellotaColors.chilero.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: BellotaColors.chilero,
          ),
        ),
        SizedBox(width: 10),
        Text(
          _formattedDate,
          style: TextStyle(
            color: BellotaColors.textoMedio,
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
                  BellotaColors.textoMedio.withValues(alpha: 0.20),
                  BellotaColors.textoMedio.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // CARD POR ÍTEM
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
          color: BellotaColors.blanco,
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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: iconColor, size: 22),
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
                      color: BellotaColors.textoDark,
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
                        color: BellotaColors.textoMedio.withValues(alpha: 0.85),
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

  // TOGGLE SÍ / NO
  Widget _buildSiNoToggle({required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      decoration: BoxDecoration(
        color: BellotaColors.nancite,
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
                color: value ? BellotaColors.chilero : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: value
                    ? [BoxShadow(color: BellotaColors.chilero.withValues(alpha: 0.25), blurRadius: 8, offset: Offset(0, 2))]
                    : [],
              ),
              child: Text(
                'Sí',
                style: TextStyle(
                  color: value ? Colors.white : BellotaColors.textoMedio,
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
                color: !value ? BellotaColors.chilero : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: !value
                    ? [BoxShadow(color: BellotaColors.chilero.withValues(alpha: 0.25), blurRadius: 8, offset: Offset(0, 2))]
                    : [],
              ),
              child: Text(
                'No',
                style: TextStyle(
                  color: !value ? Colors.white : BellotaColors.textoMedio,
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

  // BOTÓN AÑADIR
  Widget _buildAddButton({bool hasItems = false}) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: hasItems ? BellotaColors.chilero.withValues(alpha: 0.12) : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: BellotaColors.chilero.withValues(alpha: hasItems ? 0.0 : 0.6),
          width: 1.5,
        ),
      ),
      child: Icon(
        hasItems ? Icons.edit_outlined : Icons.add_rounded,
        color: BellotaColors.chilero,
        size: 18,
      ),
    );
  }

  // BOTÓN GUARDAR
  Widget _buildSaveButton(BuildContext context) {
    return GestureDetector(
      onTap: _saveAndAccept,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: BellotaColors.buttonGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: BellotaColors.chilero.withValues(alpha: 0.30),
              blurRadius: 16,
              spreadRadius: 0,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Guardar registro',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
