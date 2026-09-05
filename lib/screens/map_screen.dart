import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import '../widgets/bellota_top_actions.dart';
import '../widgets/bellota_icon.dart';
import 'health_center_detail_screen.dart';
import '../core/models/health_center_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isListVisible = true;
  LatLng? _userLocation;

  // Ã¢â€â‚¬Ã¢â€â‚¬ Centros de salud Ã¢â€â‚¬Ã¢â€â‚¬
  final List<HealthCenter> _healthCenters = [
    HealthCenter(
      id: "MGA-001",
      name: "Hospital Materno Infantil Bertha Calderón Roque",
      department: "Managua",
      municipality: "Managua",
      address: "Semáforos del Zumen 200m al sur, Distrito III",
      phone: "+505 2265-1020",
      type: "Hospital Especializado Materno Infantil",
      services: [
        "Ginecología",
        "Obstetricia",
        "Neonatología",
        "Oncología Ginecológica",
        "Mamografía",
        "Atención al Parto"
      ],
      location: LatLng(12.1285, -86.2941),
    ),
    HealthCenter(
      id: "MGA-002",
      name: "Hospital Infantil Manuel de Jesús Rivera 'La Mascota'",
      department: "Managua",
      municipality: "Managua",
      address: "Semaforos de la Lotería Nacional 2 c. al este, 1 c. al norte",
      phone: "+505 2289-7250",
      type: "Hospital Especializado Pediátrico",
      services: [
        "Pediatría Especializada",
        "Cirugía Pediátrica",
        "Onco-Hematología Pediátrica",
        "UCI Pediátrica",
        "Emergencias Pediátricas 24/7"
      ],
      location: LatLng(12.1158, -86.2621),
    ),
    HealthCenter(
      id: "MGA-003",
      name: "Hospital Escuela Roberto Calderón Gutiérrez",
      department: "Managua",
      municipality: "Managua",
      address: "Pista de la Solidaridad, frente a Universidad Agraria",
      phone: "+505 2289-4700",
      type: "Hospital Nacional de Referencia",
      services: [
        "Oncología Adultos",
        "Cirugía General",
        "Medicina Interna",
        "Urgencias 24/7",
        "Hemodiálisis"
      ],
      location: LatLng(12.1189, -86.2364),
    ),
    HealthCenter(
      id: "MGA-004",
      name: "Hospital Occidental Fernando Vélez Paiz",
      department: "Managua",
      municipality: "Managua",
      address: "Km 5.5 Carretera Sur, de los Semáforos de Belmonte 100m al norte",
      phone: "+505 2232-1500",
      type: "Hospital Departamental / General",
      services: [
        "Cirugía Laparoscópica",
        "Pediatría",
        "Ginecobstetricia",
        "Ortopedia",
        "Imagenología Avanzada"
      ],
      location: LatLng(12.1231, -86.3075),
    ),
    HealthCenter(
      id: "MGA-005",
      name: "Hospital Antonio Lenín Fonseca",
      department: "Managua",
      municipality: "Managua",
      address: "Las Brisas 2 c. al sur, Distrito II",
      phone: "+505 2266-0700",
      type: "Hospital Nacional de Referencia",
      services: [
        "Neurocirugía",
        "Traumatología",
        "Urología",
        "Unidad de Cuidados Intensivos",
        "Emergencias 24/7"
      ],
      location: LatLng(12.1524, -86.3021),
    ),
    HealthCenter(
      id: "MGA-006",
      name: "Hospital Alemán Nicaragüense",
      department: "Managua",
      municipality: "Managua",
      address: "Semaforos de la Subasta 3 c. al norte, Distrito VI",
      phone: "+505 2249-1120",
      type: "Hospital Departamental",
      services: [
        "Emergencias 24/7",
        "Ginecología",
        "Pediatría",
        "Cirugía General",
        "Atención del Parto"
      ],
      location: LatLng(12.1512, -86.2163),
    ),
    HealthCenter(
      id: "MGA-007",
      name: "Centro de Salud Francisco Buitrago",
      department: "Managua",
      municipality: "Managua",
      address: "Mercado Oriental, del Novillo 3 c. al lago",
      phone: "+505 2249-3310",
      type: "Centro de Salud Familiar",
      services: [
        "Atención Primaria",
        "Planificación Familiar",
        "Vacunación",
        "Control Prenatal",
        "Odontología"
      ],
      location: LatLng(12.1462, -86.2578),
    ),
    HealthCenter(
      id: "MGA-008",
      name: "Centro de Salud Sócrates Flores",
      department: "Managua",
      municipality: "Managua",
      address: "Barrio Monseñor Lezcano, de la Iglesia 1 c. abajo, Distrito II",
      phone: "+505 2266-3211",
      type: "Centro de Salud Familiar",
      services: [
        "Medicina General",
        "Pediatría Primaria",
        "Vacunación",
        "Programa Chagas/Dengue"
      ],
      location: LatLng(12.1491, -86.2915),
    ),
    HealthCenter(
      id: "MGA-009",
      name: "Centro de Salud Pedro Altamirano",
      department: "Managua",
      municipality: "Managua",
      address: "Colonia Centroamérica, de la Gasolinera 1 c. al este, Distrito V",
      phone: "+505 2270-1422",
      type: "Centro de Salud Familiar",
      services: [
        "Atención Prenatal",
        "Odontología",
        "Laboratorio Clínico",
        "Control de Enfermedades Crónicas"
      ],
      location: LatLng(12.1123, -86.2511),
    ),
    HealthCenter(
      id: "LEO-001",
      name: "Hospital Escuela Oscar Danilo Rosales Argüello (HEODRA)",
      department: "León",
      municipality: "León",
      address: "Frente a la Plaza Central, Calle Real",
      phone: "+505 2311-2222",
      type: "Hospital Regional Escuela",
      services: [
        "Emergencias 24/7",
        "Pediatría",
        "Cirugía General",
        "Maternidad y Ginecología",
        "Cardiología"
      ],
      location: LatLng(12.43525, -86.87912),
    ),
    HealthCenter(
      id: "LEO-002",
      name: "Centro de Salud Periférico Subtiava",
      department: "León",
      municipality: "León",
      address: "De la Iglesia San Juan Bautista 2 cuadras al sur",
      phone: "+505 2311-4567",
      type: "Centro de Salud Familiar",
      services: [
        "Consulta Externa",
        "Vacunación",
        "Odontología",
        "Medicina General",
        "Atención Prenatal"
      ],
      location: LatLng(12.4281, -86.8923),
    ),
    HealthCenter(
      id: "LEO-003",
      name: "Centro de Salud Mántica Berio",
      department: "León",
      municipality: "León",
      address: "Barrio Laborío, Contiguo a la Cancha San Juan",
      phone: "+505 2311-8901",
      type: "Centro de Salud Familiar",
      services: [
        "Atención Primaria",
        "Control Prenatal",
        "Laboratorio Clínico",
        "Vacunación"
      ],
      location: LatLng(12.4398, -86.8815),
    ),
    HealthCenter(
      id: "LEO-004",
      name: "Hospital Primario Coronel Santos López",
      department: "León",
      municipality: "El Sauce",
      address: "Entrada principal a El Sauce, contiguo al Estadio Municipal",
      phone: "+505 2319-2100",
      type: "Hospital Primario",
      services: [
        "Urgencias",
        "Maternidad",
        "Medicina General",
        "Laboratorio",
        "Ultrasonografía"
      ],
      location: LatLng(12.9861, -86.5382),
    ),
    HealthCenter(
      id: "CHN-001",
      name: "Hospital General Doctor Mauricio Abdalah",
      department: "Chinandega",
      municipality: "Chinandega",
      address: "Carretera Chinandega - El Viejo, Km 134",
      phone: "+505 2341-2050",
      type: "Hospital Departamental General",
      services: [
        "Emergencias 24/7",
        "Ginecología y Obstetricia",
        "Cirugía",
        "Pediatría",
        "Cuidados Intensivos"
      ],
      location: LatLng(12.6391, -87.1352),
    ),
    HealthCenter(
      id: "CHN-002",
      name: "Centro de Salud Roberto Cortez",
      department: "Chinandega",
      municipality: "Chinandega",
      address: "Barrio Santa Ana, del Templo San Antonio 2 c. al oeste",
      phone: "+505 2341-3310",
      type: "Centro de Salud Familiar",
      services: [
        "Atención Primaria",
        "Ginecología Preventiva",
        "Inmunizaciones",
        "Atención Integral a la Mujer"
      ],
      location: LatLng(12.6284, -87.1298),
    ),
    HealthCenter(
      id: "CHN-003",
      name: "Hospital Primario Teodoro King",
      department: "Chinandega",
      municipality: "El Viejo",
      address: "De la Parroquia Nuestra Señora de los Ángeles 3 c. al norte",
      phone: "+505 2344-2110",
      type: "Hospital Primario",
      services: [
        "Atención de Partos",
        "Urgencias 24/7",
        "Pediatría General",
        "Ecografía"
      ],
      location: LatLng(12.6631, -87.1685),
    ),
    HealthCenter(
      id: "MAS-001",
      name: "Hospital Departamental Doctor Humberto Alvarado Vásquez",
      department: "Masaya",
      municipality: "Masaya",
      address: "Entrada a Masaya por la Rotonda San Jerónimo 800m al sur",
      phone: "+505 2522-2580",
      type: "Hospital Departamental",
      services: [
        "Emergencias 24/7",
        "Ginecobstetricia",
        "Cirugía General",
        "Pediatría",
        "Ortopedia"
      ],
      location: LatLng(11.9792, -86.0981),
    ),
    HealthCenter(
      id: "MAS-002",
      name: "Centro de Salud Monimbó",
      department: "Masaya",
      municipality: "Masaya",
      address: "Plaza Tiangue Monimbó 1 c. al oeste",
      phone: "+505 2522-3100",
      type: "Centro de Salud Familiar",
      services: [
        "Atención Preventiva",
        "Planificación Familiar",
        "Pediatría",
        "Salud Materna"
      ],
      location: LatLng(11.9684, -86.0945),
    ),
    HealthCenter(
      id: "GRA-001",
      name: "Hospital Departamental Amistad Japón Nicaragua",
      department: "Granada",
      municipality: "Granada",
      address: "Carretera Granada - Malacatoya, Km 46",
      phone: "+505 2552-2720",
      type: "Hospital Departamental",
      services: [
        "Emergencias 24/7",
        "Maternidad",
        "Cirugía General",
        "Pediatría",
        "Radiología"
      ],
      location: LatLng(11.9365, -85.9523),
    ),
    HealthCenter(
      id: "GRA-002",
      name: "Centro de Salud Villa Sandino",
      department: "Granada",
      municipality: "Granada",
      address: "Reparto Villa Sandino, del Tanque de Agua 1 c. al sur",
      phone: "+505 2552-4112",
      type: "Centro de Salud Familiar",
      services: [
        "Atención Prenatal",
        "Vacunación",
        "Medicina General",
        "Odontología"
      ],
      location: LatLng(11.9298, -85.9681),
    ),
    HealthCenter(
      id: "CAR-001",
      name: "Hospital Regional Santiago de Jinotepe",
      department: "Carazo",
      municipality: "Jinotepe",
      address: "Salida a San Marcos, frente al Estadio Pedro Selva",
      phone: "+505 2532-2340",
      type: "Hospital Regional",
      services: [
        "Urgencias 24/7",
        "Ginecología",
        "Pediatría",
        "Cirugía General",
        "Laboratorio Clínico"
      ],
      location: LatLng(11.8541, -86.1985),
    ),
    HealthCenter(
      id: "CAR-002",
      name: "Hospital Primario Maestro San José",
      department: "Carazo",
      municipality: "Diriamba",
      address: "Del Reloj de Diriamba 4 c. al sur",
      phone: "+505 2534-2210",
      type: "Hospital Primario",
      services: [
        "Atención de Partos",
        "Consulta Externa",
        "Emergencias",
        "Vacunación"
      ],
      location: LatLng(11.8562, -86.2391),
    ),
    HealthCenter(
      id: "RIV-001",
      name: "Hospital Departamental Gaspar García Laviana",
      department: "Rivas",
      municipality: "Rivas",
      address: "Km 112 Carretera Panamericana Sur",
      phone: "+505 2563-3240",
      type: "Hospital Departamental",
      services: [
        "Emergencias 24/7",
        "Cirugía General",
        "Ortopedia",
        "Gineco-obstetricia",
        "Consulta Externa"
      ],
      location: LatLng(11.4385, -85.8341),
    ),
    HealthCenter(
      id: "RIV-002",
      name: "Centro de Salud Camilo Ortega Saavedra",
      department: "Rivas",
      municipality: "Rivas",
      address: "Barrio San Francisco, del Parque Infantil 2 c. al este",
      phone: "+505 2563-0112",
      type: "Centro de Salud Familiar",
      services: [
        "Atención Primaria",
        "Planificación Familiar",
        "Control Prenatal",
        "Vacunación"
      ],
      location: LatLng(11.4421, -85.8295),
    ),
    HealthCenter(
      id: "EST-001",
      name: "Hospital Regional San Juan de Dios",
      department: "Estelí",
      municipality: "Estelí",
      address: "Salida sur de la ciudad, Carretera Panamericana",
      phone: "+505 2713-2451",
      type: "Hospital Regional",
      services: [
        "Urgencias 24/7",
        "Traumatología",
        "Pediatría",
        "Radiología",
        "Ginecología"
      ],
      location: LatLng(13.0833, -86.3538),
    ),
    HealthCenter(
      id: "EST-002",
      name: "Centro de Salud Leonel Rugama Rugama",
      department: "Estelí",
      municipality: "Estelí",
      address: "Barrio Juana Elena Mendoza, de la ENABAS 2 c. al oeste",
      phone: "+505 2713-3320",
      type: "Centro de Salud Familiar",
      services: [
        "Medicina General",
        "Salud Materna",
        "Odontología",
        "Laboratorio"
      ],
      location: LatLng(13.0912, -86.3581),
    ),
    HealthCenter(
      id: "MAD-001",
      name: "Hospital Departamental Juan Antonio Brenes Palacios",
      department: "Madriz",
      municipality: "Somoto",
      address: "Entrada principal a Somoto, contiguo a ENACAL",
      phone: "+505 2722-2215",
      type: "Hospital Departamental",
      services: [
        "Emergencias 24/7",
        "Maternidad",
        "Cirugía General",
        "Pediatría"
      ],
      location: LatLng(13.4812, -86.5821),
    ),
    HealthCenter(
      id: "NSG-001",
      name: "Hospital Departamental Alfonso Moncada Guillén",
      department: "Nueva Segovia",
      municipality: "Ocotal",
      address: "Barrio Nicarao, de la Calzada 3 c. al norte",
      phone: "+505 2732-2300",
      type: "Hospital Departamental",
      services: [
        "Emergencias 24/7",
        "Obstetricia",
        "Pediatría",
        "Cirugía General"
      ],
      location: LatLng(13.6321, -86.4782),
    ),
    HealthCenter(
      id: "MAT-001",
      name: "Hospital Escuela César Amador Molina",
      department: "Matagalpa",
      municipality: "Matagalpa",
      address: "Entrada principal a Matagalpa, Contiguo al Río Grande",
      phone: "+505 2772-2011",
      type: "Hospital Regional Escuela",
      services: [
        "Medicina Interna",
        "Cirugía",
        "Gineco-obstetricia",
        "Hemodiálisis",
        "UCI"
      ],
      location: LatLng(12.9261, -85.9182),
    ),
    HealthCenter(
      id: "JIN-001",
      name: "Hospital Departamental Victoria Motta",
      department: "Jinotega",
      municipality: "Jinotega",
      address: "Barrio San Juan, contiguo al Estadio Moisés Palacios",
      phone: "+505 2782-2311",
      type: "Hospital Departamental",
      services: [
        "Emergencias 24/7",
        "Maternidad",
        "Pediatría",
        "Cirugía General"
      ],
      location: LatLng(13.0982, -85.9981),
    ),
    HealthCenter(
      id: "BOA-001",
      name: "Hospital Departamental José Nieborowski",
      department: "Boaco",
      municipality: "Boaco",
      address: "Salida a Managua, frente a la Subestación Eléctrica",
      phone: "+505 2542-2200",
      type: "Hospital Departamental",
      services: [
        "Emergencias 24/7",
        "Cirugía General",
        "Gineco-obstetricia",
        "Pediatría"
      ],
      location: LatLng(12.4721, -85.6582),
    ),
    HealthCenter(
      id: "CHO-001",
      name: "Hospital Regional Escuela Asunción de Juigalpa",
      department: "Chontales",
      municipality: "Juigalpa",
      address: "Salida a Rama, Km 140",
      phone: "+505 2512-2300",
      type: "Hospital Regional Escuela",
      services: [
        "Emergencias 24/7",
        "Traumatología",
        "Maternidad",
        "Cirugía",
        "Cuidados Intensivos"
      ],
      location: LatLng(12.1082, -85.3621),
    ),
    HealthCenter(
      id: "RSJ-001",
      name: "Hospital Departamental Luis Felipe Moncada",
      department: "Río San Juan",
      municipality: "San Carlos",
      address: "Barrio 19 de Julio, San Carlos",
      phone: "+505 2583-0100",
      type: "Hospital Departamental",
      services: [
        "Emergencias 24/7",
        "Atención al Parto",
        "Pediatría",
        "Cirugía General",
        "Laboratorio"
      ],
      location: LatLng(11.1281, -84.7782),
    ),
    HealthCenter(
      id: "RAC-001",
      name: "Hospital Regional Nuevo Amanecer",
      department: "RACCN",
      municipality: "Puerto Cabezas (Bilwi)",
      address: "Barrio Peter Ferrera, Bilwi",
      phone: "+505 2792-2210",
      type: "Hospital Regional",
      services: [
        "Emergencias 24/7",
        "Cirugía General",
        "Gineco-obstetricia",
        "Pediatría",
        "Medicina Intercultural"
      ],
      location: LatLng(14.0321, -83.3892),
    ),
    HealthCenter(
      id: "RAC-002",
      name: "Hospital Regional Doctor Ernesto Sequeira Blanco",
      department: "RACCS",
      municipality: "Bluefields",
      address: "Barrio Central, frente al Parque Reyes",
      phone: "+505 2572-2311",
      type: "Hospital Regional",
      services: [
        "Emergencias 24/7",
        "Maternidad e Infancia",
        "Cirugía General",
        "Laboratorio Clínico"
      ],
      location: LatLng(12.0132, -83.7642),
    ),
  ];

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
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
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _healthCenters;

    return _healthCenters.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.services.any((s) => s.toLowerCase().contains(query)) ||
          c.address.toLowerCase().contains(query) ||
          c.municipality.toLowerCase().contains(query) ||
          c.department.toLowerCase().contains(query);
    }).toList();
  }

  /// Centros que se muestran en la lista lateral.
  List<HealthCenter> get _filteredCenters {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _healthCenters;

    return _healthCenters.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.services.any((s) => s.toLowerCase().contains(query)) ||
          c.address.toLowerCase().contains(query) ||
          c.municipality.toLowerCase().contains(query) ||
          c.department.toLowerCase().contains(query);
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
        // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
        // BARRA SUPERIOR — Búsqueda + íconos
        // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
        _buildSearchBar(context),
        
        // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
        // MAPA + LISTA (scrollable)
        // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
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
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                ),
              ),
              if (_isListVisible)
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredCenters.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: _buildHealthCenterCard(context, _filteredCenters[index]),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€¢Â
  // BARRA DE BÚSQUEDA Y BOTONES GLOBALES
  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildSearchBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).bellotaColors.basilica,
      child: Row(
        children: [
          // Campo de búsqueda
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).bellotaColors.blanco,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(width: 14),
                  Icon(Icons.search, color: Theme.of(context).bellotaColors.textoMedio, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).bellotaColors.textoDark),
                      decoration: InputDecoration(
                        hintText: 'Buscar centro de salud...',
                        hintStyle: textTheme.bodyMedium?.copyWith(color: Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.6)),
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
          SizedBox(width: 10),
          
          // === BOTONES GLOBALES ===
          BellotaTopActions(
            showSettings: false, 
            onTalkBackPressed: () {},
          ),
        ],
      ),
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  // MAPA FLUTTER MAP
  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(12.1250, -86.2500),
        initialZoom: 13.0,
        interactionOptions: InteractionOptions(
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
                Color(0xFF4CAF50),
                Color(0xFF2196F3),
                Color(0xFF9C27B0),
                Color(0xFFFFB300),
                Color(0xFF00BCD4),
                Color(0xFFE91E63),
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
            
            // Ã¢â€â‚¬Ã¢â€â‚¬ Pin de la ubicación del usuario Ã¢â€â‚¬Ã¢â€â‚¬
            if (_userLocation != null)
              Marker(
                point: _userLocation!,
                width: 80,
                height: 65,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).bellotaColors.textoDark,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
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

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  // LISTA DE CENTROS DE SALUD
  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  Widget _buildHealthCenterCard(BuildContext context, HealthCenter center) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => _onCardTap(center),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).bellotaColors.blanco,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
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
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).bellotaColors.textoDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  _cardBullet(context, center.type),
                  _cardBullet(context, center.address),
                  _cardBullet(context, '${center.municipality}, ${center.department}.'),
                ],
              ),
            ),
            SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).bellotaColors.melon,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: Offset(0, 2),
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
      padding: EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).bellotaColors.textoMedio,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 6),
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





