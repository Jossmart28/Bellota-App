import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';
import 'package:bellotadevelopment/core/data/hospital_repository.dart';
import 'package:bellotadevelopment/core/services/recommendation_engine.dart';
import 'package:bellotadevelopment/core/services/user_health_profile.dart';
import 'package:bellotadevelopment/core/services/clinical_analysis_service.dart';
import 'package:bellotadevelopment/core/models/hospital_recommendation.dart';
import 'package:bellotadevelopment/core/models/health_center_model.dart';
import 'package:bellotadevelopment/presentation/common/recommended_hospital_card.dart';
import 'package:bellotadevelopment/presentation/screens/hospitals/health_center_detail_screen.dart';
import 'package:bellotadevelopment/presentation/screens/hospitals/all_hospitals_screen.dart';
import 'package:bellotadevelopment/presentation/common/map_carousel_widget.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';

class HospitalHubScreen extends StatefulWidget {
  final List<ClinicalAlert>? activeAlerts;
  const HospitalHubScreen({super.key, this.activeAlerts});

  @override
  State<HospitalHubScreen> createState() => _HospitalHubScreenState();
}

class _HospitalHubScreenState extends State<HospitalHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  final HospitalRepository _repository = HospitalRepository();
  final RecommendationEngine _engine = RecommendationEngine();
  
  LatLng? _userLocation;
  List<HospitalRecommendation> _recommended = [];
  bool _isLoading = true;
  int _matchingSymptomsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('user_latitude');
    final lng = prefs.getDouble('user_longitude');

    if (lat != null && lng != null) {
      _userLocation = LatLng(lat, lng);
    }
    
    // Obtener perfil completo de salud
    final healthData = await UserHealthProfileService.instance.getConsolidatedHealthData();
    List<String> userSymptoms = [];
    List<String> userConditions = [];
    List<ClinicalAlert> activeAlerts = [];
    
    if (healthData != null) {
      userSymptoms = healthData.recentSymptoms;
      userConditions = healthData.medicalConditions;
      _matchingSymptomsCount = userSymptoms.length;
      activeAlerts = widget.activeAlerts ?? await ClinicalAnalysisService.instance.analyzeHealthState(healthData.userId);
    }

    final allHospitals = _repository.getAll();

    if (mounted) {
      setState(() {
        _recommended = _engine.recommend(
          userLocation: _userLocation,
          userSymptoms: userSymptoms,
          userMedicalConditions: userConditions,
          hospitals: allHospitals,
          activeAlerts: activeAlerts,
        );
        _isLoading = false;
      });
    }
  }

  void _navigateToDetail(HealthCenter center) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HealthCenterDetailScreen(center: center)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).bellotaColors;

    return Scaffold(
      backgroundColor: colors.basilica,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BellotaColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colors.basilica,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: colors.blanco,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search, color: colors.textoMedio, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                readOnly: true,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AllHospitalsScreen()));
                },
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.hospitalHubSearchHint,
                  hintStyle: TextStyle(color: colors.textoMedio.withOpacity(0.6)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BellotaColors colors) {
    return ListView(
      padding: const EdgeInsets.only(top: 10, bottom: 30),
      children: [
        // ── Map embedded at the top ──────────────────────────────────
        MapCarouselWidget(userLocation: _userLocation),

        // ── Recomendados para ti ─────────────────────────────────────
        if (_recommended.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: colors.melon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.hospitalHubRecommended,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textoDark),
                      ),
                      if (_matchingSymptomsCount > 0)
                        Text(
                          AppLocalizations.of(context)!.hospitalHubRecommendedSub,
                          style: TextStyle(fontSize: 12, color: colors.textoMedio),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideX(),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _recommended.length,
              itemBuilder: (context, index) {
                return RecommendedHospitalCard(
                  recommendation: _recommended[index],
                  onTap: () => _navigateToDetail(_recommended[index].hospital),
                ).animate().fadeIn(delay: (index * 100).ms).slideX();
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── View All Action Button ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildActionButton(
            context: context,
            title: AppLocalizations.of(context)!.hospitalHubViewAll,
            icon: Icons.list_rounded,
            color: colors.asuncion,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllHospitalsScreen())),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).bellotaColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.blanco,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textoDark,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: colors.textoMedio, size: 14),
          ],
        ),
      ),
    );
  }
}
