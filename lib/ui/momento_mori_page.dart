import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/mori_nudge_service.dart';
import '../state/calendar_state.dart';
import '../theme/app_theme.dart';
import 'settings_page.dart';
import 'widgets/animated_headline.dart';

enum MoriFilter { lifetime, decade, year }

class MomentoMoriPage extends StatefulWidget {
  const MomentoMoriPage({Key? key}) : super(key: key);

  @override
  State<MomentoMoriPage> createState() => _MomentoMoriPageState();
}

class _MomentoMoriPageState extends State<MomentoMoriPage> {
  MoriFilter _filter = MoriFilter.lifetime;

  static const int _lifeYears = 80;
  static const int _weeksPerYear = 52;
  static const double _gapRatio = 0.4;

  void _cycleFilter() {
    setState(() {
      _filter = MoriFilter
          .values[(_filter.index + 1) % MoriFilter.values.length];
    });
  }

  String get _filterLabel {
    switch (_filter) {
      case MoriFilter.lifetime:
        return 'Lifetime';
      case MoriFilter.decade:
        return 'Decade';
      case MoriFilter.year:
        return 'Year';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalendarStateProvider>(context);
    final birthday = provider.birthday;
    final colors = context.appColors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, size: 28, color: colors.icon),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  GestureDetector(
                    onTap: _cycleFilter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        _filterLabel,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colors.labelPrimary,
                          decoration: TextDecoration.underline,
                          decorationColor: colors.labelPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedHeadline(
                key: ValueKey(_filter),
                titleBold: 'Momento ',
                titleLight: 'Mori',
                nudges: MoriNudgeService.getNudges(
                  _filter.name,
                  birthday,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: birthday == null
                  ? _buildNoBirthdayPrompt(context, colors)
                  : _buildDotGrid(context, birthday, colors),
            ),
          ],
        ),
      ),
    );
  }

  // ── No birthday prompt ────────────────────────────────────────────────────

  Widget _buildNoBirthdayPrompt(BuildContext context, AppColorTokens colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_bottom_rounded,
                size: 48, color: colors.labelTertiary),
            const SizedBox(height: 20),
            Text(
              'Set your birthday to see your life in weeks.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                color: colors.labelSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.labelPrimary,
                foregroundColor: colors.background,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                elevation: 0,
              ),
              child: Text(
                'Go to Settings',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grid router ───────────────────────────────────────────────────────────

  Widget _buildDotGrid(
      BuildContext context, DateTime birthday, AppColorTokens colors) {
    final totalWeeksLived = DateTime.now().difference(birthday).inDays ~/ 7;

    switch (_filter) {
      case MoriFilter.lifetime:
        return _buildLifetimeGrid(totalWeeksLived, colors);
      case MoriFilter.decade:
        return _buildDecadeGrid(birthday, totalWeeksLived, colors);
      case MoriFilter.year:
        return _buildYearGrid(birthday, totalWeeksLived, colors);
    }
  }

  // ── LIFETIME ──────────────────────────────────────────────────────────────
  // 80 rows of 52 dots. Extra vertical gap every 10 rows (decade separator).

  Widget _buildLifetimeGrid(int totalWeeksLived, AppColorTokens colors) {
    const int total = _lifeYears * _weeksPerYear;
    final int filled = totalWeeksLived.clamp(0, total);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth - 48; // 24px padding each side
        final double dotSize =
            width / (_weeksPerYear + (_weeksPerYear - 1) * _gapRatio);
        final double rowGap = dotSize * _gapRatio;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: List.generate(_lifeYears, (yearIdx) {
                final int offset = yearIdx * _weeksPerYear;
                final int filledInRow =
                    (filled - offset).clamp(0, _weeksPerYear);
                final bool decadeBreak =
                    yearIdx > 0 && yearIdx % 10 == 0;

                return Padding(
                  padding: EdgeInsets.only(
                    top: decadeBreak ? 12.0 : 0,
                    bottom: rowGap,
                  ),
                  child: _dotRow(
                    dotSize: dotSize,
                    count: _weeksPerYear,
                    filledCount: filledInRow,
                    colors: colors,
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  // ── DECADE ────────────────────────────────────────────────────────────────
  // 10 rows of 52 dots for the user's current decade of life.
  // Each row has an age label on the left.

  Widget _buildDecadeGrid(
      DateTime birthday, int totalWeeksLived, AppColorTokens colors) {
    final int age = _ageInYears(birthday);
    final int decadeStart = (age ~/ 10) * 10;

    return LayoutBuilder(
      builder: (context, constraints) {
        const double labelWidth = 28;
        const double labelGap = 6;
        final double dotsWidth =
            constraints.maxWidth - 48 - labelWidth - labelGap;
        final double dotSize =
            dotsWidth / (_weeksPerYear + (_weeksPerYear - 1) * _gapRatio);
        final double rowGap = dotSize * _gapRatio;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: List.generate(10, (i) {
                final int yearAge = decadeStart + i;
                final int weekOffset = yearAge * _weeksPerYear;
                final int filledInRow =
                    (totalWeeksLived - weekOffset).clamp(0, _weeksPerYear);

                return Padding(
                  padding: EdgeInsets.only(bottom: rowGap + 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: Text(
                          '$yearAge',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            color: yearAge == age
                                ? colors.labelPrimary
                                : colors.labelTertiary,
                            fontWeight: yearAge == age
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: labelGap),
                      Expanded(
                        child: _dotRow(
                          dotSize: dotSize,
                          count: _weeksPerYear,
                          filledCount: filledInRow,
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  // ── YEAR ──────────────────────────────────────────────────────────────────
  // 52 dots for the current year of life, arranged in 4 rows of 13 (quarters).

  Widget _buildYearGrid(
      DateTime birthday, int totalWeeksLived, AppColorTokens colors) {
    final int age = _ageInYears(birthday);
    final int weekOffset = age * _weeksPerYear;
    final int filledInYear =
        (totalWeeksLived - weekOffset).clamp(0, _weeksPerYear);
    const int dotsPerRow = 13;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth - 48;
        final double dotSize =
            width / (dotsPerRow + (dotsPerRow - 1) * _gapRatio);
        final double rowGap = dotSize * 0.6;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Age $age',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: colors.labelTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(4, (qIdx) {
                final int start = qIdx * dotsPerRow;
                final int filledInQ =
                    (filledInYear - start).clamp(0, dotsPerRow);

                return Padding(
                  padding: EdgeInsets.only(bottom: qIdx < 3 ? rowGap + 8 : 0),
                  child: _dotRow(
                    dotSize: dotSize,
                    count: dotsPerRow,
                    filledCount: filledInQ,
                    colors: colors,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── Shared dot row ────────────────────────────────────────────────────────
  // Renders [count] circles distributed evenly across the available width.

  Widget _dotRow({
    required double dotSize,
    required int count,
    required int filledCount,
    required AppColorTokens colors,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(count, (i) {
        return SizedBox(
          width: dotSize,
          height: dotSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: i < filledCount ? colors.dotFilled : colors.dotEmpty,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }

  // ── Age calculation ───────────────────────────────────────────────────────

  int _ageInYears(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age.clamp(0, 999);
  }
}
