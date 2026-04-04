import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/calendar_state.dart';
import 'date_cell.dart';

class VerticalMonthGrid extends StatelessWidget {
  final int year;
  final int month;

  const VerticalMonthGrid({Key? key, required this.year, required this.month}) : super(key: key);

  int _getDaysInMonth(int year, int month) {
    if (month == 12) {
      return DateTime(year + 1, 1, 0).day;
    }
    return DateTime(year, month + 1, 0).day;
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime?> dayGrid = List.filled(35, null);
    
    // DateTime.weekday returns 1 for Monday, 7 for Sunday.
    // We adjust it to 0 for Sunday, 1 for Monday... 6 for Saturday using modulo.
    int firstDayOffset = DateTime(year, month, 1).weekday % 7;
    int days = _getDaysInMonth(year, month);

    for (int d = 1; d <= days; d++) {
      int pos = (firstDayOffset + d - 1) % 35;
      dayGrid[pos] = DateTime(year, month, d);
    }

    return Row(
      children: List.generate(5, (c) {
        return Expanded(
          child: Column(
            children: List.generate(7, (r) {
              int index = c * 7 + r;
              DateTime? day = dayGrid[index];
              return Expanded(
                child: DateCell(date: day),
              );
            }),
          ),
        );
      }),
    );
  }
}
