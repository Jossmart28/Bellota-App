import 'package:bellotadevelopment/core/models/health_center_model.dart';
import 'package:bellotadevelopment/core/data/hospital_data.dart';

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

  List<HealthCenter> getByTiers(List<String> tiers) {
    if (tiers.isEmpty) return getAll();
    
    return hospitalDataList.where((h) {
      // Return true if the hospital supports ANY of the requested tiers
      return h.supportedTiers.any((tier) => tiers.contains(tier));
    }).toList();
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
