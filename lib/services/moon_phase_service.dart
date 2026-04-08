enum MoonPhase { newMoon, firstQuarter, fullMoon, lastQuarter }

class MoonPhaseService {
  static const double _synodicPeriod = 29.530588853;

  /// Known new moon: January 6, 2000 18:14 UTC
  static final DateTime _referenceNewMoon = DateTime.utc(2000, 1, 6, 18, 14);

  static const double _newMoonAge = 0.0;
  static const double _firstQuarterAge = _synodicPeriod * 0.25;
  static const double _fullMoonAge = _synodicPeriod * 0.5;
  static const double _lastQuarterAge = _synodicPeriod * 0.75;
  static final Map<String, Map<int, MoonPhase>> _monthCache = {};

  /// Returns one of the 4 principal phases for [date] if that day is selected
  /// as the nearest phase-day in its month.
  static MoonPhase? getPhase(DateTime date) {
    final key = '${date.year}-${date.month}';
    final monthMap = _monthCache.putIfAbsent(
      key,
      () => _buildMonthPhaseMap(date.year, date.month),
    );
    return monthMap[date.day];
  }

  /// Shortest distance around the cycle between two ages.
  static double _cyclicDistance(double a, double b) {
    final d = (a - b).abs();
    return d > _synodicPeriod / 2 ? _synodicPeriod - d : d;
  }

  static double _ageAtNoonUtc(int year, int month, int day) {
    final noon = DateTime.utc(year, month, day, 12);
    final daysSinceRef = noon.difference(_referenceNewMoon).inMinutes / 1440.0;
    final age = daysSinceRef % _synodicPeriod;
    return age < 0 ? age + _synodicPeriod : age;
  }

  static Map<int, MoonPhase> _buildMonthPhaseMap(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final targets = <MoonPhase, double>{
      MoonPhase.newMoon: _newMoonAge,
      MoonPhase.firstQuarter: _firstQuarterAge,
      MoonPhase.fullMoon: _fullMoonAge,
      MoonPhase.lastQuarter: _lastQuarterAge,
    };

    final phaseRank = <MoonPhase, int>{
      MoonPhase.newMoon: 0,
      MoonPhase.firstQuarter: 1,
      MoonPhase.fullMoon: 2,
      MoonPhase.lastQuarter: 3,
    };

    final candidates = <MoonPhase, List<_PhaseCandidate>>{};
    for (final entry in targets.entries) {
      final phase = entry.key;
      final target = entry.value;
      final list = <_PhaseCandidate>[];
      for (int day = 1; day <= daysInMonth; day++) {
        final age = _ageAtNoonUtc(year, month, day);
        list.add(_PhaseCandidate(day, _cyclicDistance(age, target)));
      }
      list.sort((a, b) => a.distance.compareTo(b.distance));
      candidates[phase] = list;
    }

    final phasesOrdered = <MoonPhase>[
      MoonPhase.newMoon,
      MoonPhase.firstQuarter,
      MoonPhase.fullMoon,
      MoonPhase.lastQuarter,
    ];
    phasesOrdered.sort((a, b) {
      final da = candidates[a]!.first.distance;
      final db = candidates[b]!.first.distance;
      final c = da.compareTo(db);
      if (c != 0) return c;
      return phaseRank[a]!.compareTo(phaseRank[b]!);
    });

    final usedDays = <int>{};
    final result = <int, MoonPhase>{};
    for (final phase in phasesOrdered) {
      for (final candidate in candidates[phase]!) {
        if (usedDays.add(candidate.day)) {
          result[candidate.day] = phase;
          break;
        }
      }
    }
    return result;
  }

  static Map<MoonPhase, int> getPhaseDaysForMonth(int year, int month) {
    final byDay = _buildMonthPhaseMap(year, month);
    final result = <MoonPhase, int>{};
    byDay.forEach((day, phase) {
      result[phase] = day;
    });
    if (result.length < 4) {
      for (int d = 1; d <= DateTime(year, month + 1, 0).day; d++) {
        final phase = byDay[d];
        if (phase != null) {
          result[phase] = d;
        }
      }
    }
    return result;
  }

  static String getAssetPath(MoonPhase phase, {required bool isDark}) {
    final suffix = isDark ? 'dm' : 'lm';
    switch (phase) {
      case MoonPhase.newMoon:
        return 'assets/nm-$suffix.png';
      case MoonPhase.firstQuarter:
        return 'assets/fq-$suffix.png';
      case MoonPhase.fullMoon:
        return 'assets/fm-$suffix.png';
      case MoonPhase.lastQuarter:
        return 'assets/lq-$suffix.png';
    }
  }
}

class _PhaseCandidate {
  const _PhaseCandidate(this.day, this.distance);
  final int day;
  final double distance;
}
