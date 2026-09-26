import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';
import '../core/data/hospital_repository.dart';
import '../core/models/health_center_model.dart';
import 'health_center_detail_screen.dart';

class AllHospitalsScreen extends StatefulWidget {
  const AllHospitalsScreen({super.key});

  @override
  State<AllHospitalsScreen> createState() => _AllHospitalsScreenState();
}

class _AllHospitalsScreenState extends State<AllHospitalsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final HospitalRepository _repository = HospitalRepository();
  List<HealthCenter> _hospitals = [];

  @override
  void initState() {
    super.initState();
    _hospitals = _repository.getAll();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _hospitals = _repository.search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).bellotaColors;

    return Scaffold(
      backgroundColor: colors.basilica,
      appBar: AppBar(
        backgroundColor: colors.blanco,
        elevation: 0,
        title: Text(
          'Hospitales',
          style: TextStyle(color: colors.textoDark, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: colors.textoDark),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: colors.basilica,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar centro de salud...',
                  prefixIcon: Icon(Icons.search, color: colors.textoMedio),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _hospitals.length,
        itemBuilder: (context, index) {
          final hospital = _hospitals[index];
          return Card(
            elevation: 0,
            color: colors.blanco,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.melon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_hospital_rounded, color: colors.melon),
              ),
              title: Text(
                hospital.name,
                style: TextStyle(fontWeight: FontWeight.bold, color: colors.textoDark),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${hospital.municipality}, ${hospital.department}',
                  style: TextStyle(color: colors.textoMedio, fontSize: 12),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HealthCenterDetailScreen(center: hospital)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
