const fs = require('fs');
let content = fs.readFileSync('lib/screens/resumen_diario_screen.dart', 'utf8');

content = content.replace('class ResumenDiarioScreen extends StatelessWidget {', 'class ResumenDiarioScreen extends StatefulWidget {');

const newFields = 
  final int? userId;
  final String? contraceptive;
  final DateTime? lastPeriodStart;
  final int cycleDuration;
  final int periodDuration;;
content = content.replace('final List<ClinicalAlert>? activeAlerts;', 'final List<ClinicalAlert>? activeAlerts;' + newFields);

const oldConstructorEnd =     this.cycleInfo,
    this.activeAlerts,
  });;
const newConstructorEnd =     this.cycleInfo,
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
  };
content = content.replace(oldConstructorEnd, newConstructorEnd);

content = content.replace(/\bnextPeriodDate\b/g, 'widget.nextPeriodDate');
content = content.replace(/\bpredictedSymptoms\b/g, '(_predictions[_selectedOffset] ?? [])');
content = content.replace(/\btodaySymptoms\b/g, 'widget.todaySymptoms');
content = content.replace(/\btodayMood\b/g, 'widget.todayMood');
content = content.replace(/\bmedicalConditions\b/g, 'widget.medicalConditions');
content = content.replace(/\bcycleInfo\b/g, 'widget.cycleInfo');
content = content.replace(/\bcurrentPhaseIndex\b/g, '(_phases[_selectedOffset] ?? widget.currentPhaseIndex)');
content = content.replace(/\bactiveAlerts\b/g, 'widget.activeAlerts');

content = content.replace(/final DateTime widget\.nextPeriodDate;/, 'final DateTime nextPeriodDate;');
content = content.replace(/final List<String> \(\_predictions\[\_selectedOffset\] \?\? \[\]\);/, 'final List<String> predictedSymptoms;');
content = content.replace(/final List<String> widget\.todaySymptoms;/, 'final List<String> todaySymptoms;');
content = content.replace(/final String\? widget\.todayMood;/, 'final String? todayMood;');
content = content.replace(/final List<String> widget\.medicalConditions;/, 'final List<String> medicalConditions;');
content = content.replace(/final CycleInfo\? widget\.cycleInfo;/, 'final CycleInfo? cycleInfo;');
content = content.replace(/final int \(\_phases\[\_selectedOffset\] \?\? widget\.currentPhaseIndex\);/, 'final int currentPhaseIndex;');
content = content.replace(/final List<ClinicalAlert>\? widget\.activeAlerts;/, 'final List<ClinicalAlert>? activeAlerts;');

content = content.replace(/required this\.widget\.nextPeriodDate,/g, 'required this.nextPeriodDate,');
content = content.replace(/required this\.\(\_predictions\[\_selectedOffset\] \?\? \[\]\),/g, 'required this.predictedSymptoms,');
content = content.replace(/required this\.widget\.todaySymptoms,/g, 'required this.todaySymptoms,');
content = content.replace(/required this\.widget\.medicalConditions,/g, 'required this.medicalConditions,');
content = content.replace(/required this\.\(\_phases\[\_selectedOffset\] \?\? widget\.currentPhaseIndex\),/g, 'required this.currentPhaseIndex,');
content = content.replace(/this\.widget\.todayMood,/g, 'this.todayMood,');
content = content.replace(/this\.widget\.cycleInfo,/g, 'this.cycleInfo,');
content = content.replace(/this\.widget\.activeAlerts,/g, 'this.activeAlerts,');

const oldDateSelectorRegex = /Widget _buildDateSelector[\s\S]*?Widget _dateItem[\s\S]*?\}[\s\S]*?\}/;
const newDateSelector = 
  Widget _buildDateSelector(BuildContext context, BellotaColors colors) {
    final now = DateTime.now();
    
    final List<String> monthNames = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final List<String> weekDays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

    String format(DateTime d) => '\\\ \\\';
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
;
content = content.replace(oldDateSelectorRegex, newDateSelector);

const oldSymptomsCheck = if (widget.todaySymptoms.isEmpty)
                  Text(
                    AppLocalizations.of(context)!.symptomsAndActionsNoSymptomsLogged,
                    style: TextStyle(
                      color: colors.textoMedio,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (widget.todaySymptoms.isNotEmpty);
const newSymptomsCheck = if (_selectedOffset > 0)
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
                else if (widget.todaySymptoms.isNotEmpty);
content = content.replace(oldSymptomsCheck, newSymptomsCheck);

content = content.replace('if ((_predictions[_selectedOffset] ?? []).isEmpty)', 'if (_isLoading) const Center(child: CircularProgressIndicator()) else if ((_predictions[_selectedOffset] ?? []).isEmpty)');

fs.writeFileSync('lib/screens/resumen_diario_screen.dart', content);
console.log('Modified successfully.');