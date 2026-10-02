import 'dart:io';

void main() {
  final file = File('lib/screens/resumen_diario_screen.dart');
  String content = file.readAsStringSync();

  content = content.replaceFirst('class ResumenDiarioScreen extends StatelessWidget {', 'class ResumenDiarioScreen extends StatefulWidget {');

  final oldConstructor = '''
  final DateTime nextPeriodDate;
  final List<String> predictedSymptoms;
  final List<String> todaySymptoms;
  final String? todayMood;
  final List<String> medicalConditions;
  final CycleInfo? cycleInfo;
  final int currentPhaseIndex;
  final List<ClinicalAlert>? activeAlerts;

  const ResumenDiarioScreen({
    super.key,
    required this.nextPeriodDate,
    required this.predictedSymptoms,
    required this.todaySymptoms,
    required this.medicalConditions,
    required this.currentPhaseIndex,
    this.todayMood,
    this.cycleInfo,
    this.activeAlerts,
  });
''';

  final newConstructor = '''
  final DateTime nextPeriodDate;
  final List<String> predictedSymptoms;
  final List<String> todaySymptoms;
  final String? todayMood;
  final List<String> medicalConditions;
  final CycleInfo? cycleInfo;
  final int currentPhaseIndex;
  final List<ClinicalAlert>? activeAlerts;
  
  final int? userId;
  final String? contraceptive;
  final DateTime? lastPeriodStart;
  final int cycleDuration;
  final int periodDuration;

  const ResumenDiarioScreen({
    super.key,
    required this.nextPeriodDate,
    required this.predictedSymptoms,
    required this.todaySymptoms,
    required this.medicalConditions,
    required this.currentPhaseIndex,
    this.todayMood,
    this.cycleInfo,
    this.activeAlerts,
    this.userId,
    this.contraceptive,
    this.lastPeriodStart,
    this.cycleDuration = 28,
    this.periodDuration = 5,
  });

  @override
  State<ResumenDiarioScreen> createState() => _ResumenDiarioScreenState();
}

class _ResumenDiarioScreenState extends State<ResumenDiarioScreen> {
  int _selectedOffset = 0;
  bool _isLoading = false;
  final Map<int, List<String>> _predictions = {};
  final Map<int, int> _phases = {};

  @override
  void initState() {
    super.initState();
    _predictions[0] = widget.predictedSymptoms;
    _phases[0] = widget.currentPhaseIndex;
  }

  Future<void> _fetchPredictionForOffset(int offset) async {
    if (_predictions.containsKey(offset) || widget.userId == null || widget.lastPeriodStart == null) {
      setState(() {
        _selectedOffset = offset;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedOffset = offset;
    });

    final targetDate = DateTime.now().add(Duration(days: offset));
    final phase = CycleService.instance.getPhaseForDate(
      date: targetDate,
      lastPeriodStart: widget.lastPeriodStart!,
      effectiveCycleDuration: widget.cycleDuration,
      periodDuration: widget.periodDuration,
    );

    int pIdx = 0;
    String pNameStr = 'ovulatory';
    switch (phase) {
      case CyclePhase.ovulatory: pIdx = 0; pNameStr = 'ovulatory'; break;
      case CyclePhase.luteal: pIdx = 1; pNameStr = 'luteal'; break;
      case CyclePhase.follicular: pIdx = 2; pNameStr = 'follicular'; break;
      case CyclePhase.menstrual: pIdx = 3; pNameStr = 'menstrual'; break;
    }

    final symps = await DatabaseHelper.instance.getPredictedSymptomsV2(
      widget.userId!, 
      pNameStr,
      widget.medicalConditions,
      widget.contraceptive,
      limit: 5,
    );

    setState(() {
      _predictions[offset] = symps.isNotEmpty ? symps : ['mood_swings', 'headache', 'bloating'];
      _phases[offset] = pIdx;
      _isLoading = false;
    });
  }
''';

  content = content.replaceFirst(oldConstructor, newConstructor);

  // Instead of simple replaces, let's just prefix properties with 'widget.' inside the State class methods
  // Wait, in dart we can just wrap the rest of the file in the State class, but wait, the methods were in the StatelessWidget.
  // So all methods are now inside the State class.
  // Let's replace usages:
  content = content.replaceAll('currentPhaseIndex', '(_phases[_selectedOffset] ?? widget.currentPhaseIndex)');
  content = content.replaceAll('predictedSymptoms.isEmpty', '(_predictions[_selectedOffset] ?? []).isEmpty');
  content = content.replaceAll('predictedSymptoms.length', '(_predictions[_selectedOffset] ?? []).length');
  content = content.replaceAll('predictedSymptoms[index]', '(_predictions[_selectedOffset] ?? [])[index]');

  // Fix references to widget properties (except in constructor and class definition)
  // To be safe, we only replace word boundaries inside methods.
  final RegExp nextPeriodExp = RegExp(r'\bnextPeriodDate\b');
  content = content.replaceAll(nextPeriodExp, 'widget.nextPeriodDate');
  
  final RegExp todaySympExp = RegExp(r'\btodaySymptoms\b');
  content = content.replaceAll(todaySympExp, 'widget.todaySymptoms');

  final RegExp todayMoodExp = RegExp(r'\btodayMood\b');
  content = content.replaceAll(todayMoodExp, 'widget.todayMood');

  final RegExp cycleInfoExp = RegExp(r'\bcycleInfo\b');
  content = content.replaceAll(cycleInfoExp, 'widget.cycleInfo');

  final RegExp activeAlertsExp = RegExp(r'\bactiveAlerts\b');
  content = content.replaceAll(activeAlertsExp, 'widget.activeAlerts');

  // Fix the constructor part that we messed up by doing global replace!
  content = content.replaceAll('widget.widget.', 'widget.');
  
  // Actually, wait, replacing global words will also replace the class fields!
  // Let's fix the class fields back to normal:
  content = content.replaceAll('final DateTime widget.nextPeriodDate;', 'final DateTime nextPeriodDate;');
  content = content.replaceAll('final List<String> widget.todaySymptoms;', 'final List<String> todaySymptoms;');
  content = content.replaceAll('final String? widget.todayMood;', 'final String? todayMood;');
  content = content.replaceAll('final CycleInfo? widget.cycleInfo;', 'final CycleInfo? cycleInfo;');
  content = content.replaceAll('final List<ClinicalAlert>? widget.activeAlerts;', 'final List<ClinicalAlert>? activeAlerts;');
  
  content = content.replaceAll('required this.widget.nextPeriodDate,', 'required this.nextPeriodDate,');
  content = content.replaceAll('required this.widget.todaySymptoms,', 'required this.todaySymptoms,');
  content = content.replaceAll('this.widget.todayMood,', 'this.todayMood,');
  content = content.replaceAll('this.widget.cycleInfo,', 'this.cycleInfo,');
  content = content.replaceAll('this.widget.activeAlerts,', 'this.activeAlerts,');
  
  // Fix the currentPhaseIndex in constructor that got replaced:
  content = content.replaceAll('final int (_phases[_selectedOffset] ?? widget.currentPhaseIndex);', 'final int currentPhaseIndex;');
  content = content.replaceAll('required this.(_phases[_selectedOffset] ?? widget.currentPhaseIndex),', 'required this.currentPhaseIndex,');

  // Also replace _buildDateSelector implementation
  final oldDateSelector = '''
  Widget _buildDateSelector(BuildContext context, BellotaColors colors) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final tomorrow = now.add(const Duration(days: 1));

    final List<String> monthNames = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final List<String> weekDays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

    String format(DateTime d) => '\ \';
    String formatDay(DateTime d) => weekDays[d.weekday - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _dateItem(formatDay(yesterday), format(yesterday), false),
          _dateItem('Hoy', format(now), true),
          _dateItem(formatDay(tomorrow), format(tomorrow), false),
        ],
      ),
    );
  }

  Widget _dateItem(String day, String date, bool isToday) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            fontSize: isToday ? 18 : 14,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
            color: Colors.white.withValues(alpha: isToday ? 1.0 : 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: isToday ? 12 : 0, vertical: isToday ? 4 : 0),
          decoration: isToday
              ? BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Text(
            date,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isToday ? FontWeight.w500 : FontWeight.w400,
              color: Colors.white.withValues(alpha: isToday ? 1.0 : 0.6),
            ),
          ),
        ),
      ],
    );
  }
''';

  final newDateSelector = '''
  Widget _buildDateSelector(BuildContext context, BellotaColors colors) {
    final now = DateTime.now();
    
    final List<String> monthNames = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final List<String> weekDays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

    String format(DateTime d) => '\ \';
    String formatDay(DateTime d) => weekDays[d.weekday - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(5, (index) {
            final date = now.add(Duration(days: index));
            final isSelected = _selectedOffset == index;
            final labelDay = index == 0 ? 'Hoy' : formatDay(date);
            
            return GestureDetector(
              onTap: () => _fetchPredictionForOffset(index),
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  children: [
                    Text(
                      labelDay,
                      style: TextStyle(
                        fontSize: isSelected ? 18 : 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 8, vertical: isSelected ? 4 : 4),
                      decoration: isSelected
                          ? BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                      child: Text(
                        format(date),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                          color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
''';

  // Replace UTF-8 strings accurately
  // A simple workaround for encoding issues in dart reading files:
  content = content.replaceAll(oldDateSelector, newDateSelector);

  // We only want to show registered symptoms if it is today!
  // Find if (widget.todaySymptoms.isEmpty) and change to if (_selectedOffset > 0) Text("Sin datos para este día futuro", ...) else if (widget.todaySymptoms.isEmpty)
  final oldSymptoms = '''
                if (widget.todaySymptoms.isEmpty)
                  Text(
                    AppLocalizations.of(context)!.symptomsAndActionsNoSymptomsLogged,
                    style: TextStyle(
                      color: colors.textoMedio,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (widget.todaySymptoms.isNotEmpty)
''';

  final newSymptoms = '''
                if (_selectedOffset > 0)
                  Text(
                    "No hay registros porque es un día futuro.",
                    style: TextStyle(
                      color: colors.textoMedio,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (widget.todaySymptoms.isEmpty)
                  Text(
                    AppLocalizations.of(context)!.symptomsAndActionsNoSymptomsLogged,
                    style: TextStyle(
                      color: colors.textoMedio,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (widget.todaySymptoms.isNotEmpty)
''';
  content = content.replaceAll(oldSymptoms, newSymptoms);
  
  // Wrap prediction content in _isLoading check
  content = content.replaceAll('if ((_predictions[_selectedOffset] ?? []).isEmpty)', 'if (_isLoading) const CircularProgressIndicator() else if ((_predictions[_selectedOffset] ?? []).isEmpty)');

  File('scratch/resumen_mod2.dart').writeAsStringSync(content);
}