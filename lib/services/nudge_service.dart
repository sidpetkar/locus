import 'dart:math';
import '../data/nudges.dart';

/// A single styled span within a resolved nudge — either bold or normal weight.
class NudgeSpan {
  final String text;
  final bool bold;

  const NudgeSpan({required this.text, required this.bold});
}

/// A fully-resolved nudge ready for rendering — a list of styled spans.
class ResolvedNudge {
  final List<NudgeSpan> spans;

  const ResolvedNudge(this.spans);

  /// The raw combined text (for line-count detection).
  String get rawText => spans.map((s) => s.text).join();
}

class NudgeService {
  /// Returns a list of resolved nudges appropriate for the given [year]/[month].
  /// Returns empty list if not the current month/year (no nudges for past/future).
  static List<ResolvedNudge> getNudgesForNow(int year, int month) {
    final now = DateTime.now();

    // Only cycle nudges on the current month view
    if (year != now.year || month != now.month) return [];

    final eligible = _filterByContext(now, year, month);
    final resolved = eligible.map((t) => _resolve(t, now, year, month)).toList();
    // Shuffle so nudges appear in random order each session
    resolved.shuffle(Random());
    return resolved;
  }

  // -------------------------------------------------------------------------
  // Context filtering
  // -------------------------------------------------------------------------

  static List<NudgeTemplate> _filterByContext(
      DateTime now, int year, int month) {
    final hour = now.hour;
    final weekday = now.weekday; // 1=Mon, 7=Sun
    final day = now.day;

    return kNudgeTemplates.where((t) {
      if (t.contexts.contains('always')) return true;

      for (final ctx in t.contexts) {
        switch (ctx) {
          case 'morning':
            if (hour >= 5 && hour < 12) return true;
            break;
          case 'afternoon':
            if (hour >= 12 && hour < 18) return true;
            break;
          case 'evening':
            if (hour >= 18 && hour < 22) return true;
            break;
          case 'night':
            if (hour >= 22 || hour < 5) return true;
            break;
          case 'weekday':
            if (weekday >= 1 && weekday <= 5) return true;
            break;
          case 'weekend':
            if (weekday == 6 || weekday == 7) return true;
            break;
          case 'pre_weekend':
            if (weekday == 5) return true;
            break;
          case 'pre_monday':
            if (weekday == 7) return true;
            break;
          case 'month_start':
            if (day <= 7) return true;
            break;
          case 'month_mid':
            if (day >= 8 && day <= 22) return true;
            break;
          case 'month_end':
            if (day >= 23) return true;
            break;
          case 'year_end':
            if (month >= 10) return true;
            break;
        }
      }
      // If none of the specific contexts matched, exclude
      return false;
    }).toList();
  }

  // -------------------------------------------------------------------------
  // Placeholder resolution
  // -------------------------------------------------------------------------

  static ResolvedNudge _resolve(
      NudgeTemplate template, DateTime now, int year, int month) {
    final daysInMonth = _daysInMonth(year, month);
    final daysLeft = daysInMonth - now.day + 1;
    final daysGone = now.day - 1;

    // Hours left until end of month
    final endOfMonth = DateTime(year, month, daysInMonth, 23, 59, 59);
    final hoursLeft = endOfMonth.difference(now).inHours;

    final weeksLeft = (daysLeft / 7).ceil();
    final monthsLeft = 12 - month;

    final monthName = _monthName(month);
    final dayOfWeek = _dayName(now.weekday);
    final nextDay = _dayName(now.weekday % 7 + 1);
    final timeOfDay = _timeOfDay(now.hour);

    String text = template.template
        .replaceAll('{month}', monthName)
        .replaceAll('{year}', year.toString())
        .replaceAll('{daysLeft}', daysLeft.toString())
        .replaceAll('{hoursLeft}', hoursLeft.toString())
        .replaceAll('{dayOfWeek}', dayOfWeek)
        .replaceAll('{nextDay}', nextDay)
        .replaceAll('{dayNumber}', now.day.toString())
        .replaceAll('{daysGone}', daysGone.toString())
        .replaceAll('{weeksLeft}', weeksLeft.toString())
        .replaceAll('{monthsLeft}', monthsLeft.toString())
        .replaceAll('{timeOfDay}', timeOfDay);

    return ResolvedNudge(_parseSpans(text));
  }

  // -------------------------------------------------------------------------
  // Bold markup parser: *text* → bold span
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month];
  }

  static String _dayName(int weekday) {
    const names = [
      '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return names[weekday];
  }

  static String _timeOfDay(int hour) {
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 18) return 'Afternoon';
    if (hour >= 18 && hour < 22) return 'Evening';
    return 'Night';
  }
}
