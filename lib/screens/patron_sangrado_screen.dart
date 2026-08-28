import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';

class PatronSangradoScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const PatronSangradoScreen({super.key, required this.initialData});

  @override
  State<PatronSangradoScreen> createState() => _PatronSangradoScreenState();
}

class _PatronSangradoScreenState extends State<PatronSangradoScreen> {
  late String _intensidadFlujo;
  late String _coagulos;
  late String _manchado;
  late TextEditingController _manchadoDiasController;
  late String _sintomasSexuales;

  @override
  void initState() {
    super.initState();
    _intensidadFlujo = widget.initialData['intensidadFlujo'] ?? 'Moderado 3-5';
    _coagulos = widget.initialData['coagulos'] ?? 'Nunca';
    _manchado = widget.initialData['manchado'] ?? 'No';
    _manchadoDiasController = TextEditingController(text: widget.initialData['manchadoDias'] ?? '');
    _sintomasSexuales = widget.initialData['sintomasSexuales'] ?? 'Ninguno';
  }

  @override
  void dispose() {
    _manchadoDiasController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(context, {
      'intensidadFlujo': _intensidadFlujo,
      'coagulos': _coagulos,
      'manchado': _manchado,
      'manchadoDias': _manchadoDiasController.text.trim(),
      'sintomasSexuales': _sintomasSexuales,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BellotaColors.basilica,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: BellotaColors.textoDark, fontSize: 16)),
        ),
        leadingWidth: 80,
        title: Text('Patrón de Sangrado', style: TextStyle(color: BellotaColors.textoDark, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Confirmar', style: TextStyle(color: BellotaColors.chilero, fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Intensidad del flujo'),
                SizedBox(height: 8),
                _buildSingleChoiceChips(
                  options: ['Leve <3', 'Moderado 3-5', 'Abundante >5'],
                  selected: _intensidadFlujo,
                  onSelected: (val) => setState(() => _intensidadFlujo = val),
                ),
                SizedBox(height: 24),

                _buildLabel('Coágulos'),
                SizedBox(height: 8),
                _buildSingleChoiceChips(
                  options: ['Nunca', 'Ocasional', 'Frecuente'],
                  selected: _coagulos,
                  onSelected: (val) => setState(() => _coagulos = val),
                ),
                SizedBox(height: 24),

                _buildLabel('Manchado intermenstrual'),
                SizedBox(height: 8),
                _buildSingleChoiceChips(
                  options: ['No', 'Sí'],
                  selected: _manchado,
                  onSelected: (val) => setState(() => _manchado = val),
                ),
                if (_manchado == 'Sí') ...[
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _manchadoDiasController,
                    decoration: InputDecoration(
                      hintText: 'Días del ciclo (Ej. 14, 15)',
                      filled: true,
                      fillColor: BellotaColors.basilica,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
                SizedBox(height: 24),

                _buildLabel('Síntomas en relaciones sexuales'),
                SizedBox(height: 8),
                _buildSingleChoiceChips(
                  options: ['Dolor', 'Sangrado', 'Flujo inusual', 'Ninguno'],
                  selected: _sintomasSexuales,
                  onSelected: (val) => setState(() => _sintomasSexuales = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(color: BellotaColors.textoDark, fontSize: 15, fontWeight: FontWeight.bold));
  }

  Widget _buildSingleChoiceChips({required List<String> options, required String selected, required Function(String) onSelected}) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return ChoiceChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (_) => onSelected(opt),
          selectedColor: BellotaColors.chilero,
          backgroundColor: BellotaColors.basilica,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : BellotaColors.textoDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
