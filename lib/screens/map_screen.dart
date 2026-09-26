import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import '../widgets/bellota_top_actions.dart';
import '../widgets/bellota_icon.dart';
import 'health_center_detail_screen.dart';
import '../core/models/health_center_model.dart';
import '../core/data/hospital_repository.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final HospitalRepository _repository = HospitalRepository();
  bool _isListVisible = true;
  LatLng? _userLocation;

  List<HealthCenter> _healthCenters = [];

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _healthCenters = _repository.getAll();
    _searchController.addListener(_onSearchChanged);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('user_latitude');
    final lng = prefs.getDouble('user_longitude');

    if (mounted) {
      setState(() {
        if (lat != null && lng != null) {
          _userLocation = LatLng(lat, lng);
        }
      });
      // Mover el mapa a la ubicación del usuario si el mapa ya está listo
      try {
        if (_userLocation != null) {
          _mapController.move(_userLocation!, 13.0);
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Centros que se muestran en el mapa: SIEMPRE todos (sin filtro de ubicación).
  /// Solo aplica el filtro de texto de búsqueda si el usuario escribió algo.
  List<HealthCenter> get _mapCenters {
    return _repository.search(_searchController.text);
  }

  /// Centros que se muestran en la lista lateral.
  List<HealthCenter> get _filteredCenters {
    return _repository.search(_searchController.text);
  }

  void _onMarkerTap(HealthCenter center) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HealthCenterDetailScreen(center: center),
      ),
    );
  }

  void _onCardTap(HealthCenter center) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HealthCenterDetailScreen(center: center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    flex: _isListVisible ? 0 : 1,
                    child: _isListVisible
                        ? SizedBox(height: 300, child: _buildMap())
                        : _buildMap(),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isListVisible = !_isListVisible),
                    child: Container(
                      width: double.infinity,
                      color: Theme.of(context).bellotaColors.blanco,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Theme.of(context).bellotaColors.textoMedio.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isListVisible)
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredCenters.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildHealthCenterCard(context, _filteredCenters[index]),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BARRA DE BÚSQUEDA Y BOTONES GLOBALES
  Widget _buildSearchBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).bellotaColors.basilica,
      child: Row(
        children: [
          // Botón Atrás
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Theme.of(context).bellotaColors.blanco,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back_rounded, color: Theme.of(context).bellotaColors.textoDark, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          // Campo de búsqueda
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).bellotaColors.blanco,
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
                  Icon(Icons.search, color: Theme.of(context).bellotaColors.textoMedio, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).bellotaColors.textoDark),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.hospitalHubSearchHint,
                        hintStyle: textTheme.bodyMedium?.copyWith(color: Theme.of(context).bellotaColors.textoMedio.withOpacity(0.6)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        filled: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          BellotaTopActions(
            showSettings: false, 
            onTalkBackPressed: () {},
          ),
        ],
      ),
    );
  }

  // MAPA FLUTTER MAP
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(12.1250, -86.2500),
        initialZoom: 13.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.bellota.app',
        ),
        MarkerLayer(
          markers: [
            ..._mapCenters.asMap().entries.map((entry) {
              final index = entry.key;
              final center = entry.value;
              final colors = [
                Theme.of(context).bellotaColors.chilero,
                Theme.of(context).bellotaColors.melon,
                const Color(0xFF4CAF50),
                const Color(0xFF2196F3),
                const Color(0xFF9C27B0),
                const Color(0xFFFFB300),
                const Color(0xFF00BCD4),
                const Color(0xFFE91E63),
              ];
              final color = colors[index % colors.length];

              return Marker(
                point: center.location,
                width: 20,
                height: 20,
                child: GestureDetector(
                  onTap: () => _onMarkerTap(center),
                  child: BellotaIcon(
                    color: color,
                    size: 20,
                  ),
                ),
              );
            }),
            
            if (_userLocation != null)
              Marker(
                point: _userLocation!,
                width: 80,
                height: 65,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).bellotaColors.textoDark,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Ubicación',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(Icons.location_pin, color: Theme.of(context).bellotaColors.textoDark, size: 32),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  // LISTA DE CENTROS DE SALUD
  Widget _buildHealthCenterCard(BuildContext context, HealthCenter center) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => _onCardTap(center),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).bellotaColors.blanco,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                    center.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).bellotaColors.textoDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _cardBullet(context, center.type),
                  _cardBullet(context, center.address),
                  _cardBullet(context, '${center.municipality}, ${center.department}.'),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).bellotaColors.melon,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).bellotaColors.melon.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: Theme.of(context).bellotaColors.blanco,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardBullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).bellotaColors.textoMedio,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
