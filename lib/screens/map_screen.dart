import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../theme/bellota_colors.dart';
import 'health_center_detail_screen.dart';

/// Modelo de datos para un centro de salud
class HealthCenter {
  final String id;
  final String name;
  final String type;
  final String address;
  final String schedule;
  final String city;
  final String department;
  final List<String> specialties;
  final LatLng location;

  const HealthCenter({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.schedule,
    required this.city,
    required this.department,
    required this.specialties,
    required this.location,
  });
}

/// Pantalla de mapa con centros de salud marcados con bellotas
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isListVisible = true;

  // ── Centros de salud de ejemplo (lorem ipsum) ──
  final List<HealthCenter> _healthCenters = [
    HealthCenter(
      id: '1',
      name: 'Centro de Salud Sócrates Flores',
      type: 'Centro de Salud',
      address: 'Mercado Oriental 2 cuadras al Norte.',
      schedule: '8:00 a.m. a 5:30 p.m.',
      city: 'Managua',
      department: 'Managua',
      specialties: ['Consulta Ginecológica', 'Planificación Familiar', 'Consulta General'],
      location: LatLng(12.1364, -86.2514),
    ),
    HealthCenter(
      id: '2',
      name: 'Centro de Salud Pedro Altamirano',
      type: 'Centro de Salud',
      address: 'Lorem ipsum dolor sit amet, consectetur.',
      schedule: '7:00 a.m. a 4:00 p.m.',
      city: 'Managua',
      department: 'Managua',
      specialties: ['Consulta General', 'Pediatría', 'Planificación Familiar'],
      location: LatLng(12.1190, -86.2680),
    ),
    HealthCenter(
      id: '3',
      name: 'Centro de Salud Villa Libertad',
      type: 'Centro de Salud',
      address: 'Adipiscing elit sed do eiusmod tempor.',
      schedule: '8:00 a.m. a 5:00 p.m.',
      city: 'Managua',
      department: 'Managua',
      specialties: ['Consulta Ginecológica', 'Consulta General'],
      location: LatLng(12.1080, -86.2250),
    ),
    HealthCenter(
      id: '4',
      name: 'Centro de Salud Francisco Buitrago',
      type: 'Centro de Salud',
      address: 'Ut enim ad minim veniam, quis nostrud.',
      schedule: '7:30 a.m. a 3:30 p.m.',
      city: 'Managua',
      department: 'Managua',
      specialties: ['Planificación Familiar', 'Consulta Ginecológica'],
      location: LatLng(12.1450, -86.2750),
    ),
    HealthCenter(
      id: '5',
      name: 'Centro de Salud Edgar Lang',
      type: 'Centro de Salud',
      address: 'Duis aute irure dolor in reprehenderit.',
      schedule: '8:00 a.m. a 5:30 p.m.',
      city: 'Managua',
      department: 'Managua',
      specialties: ['Consulta General', 'Consulta Ginecológica', 'Pediatría'],
      location: LatLng(12.1250, -86.2400),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HealthCenter> get _filteredCenters {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _healthCenters;
    return _healthCenters.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.specialties.any((s) => s.toLowerCase().contains(query)) ||
          c.address.toLowerCase().contains(query);
    }).toList();
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
    return Column(
      children: [
        // ══════════════════════════════════════
        // BARRA SUPERIOR — Búsqueda + íconos
        // ══════════════════════════════════════
        _buildSearchBar(),
        // ══════════════════════════════════════
        // MAPA + LISTA (scrollable)
        // ══════════════════════════════════════
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
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4C4B0),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                ),
              ),
              if (_isListVisible)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildHealthCenterList(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────
  // BARRA DE BÚSQUEDA
  // ────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF5EDE3),
      child: Row(
        children: [
          // Campo de búsqueda
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search, color: BellotaColors.textoMedio, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: BellotaColors.textoDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar centro de salud...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: BellotaColors.textoMedio.withValues(alpha: 0.6),
                        ),
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
          // Botón de traducción
          _iconButton(
            child: Text(
              '文A',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: BellotaColors.textoDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botón de audio/accesibilidad
          _iconButton(
            child: Icon(Icons.volume_up_rounded, color: BellotaColors.textoDark, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({required Widget child}) {
    return GestureDetector(
      onTap: () {}, // Sin función por ahora
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  // ────────────────────────────────────────
  // MAPA FLUTTER MAP
  // ────────────────────────────────────────
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(12.1250, -86.2500),
        initialZoom: 13.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // Capa de tiles OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.bellota.app',
        ),
        // Marcadores de bellota
        MarkerLayer(
          markers: _filteredCenters.map((center) {
            return Marker(
              point: center.location,
              width: 44,
              height: 44,
              child: GestureDetector(
                onTap: () => _onMarkerTap(center),
                child: Container(
                  decoration: BoxDecoration(
                    color: BellotaColors.chilero,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: BellotaColors.chilero.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🌰', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ────────────────────────────────────────
  // LISTA DE CENTROS DE SALUD
  // ────────────────────────────────────────
  Widget _buildHealthCenterList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _filteredCenters.map((center) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildHealthCenterCard(center),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHealthCenterCard(HealthCenter center) {
    return GestureDetector(
      onTap: () => _onCardTap(center),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Información del centro
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    center.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: BellotaColors.textoDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _cardBullet(center.type),
                  _cardBullet(center.address),
                  _cardBullet('${center.city}, ${center.department}.'),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Botón flecha naranja
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BellotaColors.melon,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: BellotaColors.melon.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardBullet(String text) {
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
              decoration: const BoxDecoration(
                color: Color(0xFF7A4F47),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: BellotaColors.textoMedio,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
