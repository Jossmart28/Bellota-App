import 'dart:io';

void main() {
  final file = File('lib/screens/calendar_screen.dart');
  String content = file.readAsStringSync();

  final targetContent = '''  Widget _buildCalendarContent() {
    switch (_currentView) {
      case CalendarViewType.weekly:
        return _buildWeeklyView();
      case CalendarViewType.monthly:
        return _buildMonthlySwipeable();
      case CalendarViewType.annual:
        return _buildAnnualView();
    }
  }''';

  final replaceContent = '''  Widget _buildCalendarContent() {
    switch (_currentView) {
      case CalendarViewType.weekly:
      case CalendarViewType.monthly:
        return _buildTableCalendar();
      case CalendarViewType.annual:
        return _buildAnnualView();
    }
  }

  Widget _buildTableCalendar() {
    final format = _currentView == CalendarViewType.weekly 
        ? CalendarFormat.week 
        : CalendarFormat.month;
        
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: TableCalendar(
        firstDay: DateTime(_currentDate.year - 5),
        lastDay: DateTime(_currentDate.year + 5),
        focusedDay: _displayDate,
        calendarFormat: format,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        headerVisible: false,
        daysOfWeekVisible: true,
        daysOfWeekHeight: 40,
        availableGestures: AvailableGestures.horizontalSwipe,
        onPageChanged: (focusedDay) {
          setState(() {
            _displayDate = focusedDay;
          });
        },
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            final text = _dayNames[day.weekday == 7 ? 0 : day.weekday];
            return Center(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).bellotaColors.chilero, 
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Text(text, style: TextStyle(color: Theme.of(context).bellotaColors.blanco, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            );
          },
          defaultBuilder: (context, day, focusedDay) => _buildDayCell(day),
          selectedBuilder: (context, day, focusedDay) => _buildDayCell(day),
          todayBuilder: (context, day, focusedDay) => _buildDayCell(day),
          outsideBuilder: (context, day, focusedDay) {
            return Opacity(
              opacity: 0.5,
              child: _buildDayCell(day),
            );
          },
        ),
      ),
    );
  }''';

  content = content.replaceFirst(targetContent, replaceContent);
  file.writeAsStringSync(content);
}
