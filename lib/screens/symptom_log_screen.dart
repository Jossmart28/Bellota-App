import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import '../database/database_helper.dart';
import 'symptoms_selection_screen.dart';
import 'flujo_vaginal_selection_screen.dart';
import 'sexo_selection_screen.dart';

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
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registro guardado para $_formattedDate'),
          backgroundColor: BellotaColors.chilero,
        ),
      );
      Navigator.pop(context, true); // true indica que se guardó
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: BellotaColors.textoDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Registro - $_formattedDate',
          style: const TextStyle(color: BellotaColors.textoDark, fontSize: 16),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: BellotaColors.textoDark),
        actions: [
          // Botón Aceptar
          TextButton(
            onPressed: _saveAndAccept,
            child: const Text(
              'Aceptar',
              style: TextStyle(
                color: BellotaColors.chilero,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // 1. Inicia el período
          _buildListItem(
            icon: Icons.water_drop,
            iconColor: BellotaColors.chilero,
            title: 'Inicia el período',
            trailing: _buildSiNoToggle(
              value: iniciaPeriodo,
              onChanged: (val) {
                setState(() => iniciaPeriodo = val);
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // 2. Sexo
          _buildListItem(
            icon: Icons.favorite,
            iconColor: BellotaColors.melon,
            title: 'Sexo',
            subtitle: _selectedSexo.isNotEmpty ? _selectedSexo.join(', ') : null,
            trailing: _buildPlusButton(),
            onTap: _openSexoSelection,
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // 3. Síntomas
          _buildListItem(
            icon: Icons.medical_services,
            iconColor: BellotaColors.asuncion,
            title: 'Síntomas',
            subtitle: _selectedSymptoms.isNotEmpty ? _selectedSymptoms.join(', ') : null,
            trailing: _buildPlusButton(),
            onTap: _openSymptomsSelection,
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // 4. Flujo vaginal
          _buildListItem(
            icon: Icons.opacity,
            iconColor: const Color(0xFFA566C1),
            title: 'Flujo vaginal',
            subtitle: _selectedFlujos.isNotEmpty ? _selectedFlujos.join(', ') : null,
            trailing: _buildPlusButton(),
            onTap: _openFlujoSelection,
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      color: BellotaColors.textoDark,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: BellotaColors.textoMedio.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSiNoToggle({required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => onChanged(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: value ? BellotaColors.chilero : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Text(
                'Sí',
                style: TextStyle(
                  color: value ? Colors.white : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: !value ? BellotaColors.chilero : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                'No',
                style: TextStyle(
                  color: !value ? Colors.white : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlusButton() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: BellotaColors.chilero, width: 1.5),
      ),
      child: const Icon(
        Icons.add,
        color: BellotaColors.chilero,
        size: 20,
      ),
    );
  }
}
