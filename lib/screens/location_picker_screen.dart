import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/bellota_colors.dart';

/// Pantalla de selecciÃ³n de ubicaciÃ³n con flutter_map.
/// Devuelve un String con "Ciudad, PaÃ­s" al hacer pop.
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  const LocationPickerScreen({super.key, this.initialPosition});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _selectedPosition;
  final MapController _mapController = MapController();
  String _locationLabel = 'Mueve el mapa para elegir tu ubicaciÃ³n';
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition ?? LatLng(9.9281, -84.0907); // Costa Rica default
    _resolveAddress(_selectedPosition);
  }

  Future<void> _resolveAddress(LatLng pos) async {
    setState(() => _isResolving = true);
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final city = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? '';
        final country = p.country ?? '';
        final label = [city, country].where((s) => s.isNotEmpty).join(', ');
        setState(() => _locationLabel = label.isNotEmpty ? label : 'UbicaciÃ³n seleccionada');
      }
    } catch (_) {
      if (mounted) setState(() => _locationLabel = 'No se pudo obtener la direcciÃ³n');
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  void _onMapTap(TapPosition _, LatLng pos) {
    setState(() => _selectedPosition = pos);
    _resolveAddress(pos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Selecciona tu ubicaciÃ³n',
            style: GoogleFonts.poppins(
                color: Theme.of(context).bellotaColors.textoDark,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Theme.of(context).bellotaColors.textoDark),
      ),
      body: Stack(
        children: [
          // â”€â”€ Mapa â”€â”€
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 10,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bellota.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition,
                    width: 48,
                    height: 48,
                    child: Icon(Icons.location_pin, color: Theme.of(context).bellotaColors.chilero, size: 48),
                  ),
                ],
              ),
            ],
          ),

          // â”€â”€ Etiqueta flotante abajo â”€â”€
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.place, color: Theme.of(context).bellotaColors.chilero),
                  SizedBox(width: 10),
                  Expanded(
                    child: _isResolving
                        ? Row(children: [
                            SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).bellotaColors.chilero),
                            ),
                            SizedBox(width: 10),
                            Text('Buscando direcciÃ³nâ€¦', style: GoogleFonts.poppins(fontSize: 13, color: Theme.of(context).bellotaColors.textoMedio)),
                          ])
                        : Text(
                            _locationLabel,
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).bellotaColors.textoDark),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // â”€â”€ BotÃ³n Confirmar â”€â”€
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: ElevatedButton.icon(
              onPressed: _isResolving
                  ? null
                  : () => Navigator.pop(context, {
                        'label': _locationLabel,
                        'position': _selectedPosition,
                      }),
              icon: Icon(Icons.check_circle_outline, color: Colors.white),
              label: Text(
                'Confirmar ubicaciÃ³n',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).bellotaColors.chilero,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 4,
              ),
            ),
          ),

          // â”€â”€ Hint â”€â”€
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Toca el mapa para mover el pin',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

