import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:bellotadevelopment/core/di/injection_container.dart';
import 'package:bellotadevelopment/core/models/daily_log_model.dart';
import 'package:bellotadevelopment/domain/repositories/daily_log_repository.dart';

class CalendarController extends ChangeNotifier {
  final DailyLogRepository _dailyLogRepository = sl<DailyLogRepository>();

  Map<DateTime, DailyLogModel> logsData = {};
  List<DateTime> periodStartDates = [];
  bool isLoading = true;

  Future<void> loadLogs(int userId) async {
    isLoading = true;
    notifyListeners();

    try {
      final logs = await _dailyLogRepository.getDailyLogs(userId);
      logsData.clear();
      periodStartDates.clear();

      for (var log in logs) {
        final d = DateTime.parse(log.date);
        final dateKey = DateTime(d.year, d.month, d.day);
        logsData[dateKey] = log;
        
        if (log.periodStart == 1) {
          periodStartDates.add(dateKey);
        }
      }
      
      // Ordenamos para facilidad de cálculos
      periodStartDates.sort((a, b) => b.compareTo(a));
    } catch (e) {
      debugPrint('Error loading logs for calendar: \$e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  DailyLogModel? getLogForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return logsData[key];
  }
}
