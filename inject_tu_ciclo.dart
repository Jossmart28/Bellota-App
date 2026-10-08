import 'dart:io';

void main() {
  final path = 'lib/presentation/screens/home/dashboard_screen.dart';
  final content = File(path).readAsStringSync();

  // ── 1. Add _CycleBar model class at the very end (before last closing brace isn't needed,
  //       we append it after the last class)
  // ── 2. Insert _buildTuCicloCard method just before "_buildResumenCard"

  // Find insertion point: the method signature for _buildResumenCard
  const marker = '  Widget _buildResumenCard(BuildContext context, _PhaseData phase) {';
  final idx = content.indexOf(marker);
  if (idx == -1) {
    print('ERROR: marker not found');
    return;
  }

  // Build the new method to insert
  final tuCicloMethod = r'''
  // ─────────────────────────────────────────────────────────────
  // TU CICLO CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildTuCicloCard(BuildContext context) {
    final colors = Theme.of(context).bellotaColors;
    final sorted = List<DateTime>.from(_allPeriodStarts)..sort();
    final hasEnoughData = sorted.length >= 2;

    final List<_CycleBar> bars = [];
    for (int i = 0; i < sorted.length - 1; i++) {
      final len = sorted[i + 1].difference(sorted[i]).inDays;
      if (len > 5 && len < 65) {
        bars.add(_CycleBar(date: sorted[i], length: len, isCurrent: false, isEstimate: false));
      }
    }

    if (sorted.isNotEmpty) {
      final lastStart = sorted.last;
      final currentLen = _cycleInfo?.cycleDay ?? DateTime.now().difference(lastStart).inDays + 1;
      bars.add(_CycleBar(date: lastStart, length: currentLen, isCurrent: true, isEstimate: !hasEnoughData));
    } else {
      bars.add(_CycleBar(date: DateTime.now(), length: _cycleDuration, isCurrent: true, isEstimate: true));
    }

    final int maxVal = bars.isEmpty ? 40 : bars.map((b) => b.length).reduce((a, b) => a > b ? a : b);
    final int chartMax = ((maxVal / 10).ceil() * 10).clamp(35, 60);
    const normalMin = 21;
    const normalMax = 35;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colors.chilero.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          BellotaIcon(color: colors.chilero, size: 22),
          const SizedBox(width: 10),
          Text('Regularidad del ciclo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Outfit', color: colors.textoDark)),
        ]),
        const SizedBox(height: 16),
        Container(
          height: 40,
          decoration: BoxDecoration(color: colors.basilica, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Expanded(child: Container(
              decoration: BoxDecoration(color: colors.chilero, borderRadius: BorderRadius.circular(20)),
              alignment: Alignment.center,
              child: const Text('Historial', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Outfit')),
            )),
            Expanded(child: Center(child: Text('Ciclo actual', style: TextStyle(color: colors.textoMedio, fontWeight: FontWeight.w500, fontSize: 14)))),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: LayoutBuilder(builder: (context, constraints) {
            final visibleBars = bars.length > 6 ? bars.sublist(bars.length - 6) : bars;
            const chartHeight = 120.0;
            final bandTop = chartHeight * (1 - normalMax / chartMax);
            final bandBot = chartHeight * (1 - normalMin / chartMax);
            return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              SizedBox(width: 28, height: chartHeight + 20,
                child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('$chartMax', style: TextStyle(fontSize: 9, color: colors.textoMedio)),
                  Text('${chartMax ~/ 2}', style: TextStyle(fontSize: 9, color: colors.textoMedio)),
                  Text('0', style: TextStyle(fontSize: 9, color: colors.textoMedio)),
                ]),
              ),
              const SizedBox(width: 8),
              Expanded(child: Stack(clipBehavior: Clip.none, children: [
                Positioned(top: bandTop, height: (bandBot - bandTop).abs(), left: 0, right: 0,
                  child: Container(decoration: BoxDecoration(color: colors.textoMedio.withOpacity(0.1), borderRadius: BorderRadius.circular(4)))),
                Positioned.fill(child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: visibleBars.map((bar) {
                    final barH = (chartHeight * bar.length / chartMax).clamp(8.0, chartHeight);
                    final monthNames = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
                    final dateLabel = '${bar.date.day}/${monthNames[bar.date.month - 1]}';
                    return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text('${bar.length}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                        color: bar.isCurrent ? colors.chilero : colors.textoMedio)),
                      const SizedBox(height: 2),
                      Container(
                        width: 28, height: barH,
                        decoration: bar.isCurrent
                          ? BoxDecoration(border: Border.all(color: colors.chilero, width: 1.5), borderRadius: BorderRadius.circular(6))
                          : BoxDecoration(borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(colors: [colors.chilero.withOpacity(0.2), colors.chilero.withOpacity(0.5)],
                                begin: Alignment.topLeft, end: Alignment.bottomRight)),
                        child: bar.isCurrent ? Center(child: BellotaIcon(color: colors.chilero, size: 12)) : null,
                      ),
                      const SizedBox(height: 4),
                      Text(bar.isCurrent ? 'Actual' : '', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                        color: bar.isCurrent ? colors.chilero : Colors.transparent)),
                      Text(dateLabel, style: TextStyle(fontSize: 9, color: colors.textoMedio)),
                      if (bar.isEstimate) Text('est.', style: TextStyle(fontSize: 8, color: colors.textoMedio.withOpacity(0.6))),
                    ]));
                  }).toList(),
                )),
              ])),
            ]);
          }),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Container(width: 16, height: 10, decoration: BoxDecoration(color: colors.textoMedio.withOpacity(0.2), borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text('Rango normal 21-35 días', style: TextStyle(fontSize: 11, color: colors.textoMedio)),
          const SizedBox(width: 14),
          Container(width: 14, height: 14,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colors.textoMedio, width: 1.2)),
            child: const Center(child: Icon(Icons.refresh_rounded, size: 8, color: Colors.grey))),
          const SizedBox(width: 6),
          Text('En curso', style: TextStyle(fontSize: 11, color: colors.textoMedio)),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.basilica, borderRadius: BorderRadius.circular(16)),
          child: hasEnoughData
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_cycleInfo?.isIrregular == true ? 'Tu ciclo es irregular' : 'Tu ciclo es regular',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Outfit', color: colors.textoDark)),
                const SizedBox(height: 6),
                Text(_cycleInfo?.isIrregular == true
                  ? 'Tu ciclo varía más de 7 días entre períodos. Consulta a tu médico si es reciente.'
                  : 'Con ${sorted.length} ciclos registrados, tu promedio es de ${_cycleInfo?.averageCycleLength?.toStringAsFixed(0) ?? _cycleDuration} días.',
                  style: TextStyle(fontSize: 13, color: colors.textoMedio, height: 1.4)),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Aún no hay suficientes ciclos',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Outfit', color: colors.textoDark)),
                const SizedBox(height: 6),
                Text('La barra rayada es una estimación con los $_cycleDuration días que indicaste. Con los inicios de tus últimos 3 meses podremos medir tu regularidad real.',
                  style: TextStyle(fontSize: 13, color: colors.textoMedio, height: 1.4)),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedNavIndex = 1),
                    icon: const Icon(Icons.calendar_month_rounded, size: 16),
                    label: const Text('Marcar mis últimos períodos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.chilero, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Outfit'),
                    ),
                  ),
                ),
              ]),
        ),
      ]),
    );
  }

''';

  // Insert before the marker
  final newContent = content.substring(0, idx) + tuCicloMethod + content.substring(idx);
  File(path).writeAsStringSync(newContent);
  print('Inserted _buildTuCicloCard successfully at index $idx');

  // ── 3. Append _CycleBar model at the end of the file ──
  final dashPath = path;
  var dashContent = File(dashPath).readAsStringSync();
  
  const cycleBarModel = '''

// ─────────────────────────────────────────────────────────────
// Data model for Tu ciclo bar chart
// ─────────────────────────────────────────────────────────────
class _CycleBar {
  final DateTime date;
  final int length;
  final bool isCurrent;
  final bool isEstimate;
  const _CycleBar({required this.date, required this.length, required this.isCurrent, required this.isEstimate});
}
''';

  if (!dashContent.contains('class _CycleBar')) {
    dashContent += cycleBarModel;
    File(dashPath).writeAsStringSync(dashContent);
    print('Appended _CycleBar model');
  } else {
    print('_CycleBar already exists');
  }
}
