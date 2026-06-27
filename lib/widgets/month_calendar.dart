import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../theme/app_theme.dart';

/// Month grid (Stil A). Monday-first week, today/selected day shown as a filled
/// square, days with appointments marked by a dot. Cells are lazy-built and
/// cheap so scrolling/animating between months stays smooth.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.today,
    required this.markedDateKeys,
    required this.onSelectDay,
  });

  /// First day of the month being shown.
  final DateTime month;
  final DateTime selectedDate;
  final DateTime today;

  /// "yyyy-MM-dd" keys of days that have at least one appointment.
  final Set<String> markedDateKeys;
  final ValueChanged<DateTime> onSelectDay;

  static const List<String> _weekdayLabels = <String>[
    'Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz',
  ];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    // weekday: Mon=1 .. Sun=7 → blanks before the 1st in a Monday-first grid.
    final leadingBlanks = DateTime(month.year, month.month, 1).weekday - 1;
    final rowCount = ((leadingBlanks + daysInMonth) / 7).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(label, style: context.text.muted),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: rowCount * 7,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - leadingBlanks + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }
            final date = DateTime(month.year, month.month, dayNumber);
            return _DayCell(
              date: date,
              isToday: DateUtils.isSameDay(date, today),
              isSelected: DateUtils.isSameDay(date, selectedDate),
              isMarked: markedDateKeys.contains(Appointment.dateKeyFor(date)),
              onTap: () => onSelectDay(date),
            );
          },
        ),
      ],
    );
  }
}

/// One day square. Selected → filled accent; today → soft-blue; otherwise plain.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.isMarked,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool isMarked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color background;
    final Color numberColor;
    if (isSelected) {
      background = colors.primary;
      numberColor = colors.onPrimary;
    } else if (isToday) {
      background = colors.softBlue;
      numberColor = colors.primary;
    } else {
      background = Colors.transparent;
      numberColor = colors.textDark;
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.todayCell),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '${date.day}',
                style: context.text.name.copyWith(color: numberColor),
              ),
              if (isMarked)
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected ? colors.onPrimary : colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
