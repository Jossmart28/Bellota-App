import 'dart:io';

void main() {
  final file = File('lib/screens/resumen_diario_screen.dart');
  String content = file.readAsStringSync();

  content = content.replaceFirst(
    'class ResumenDiarioScreen extends StatelessWidget {',
    'class ResumenDiarioScreen extends StatefulWidget {'
  );

  content = content.replaceFirst(
    'final List<ClinicalAlert>? activeAlerts;',
    '''final List<ClinicalAlert>? activeAlerts;
  final int? userId;
  final String? contraceptive;
  final DateTime? lastPeriodStart;
  final int cycleDuration;
  final int periodDuration;'''
  );

  final oldConstructorStart = 'const ResumenDiarioScreen({';
  final oldConstructorEnd = '  });';
  final startIdx = content.indexOf(oldConstructorStart);
  final endIdx = content.indexOf(oldConstructorEnd, startIdx) + oldConstructorEnd.length;
  
  final oldConstructor = content.substring(startIdx, endIdx);
  final newConstructor = '''const ResumenDiarioScreen({
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
  }''';

  content = content.replaceFirst(oldConstructor, newConstructor);

  final lastBraceIdx = content.lastIndexOf('}');
  content = content.substring(0, lastBraceIdx) + content.substring(lastBraceIdx + 1);

  final methodsStartIdx = content.indexOf('Color _phaseColor(BuildContext context)');
  String stateMethods = content.substring(methodsStartIdx);
  
  stateMethods = stateMethods.replaceAll(RegExp(r'\bcurrentPhaseIndex\b'), '(_phases[_selectedOffset] ?? widget.currentPhaseIndex)');
  stateMethods = stateMethods.replaceAll('predictedSymptoms.isEmpty', '(_predictions[_selectedOffset] ?? []).isEmpty');
  stateMethods = stateMethods.replaceAll('predictedSymptoms.length', '(_predictions[_selectedOffset] ?? []).length');
  stateMethods = stateMethods.replaceAll('predictedSymptoms[index]', '(_predictions[_selectedOffset] ?? [])[index]');
  stateMethods = stateMethods.replaceAll('predictedSymptoms.map', '(_predictions[_selectedOffset] ?? []).map');
  
  stateMethods = stateMethods.replaceAll(RegExp(r'\bnextPeriodDate\b'), 'widget.nextPeriodDate');
  stateMethods = stateMethods.replaceAll(RegExp(r'\btodaySymptoms\b'), 'widget.todaySymptoms');
  stateMethods = stateMethods.replaceAll(RegExp(r'\btodayMood\b'), 'widget.todayMood');
  stateMethods = stateMethods.replaceAll(RegExp(r'\bmedicalConditions\b'), 'widget.medicalConditions');
  stateMethods = stateMethods.replaceAll(RegExp(r'\bcycleInfo\b'), 'widget.cycleInfo');
  stateMethods = stateMethods.replaceAll(RegExp(r'\bactiveAlerts\b'), 'widget.activeAlerts');

  content = content.substring(0, methodsStartIdx) + stateMethods;

  final dateSelectorStart = content.indexOf('Widget _buildDateSelector');
  final tabsStart = content.indexOf('String _getMoodEmoji');
  final oldDateSelectorBlock = content.substring(dateSelectorStart, tabsStart);

  final newDateSelectorBlock = '''Widget _buildDateSelector(BuildContext context, BellotaColors colors) {
    final now = DateTime.now();
    
    final List<String> monthNames = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final List<String> weekDays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

    String format(DateTime d) => '\${d.day} \${monthNames[d.month - 1]}';
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

  content = content.replaceFirst(oldDateSelectorBlock, newDateSelectorBlock);

  content = content.replaceFirst(
    '''if (widget.todaySymptoms.isEmpty)
                  Text(
                    AppLocalizations.of(context)!.symptomsAndActionsNoSymptomsLogged,''',
    '''if (_selectedOffset > 0)
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
                    AppLocalizations.of(context)!.symptomsAndActionsNoSymptomsLogged,'''
  );

  content = content.replaceFirst(
    'if (widget.todaySymptoms.isNotEmpty)',
    'if (widget.todaySymptoms.isNotEmpty && _selectedOffset == 0)'
  );

  content = content.replaceFirst(
    'if ((_predictions[_selectedOffset] ?? []).isEmpty)',
    'if (_isLoading) const Center(child: CircularProgressIndicator()) else if ((_predictions[_selectedOffset] ?? []).isEmpty)'
  );

  content = content.replaceFirst(
    "import '../widgets/bellota_empty_state.dart';",
    "import '../widgets/bellota_empty_state.dart';\nimport '../database/database_helper.dart';"
  );

  content = content + '\n}\n';
  file.writeAsStringSync(content);
}