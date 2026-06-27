import 'package:flutter/foundation.dart';

/// Holds the calendar's view state: the month on screen and the selected day.
///
/// Kept deliberately small so listeners rebuild only on real changes. Dates are
/// normalized (month → first day, selection → date-only) so equality checks and
/// `dateKey` lookups are stable regardless of the time component.
class CalendarController extends ChangeNotifier {
  CalendarController({DateTime? today})
      : _visibleMonth = _firstOfMonth(today ?? DateTime.now()),
        _selectedDate = _dateOnly(today ?? DateTime.now());

  DateTime _visibleMonth;
  DateTime _selectedDate;

  /// First day of the month currently shown in the grid.
  DateTime get visibleMonth => _visibleMonth;

  /// The day whose appointments are listed below the grid.
  DateTime get selectedDate => _selectedDate;

  void nextMonth() => _setMonth(DateTime(_visibleMonth.year, _visibleMonth.month + 1));

  void previousMonth() =>
      _setMonth(DateTime(_visibleMonth.year, _visibleMonth.month - 1));

  /// Select [day]; also brings its month into view if it differs.
  void selectDay(DateTime day) {
    final date = _dateOnly(day);
    final month = _firstOfMonth(date);
    if (date == _selectedDate && month == _visibleMonth) return;
    _selectedDate = date;
    _visibleMonth = month;
    notifyListeners();
  }

  void _setMonth(DateTime month) {
    final normalized = _firstOfMonth(month);
    if (normalized == _visibleMonth) return;
    _visibleMonth = normalized;
    notifyListeners();
  }

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
