import '../models/health_center_model.dart';
import 'hospital_data.dart';

class HospitalRepository {
  static final HospitalRepository _instance = HospitalRepository._();
  factory HospitalRepository() => _instance;
  HospitalRepository._();

  List<HealthCenter> getAll() => hospitalDataList;

  HealthCenter? getById(String id) {
    try {
      return hospitalDataList.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  List<HealthCenter> search(String query) {
    final q = query.toLowerCase();
    if (q.isEmpty) return getAll();

    return hospitalDataList.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.services.any((s) => s.toLowerCase().contains(q)) ||
          c.address.toLowerCase().contains(q) ||
          c.municipality.toLowerCase().contains(q) ||
          c.department.toLowerCase().contains(q);
    }).toList();
  }
}
