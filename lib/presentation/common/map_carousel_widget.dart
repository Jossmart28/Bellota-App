import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';
import 'package:bellotadevelopment/presentation/screens/hospitals/health_center_detail_screen.dart';
import 'package:bellotadevelopment/core/models/health_center_model.dart';
import 'package:bellotadevelopment/core/data/hospital_repository.dart';

class MapCarouselWidget extends StatefulWidget {
  final LatLng? userLocation;

  const MapCarouselWidget({super.key, this.userLocation});

  @override
  State<MapCarouselWidget> createState() => _MapCarouselWidgetState();
}

class _MapCarouselWidgetState extends State<MapCarouselWidget> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final HospitalRepository _repository = HospitalRepository();
  final PageController _carouselController = PageController(viewportFraction: 0.82);

  List<HealthCenter> _healthCenters = [];
  int _selectedIndex = -1;
  HealthCenter? _selectedCenter;

  // Animations
  late AnimationController _zoomPulseCtrl;
  Timer? _zoomTimer;
  late AnimationController _markerPopCtrl;
  late Animation<double> _markerPopAnim;

  @override
  void initState() {
    super.initState();
    _healthCenters = _repository.getAll();
    
    // Zoom controller
    _zoomPulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

    // Marker pop-up controller
    _markerPopCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _markerPopAnim = CurvedAnimation(parent: _markerPopCtrl, curve: Curves.elasticOut);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.userLocation != null) {
        _mapController.move(widget.userLocation!, 13.0);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MapCarouselWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userLocation != null && oldWidget.userLocation == null) {
      _mapController.move(widget.userLocation!, 13.0);
    }
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _zoomPulseCtrl.dispose();
    _markerPopCtrl.dispose();
    _zoomTimer?.cancel();
    super.dispose();
  }

  List<HealthCenter> get _displayedCenters {
    // Sort by proximity if we have user location
    if (widget.userLocation != null) {
      final sorted = List<HealthCenter>.from(_healthCenters);
      final dist = const Distance();
      sorted.sort((a, b) {
        final da = dist(a.location, widget.userLocation!);
        final db = dist(b.location, widget.userLocation!);
        return da.compareTo(db);
      });
      return sorted;
    }
    return _healthCenters;
  }

  // ── Fly from previous marker → new marker ─────────────────────────────────
  void _flyToCenter(HealthCenter center, int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.mediumImpact();

    final wasSelected = _selectedIndex >= 0;
    final fromLocation = _selectedCenter?.location;

    // Pop DOWN the old marker (reverse)
    if (wasSelected) {
      _markerPopCtrl.reverse();
    }

    Future.delayed(wasSelected ? const Duration(milliseconds: 180) : Duration.zero, () {
      if (!mounted) return;

      setState(() {
        _selectedIndex = index;
        _selectedCenter = center;
      });

      if (wasSelected && fromLocation != null) {
        // Phase 1: zoom out a little from the previous point
        _animatedMove(fromLocation, 11.0, const Duration(milliseconds: 400));

        // Phase 2: fly across to new location
        Future.delayed(const Duration(milliseconds: 420), () {
          if (!mounted) return;
          _animatedMove(center.location, 15.0, const Duration(milliseconds: 1100));

          // Phase 3: pop up the new marker once we arrive
          Future.delayed(const Duration(milliseconds: 950), () {
            if (!mounted) return;
            _markerPopCtrl.forward(from: 0);
          });
        });
      } else {
        // First selection: zoom out → zoom in
        _mapController.move(center.location, 10.0);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          _animatedMove(center.location, 15.0, const Duration(milliseconds: 1200));
          Future.delayed(const Duration(milliseconds: 1050), () {
            if (!mounted) return;
            _markerPopCtrl.forward(from: 0);
          });
        });
      }
    });
  }

  void _animatedMove(LatLng dest, double destZoom, Duration duration) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: dest.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: dest.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final ctrl = AnimationController(vsync: this, duration: duration);
    final anim = CurvedAnimation(parent: ctrl, curve: Curves.easeInOutCubic);

    ctrl.addListener(() {
      if (!mounted) return;
      _mapController.move(LatLng(latTween.evaluate(anim), lngTween.evaluate(anim)), zoomTween.evaluate(anim));
    });
    ctrl.forward().whenComplete(() => ctrl.dispose());
  }

  String _distanceLabel(HealthCenter center) {
    if (widget.userLocation == null) return '';
    final km = const Distance()(center.location, widget.userLocation!) / 1000;
    return km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).bellotaColors;
    final centers = _displayedCenters;

    return Container(
      height: 480, // Fixed height for the widget to fit inside the hub list
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.chilero.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // ── Map ─────────────────────────────────────────
            Expanded(child: _buildMap(centers, colors)),
            // ── Carousel ────────────────────────────────────
            _buildCarousel(centers, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(List<HealthCenter> centers, BellotaColors colors) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.userLocation ?? const LatLng(12.1250, -86.2500),
        initialZoom: 13.0,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.bellota.app',
        ),
        MarkerLayer(
          markers: [
            ...centers.asMap().entries.map((entry) {
              final idx = entry.key;
              final center = entry.value;
              final isSelected = _selectedIndex == idx;

              return Marker(
                point: center.location,
                width: isSelected ? 54 : 38,
                height: isSelected ? 60 : 42,
                child: GestureDetector(
                  onTap: () {
                    _flyToCenter(center, idx);
                    _carouselController.animateToPage(
                      idx,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: isSelected
                      ? ScaleTransition(
                          scale: _markerPopAnim,
                          child: Image.asset('assets/images/bellota_hospital_marker.png', fit: BoxFit.contain),
                        )
                      : Image.asset(
                          'assets/images/bellota_hospital_marker.png',
                          fit: BoxFit.contain,
                          color: colors.textoMedio.withOpacity(0.5),
                          colorBlendMode: BlendMode.srcIn,
                        ),
                ),
              );
            }),
            if (widget.userLocation != null)
              Marker(
                point: widget.userLocation!,
                width: 48,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: const Color(0xFF4285F4).withOpacity(0.4), blurRadius: 10)],
                  ),
                  width: 16,
                  height: 16,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCarousel(List<HealthCenter> centers, BellotaColors colors) {
    if (centers.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 178,
      child: PageView.builder(
        controller: _carouselController,
        itemCount: centers.length,
        onPageChanged: (idx) => _flyToCenter(centers[idx], idx),
        itemBuilder: (context, idx) {
          final center = centers[idx];
          final isSelected = _selectedIndex == idx;
          final dist = _distanceLabel(center);

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => HealthCenterDetailScreen(center: center)),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.fromLTRB(6, isSelected ? 10 : 16, 6, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? Border.all(color: colors.chilero.withOpacity(0.4), width: 2) : Border.all(color: colors.nancite),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? colors.chilero.withOpacity(0.15) : Colors.black.withOpacity(0.04),
                    blurRadius: isSelected ? 12 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(19), topRight: Radius.circular(19)),
                    child: SizedBox(
                      height: 70,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          center.imageAsset != null
                              ? Image.asset(center.imageAsset!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _cardGradient(colors))
                              : _cardGradient(colors),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                          if (center.emergencyAvailable)
                            Positioned(
                              top: 8,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(10)),
                                child: const Text('24h', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          center.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textoDark),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 12, color: colors.chilero),
                            const SizedBox(width: 3),
                            if (dist.isNotEmpty) Text(dist, style: TextStyle(fontSize: 11, color: colors.textoMedio)),
                            if (dist.isNotEmpty) const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                center.municipality,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: colors.textoMedio),
                              ),
                            ),
                          ],
                        ),
                        if (center.specialtyTags.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 4,
                            children: center.specialtyTags.take(2).map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: colors.nancite, borderRadius: BorderRadius.circular(8)),
                              child: Text(tag.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: colors.textoMedio)),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _cardGradient(BellotaColors colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.chilero, colors.melon], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Center(child: Icon(Icons.local_hospital_rounded, size: 32, color: Colors.white.withOpacity(0.5))),
    );
  }
}
