import 'package:latlong2/latlong.dart';
import '../models/health_center_model.dart';

final List<HealthCenter> hospitalDataList = [
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
      "Atención al Parto",
    ],
    location: LatLng(12.1285, -86.2941),
    relevanceScore: 100,
    specialtyTags: ["ginecologia", "obstetricia", "materno_infantil", "oncologia_ginecologica"],
    symptomTags: ["pelvic_pain", "abnormal_discharge", "breast_tenderness", "spotting", "abdominal_pain"],
    openHours: "24 horas",
    emergencyAvailable: true,
  ),
];
