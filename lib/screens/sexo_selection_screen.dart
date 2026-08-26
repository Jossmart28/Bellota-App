import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';

class SexoSelectionScreen extends StatefulWidget {
  final List<String> initialSelectedSexo;

  const SexoSelectionScreen({super.key, required this.initialSelectedSexo});

  @override
  State<SexoSelectionScreen> createState() => _SexoSelectionScreenState();
}

class _SexoSelectionScreenState extends State<SexoSelectionScreen> {
  late Set<String> _selectedSexo;

  final List<String> _sexoOptions = [
    'Sin anticoncepción',
    'Condón',
    'Sin eyacular',
    'Píldora de corta duración',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSexo = Set.from(widget.initialSelectedSexo);
  }

  void _toggleSexo(String option) {
    setState(() {
      if (_selectedSexo.contains(option)) {
        _selectedSexo.remove(option);
      } else {
        _selectedSexo.add(option);
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
        title: const Text('Sexo', style: TextStyle(color: BellotaColors.textoDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedSexo.toList());
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
                ..._sexoOptions.map((option) => _buildSexoRow(option)),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSexoRow(String option) {
    final isSelected = _selectedSexo.contains(option);
    return InkWell(
      onTap: () => _toggleSexo(option),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Bellota en vez de ícono genérico
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: BellotaColors.nancite,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🌰', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
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
