import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';

class FlujoVaginalSelectionScreen extends StatefulWidget {
  final List<String> initialSelectedFlujos;

  const FlujoVaginalSelectionScreen({super.key, required this.initialSelectedFlujos});

  @override
  State<FlujoVaginalSelectionScreen> createState() => _FlujoVaginalSelectionScreenState();
}

class _FlujoVaginalSelectionScreenState extends State<FlujoVaginalSelectionScreen> {
  late Set<String> _selectedFlujos;

  final List<String> _flujoOptions = [
    'Seco',
    'Espeso',
    'Líquido y elástico',
    'Acuoso',
    'Clara de huevo',
  ];

  @override
  void initState() {
    super.initState();
    _selectedFlujos = Set.from(widget.initialSelectedFlujos);
  }

  void _toggleFlujo(String flujo) {
    setState(() {
      if (_selectedFlujos.contains(flujo)) {
        _selectedFlujos.remove(flujo);
      } else {
        _selectedFlujos.add(flujo);
      }
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
          child: const Text('Cancelar', style: TextStyle(color: BellotaColors.textoDark, fontSize: 16)),
        ),
        leadingWidth: 80,
        title: const Text('Flujo vaginal', style: TextStyle(color: BellotaColors.textoDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedFlujos.toList());
            },
            child: const Text('Confirmar', style: TextStyle(color: BellotaColors.chilero, fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                ..._flujoOptions.map((flujo) => _buildFlujoRow(flujo)),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlujoRow(String flujo) {
    final isSelected = _selectedFlujos.contains(flujo);
    return InkWell(
      onTap: () => _toggleFlujo(flujo),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Bellota en vez de ícono original
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BellotaColors.nancite,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🌰', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                flujo,
                style: const TextStyle(
                  fontSize: 16,
                  color: BellotaColors.textoDark,
                ),
              ),
            ),
            // Círculo seleccionable
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? BellotaColors.chilero : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? BellotaColors.chilero : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
