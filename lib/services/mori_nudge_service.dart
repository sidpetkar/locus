import 'dart:math';
import '../data/mori_nudges.dart';
import 'nudge_service.dart';

class MoriNudgeService {
  static const int _lifeYears = 80;
  static const int _weeksPerYear = 52;

  /// Returns resolved nudges for the given Memento Mori [filter] and user's
  /// [birthday]. Returns empty list if birthday is null.
  static List<ResolvedNudge> getNudges(String filter, DateTime? birthday) {
    if (birthday == null) return [];

    final now = DateTime.now();
    final age = _ageInYears(birthday, now);
    final totalWeeksLived = now.difference(birthday).inDays ~/ 7;
    final totalWeeks = _lifeYears * _weeksPerYear;
    final weeksLeft = (totalWeeks - totalWeeksLived).clamp(0, totalWeeks);
    final yearsLeft = (_lifeYears - age).clamp(0, _lifeYears);

    final decadeStart = (age ~/ 10) * 10;
    final decadeEnd = decadeStart + 9;
    final decadeEndWeek = (decadeEnd + 1) * _weeksPerYear;
    final decadeWeeksLeft = (decadeEndWeek - totalWeeksLived).clamp(0, 10 * _weeksPerYear);

    final yearWeekOffset = age * _weeksPerYear;
    final yearWeeksGone = (totalWeeksLived - yearWeekOffset).clamp(0, _weeksPerYear);
    final yearWeeksLeft = _weeksPerYear - yearWeeksGone;

    final eligible = kMoriNudgeTemplates.where((t) => t.filter == filter).toList();

    final resolved = eligible.map((t) {
      final text = t.template
          .replaceAll('{age}', age.toString())
          .replaceAll('{weeksLived}', totalWeeksLived.toString())
          .replaceAll('{weeksLeft}', weeksLeft.toString())
          .replaceAll('{yearsLeft}', yearsLeft.toString())
          .replaceAll('{decadeStart}', decadeStart.toString())
          .replaceAll('{decadeEnd}', decadeEnd.toString())
          .replaceAll('{decadeWeeksLeft}', decadeWeeksLeft.toString())
          .replaceAll('{yearWeeksGone}', yearWeeksGone.toString())
          .replaceAll('{yearWeeksLeft}', yearWeeksLeft.toString());

      return ResolvedNudge(_parseSpans(text));
    }).toList();

    resolved.shuffle(Random());
    return resolved;
  }

  static List<NudgeSpan> _parseSpans(String text) {
    final spans = <NudgeSpan>[];
    final regex = RegExp(r'\*([^*]+)\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(NudgeSpan(text: text.substring(lastEnd, match.start), bold: false));
      }
      spans.add(NudgeSpan(text: match.group(1)!, bold: true));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(NudgeSpan(text: text.substring(lastEnd), bold: false));
    }

    return spans;
  }

  static int _ageInYears(DateTime birthday, DateTime now) {
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age.clamp(0, 999);
  }
}
