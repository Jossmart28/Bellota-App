import 'dart:io';

void main() {
  final file = File('lib/screens/dashboard_screen.dart');
  String content = file.readAsStringSync();

  content = content.replaceFirst(
    '''
              nextPeriodDate: _nextPeriodDate,
              predictedSymptoms: _predictedSymptoms,
              todaySymptoms: _todaySymptoms,
              todayMood: _todayMood,
              medicalConditions: _medicalConditions,
              cycleInfo: _cycleInfo,
              currentPhaseIndex: _currentPhaseIndex,
              activeAlerts: _activeAlerts,
''',
    '''
              nextPeriodDate: _nextPeriodDate,
              predictedSymptoms: _predictedSymptoms,
              todaySymptoms: _todaySymptoms,
              todayMood: _todayMood,
              medicalConditions: _medicalConditions,
              cycleInfo: _cycleInfo,
              currentPhaseIndex: _currentPhaseIndex,
              activeAlerts: _activeAlerts,
              userId: _userId,
              contraceptive: _contraceptive,
              lastPeriodStart: _lastPeriodStart,
              cycleDuration: _cycleInfo?.cycleLength ?? 28,
              periodDuration: _cycleInfo?.periodLength ?? 5,
'''
  );

  // Also replace the empty state logic that was there (since HEAD^ had the old empty state)
  content = content.replaceFirst(
'''                if (_todaySymptoms.isEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Image.asset(
                        'assets/decorations/empty_state_cozy.png',
                        width: 54,
                        height: 54,
                        color: Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.7),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.of(context)!.symptomsAndActionsNoSymptomsLogged,
                        style: textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).bellotaColors.textoMedio,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),''',
'''                if (_todaySymptoms.isEmpty)
                  BellotaEmptyState(
                    title: 'Día tranquilo',
                    message: AppLocalizations.of(context)!.symptomsAndActionsNoSymptomsLogged,
                    compact: true,
                    imagePath: _getMascotImageForPhase(_currentPhaseIndex),
                  ),'''
  );
  
  // Also add the missing variables at the top of _DashboardScreenState if they are not there:
  // wait, _userId, _contraceptive, _lastPeriodStart were added before! Let's check if they exist in HEAD^.
  // Actually, HEAD^ (commit 8e7098a) was BEFORE my changes, wait, did I add them in c3b82dc or earlier?
  // I added them in c3b82dc. I need to make sure they exist.
  // I'll just check if they exist, if not add them.
  if (!content.contains('int? _userId;')) {
    content = content.replaceFirst('  bool _isLoading = true;', '  bool _isLoading = true;\n  int? _userId;\n  String? _contraceptive;\n  DateTime? _lastPeriodStart;');
  }

  // And in _loadUser():
  if (!content.contains('_userId = user.id;')) {
    content = content.replaceFirst(
'''        setState(() {
          _userName = user.name;''',
'''        setState(() {
          _userId = user.id;
          _contraceptive = user.contraceptive;
          _userName = user.name;'''
    );
  }

  // And in _loadDashboardData():
  if (!content.contains('_lastPeriodStart = logs.first.date;')) {
    content = content.replaceFirst(
'''      if (logs.isNotEmpty) {
        final lastLog = logs.first;''',
'''      if (logs.isNotEmpty) {
        _lastPeriodStart = logs.first.date;
        final lastLog = logs.first;'''
    );
  }

  file.writeAsStringSync(content);
}