import 'package:latlong2/latlong.dart';
import 'package:bellotadevelopment/core/models/health_center_model.dart';

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
    supportedTiers: ["primaryCare", "emergency", "gynecology", "specializedImaging"],
  ),
  HealthCenter(
    id: "RACCS-001",
    name: "Centro de Salud de Bluefields (Ejemplo Rural)",
    department: "RACCS",
    municipality: "Bluefields",
    address: "Barrio Central, Bluefields",
    phone: "+505 2572-0000",
    type: "Puesto de Salud",
    services: [
      "Consulta General",
      "EnfermerÃ­a",
      "PlanificaciÃ³n Familiar",
      "Control Prenatal BÃ¡sico",
    ],
    location: LatLng(12.0136, -83.7634),
    relevanceScore: 70,
    specialtyTags: ["medicina_general", "planificacion"],
    symptomTags: ["fever", "headache"],
    openHours: "Lunes a Viernes 8am - 4pm",
    emergencyAvailable: false,
    supportedTiers: ["primaryCare"],
  ),
];

