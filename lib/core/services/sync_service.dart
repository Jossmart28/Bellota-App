import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../database/database_helper.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  /// Exporta todos los datos del usuario a un archivo JSON y permite compartirlo
  Future<String?> exportAndShareBackup(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Obtener perfil
      final profile = await DatabaseHelper.instance.getProfile(userId);
      
      // Obtener todos los daily_logs
      final logs = await db.query(
        'daily_logs',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // Crear payload de exportación
      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'profile': profile,
        'daily_logs': logs,
      };

      final jsonStr = jsonEncode(backupData);

      // Escribir a un archivo temporal
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/bellota_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File(path);
      await file.writeAsString(jsonStr);

      // Compartir el archivo
      final result = await Share.shareXFiles([XFile(path)], text: 'Mi backup de datos de Bellota');
      
      return path; 
    } catch (e) {
      print('Error exporting backup: $e');
      return null;
    }
  }

  /// Permite al usuario seleccionar un archivo JSON y restaura los datos
  Future<bool> importBackup(int currentUserId) async {
    try {
      // Usar file_picker para elegir el archivo
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonStr = await file.readAsString();
        final backupData = jsonDecode(jsonStr);

        if (backupData['version'] == 1) {
          final profileData = backupData['profile'] as Map<String, dynamic>?;
          final logsData = backupData['daily_logs'] as List<dynamic>?;

          final db = await DatabaseHelper.instance.database;

          await db.transaction((txn) async {
            if (profileData != null) {
              final Map<String, dynamic> updateData = Map<String, dynamic>.from(profileData);
              updateData.remove('user_id'); // Asegurarnos de no sobreescribir con otro ID si hubo error
              
              await txn.update(
                'profiles',
                updateData,
                where: 'user_id = ?',
                whereArgs: [currentUserId],
              );
            }

            if (logsData != null) {
              for (var rawLog in logsData) {
                final log = Map<String, dynamic>.from(rawLog);
                log['user_id'] = currentUserId; // Forzar el ID del usuario actual

                final date = log['date'];
                final exists = await txn.query('daily_logs', where: 'user_id = ? AND date = ?', whereArgs: [currentUserId, date]);
                
                if (exists.isNotEmpty) {
                  await txn.update(
                    'daily_logs',
                    log,
                    where: 'user_id = ? AND date = ?',
                    whereArgs: [currentUserId, date],
                  );
                } else {
                  await txn.insert('daily_logs', log);
                }
              }
            }
          });

          return true;
        }
      }
    } catch (e) {
      print('Error importing backup: $e');
    }
    return false;
  }
}
