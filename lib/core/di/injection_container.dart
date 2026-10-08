import 'package:get_it/get_it.dart';
import 'package:bellotadevelopment/data/datasources/database_provider.dart';
import 'package:bellotadevelopment/domain/repositories/auth_repository.dart';
import 'package:bellotadevelopment/data/repositories/auth_repository_impl.dart';
import 'package:bellotadevelopment/domain/repositories/user_repository.dart';
import 'package:bellotadevelopment/data/repositories/user_repository_impl.dart';
import 'package:bellotadevelopment/domain/repositories/profile_repository.dart';
import 'package:bellotadevelopment/data/repositories/profile_repository_impl.dart';
import 'package:bellotadevelopment/domain/repositories/audit_repository.dart';
import 'package:bellotadevelopment/data/repositories/audit_repository_impl.dart';
import 'package:bellotadevelopment/domain/repositories/daily_log_repository.dart';
import 'package:bellotadevelopment/data/repositories/daily_log_repository_impl.dart';
import 'package:bellotadevelopment/domain/services/health_prediction_service.dart';

final sl = GetIt.instance; // sl = Service Locator

Future<void> initDependencies() async {
  // 1. Core / Data sources
  sl.registerLazySingleton<DatabaseProvider>(() => DatabaseProvider());
  
  // Inicializamos la BD al arrancar para tenerla lista
  await sl<DatabaseProvider>().database;

  // 2. Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(sl()));
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl()));
  sl.registerLazySingleton<AuditRepository>(() => AuditRepositoryImpl(sl()));
  sl.registerLazySingleton<DailyLogRepository>(() => DailyLogRepositoryImpl(sl()));
  
  // 3. Services / Usecases
  sl.registerLazySingleton<HealthPredictionService>(() => HealthPredictionService());
  
  // 4. Controllers / ViewModels
}
