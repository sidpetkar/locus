import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../state/calendar_state.dart';
import '../theme/app_theme.dart';
import 'settings_page.dart';

enum MoriFilter { lifetime, decade, year }

class MomentoMoriPage extends StatefulWidget {
  const MomentoMoriPage({Key? key}) : super(key: key);

  @override
  State<MomentoMoriPage> createState() => _MomentoMoriPageState();
}

class _MomentoMoriPageState extends State<MomentoMoriPage> {
  MoriFilter _filter = MoriFilter.lifetime;

  void _cycleFilter() {
    setState(() {
      _filter = MoriFilter.values[(_filter.index + 1) % MoriFilter.values.length];
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
            // Header: back button left, filter toggle right
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

            // Title: "Momento" bold + "Mori" light — matches home month label style
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Momento ',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: colors.labelPrimary,
                        height: 1.1,
                        letterSpacing: -2,
                      ),
                    ),
                    TextSpan(
                      text: 'Mori',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: colors.labelSecondary,
                        height: 1.1,
                        letterSpacing: -2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Body: dot grid or no-birthday prompt
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

  Widget _buildNoBirthdayPrompt(BuildContext context, AppColorTokens colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_bottom_rounded, size: 48, color: colors.labelTertiary),
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.labelPrimary,
                foregroundColor: colors.background,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                elevation: 0,
              ),
              child: Text(
                'Go to Settings',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotGrid(BuildContext context, DateTime birthday, AppColorTokens colors) {
    final now = DateTime.now();
    final totalWeeksLived = now.difference(birthday).inDays ~/ 7;

    switch (_filter) {
      case MoriFilter.lifetime:
        return _buildLifetimeGrid(totalWeeksLived, colors);
      case MoriFilter.decade:
        return _buildDecadeGrid(birthday, totalWeeksLived, colors);
      case MoriFilter.year:
        return _buildYearGrid(birthday, totalWeeksLived, colors);
    }
  }

  Widget _buildLifetimeGrid(int totalWeeksLived, AppColorTokens colors) {
    const int yearsTotal = 80;
    const int weeksPerYear = 52;
    const int totalDots = yearsTotal * weeksPerYear;
    final int filledDots = totalWeeksLived.clamp(0, totalDots);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(yearsTotal, (yearIdx) {
          final bool isDecadeStart = yearIdx > 0 && yearIdx % 10 == 0;
          final int weekOffset = yearIdx * weeksPerYear;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDecadeStart)
                const SizedBox(height: 16),
              _DotRow(
                count: weeksPerYear,
                filledCount: (filledDots - weekOffset).clamp(0, weeksPerYear),
                colors: colors,
              ),
              const SizedBox(height: 3),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDecadeGrid(DateTime birthday, int totalWeeksLived, AppColorTokens colors) {
    final int currentAge = _ageInYears(birthday);
    final int decadeStart = (currentAge ~/ 10) * 10;
    const int weeksPerYear = 52;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(10, (i) {
          final int yearOfLife = decadeStart + i;
          final int weekOffset = yearOfLife * weeksPerYear;
          final int filledInYear =
              (totalWeeksLived - weekOffset).clamp(0, weeksPerYear);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${yearOfLife + 1}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: colors.labelTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _DotRow(
                      count: weeksPerYear,
                      filledCount: filledInYear,
                      colors: colors,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildYearGrid(DateTime birthday, int totalWeeksLived, AppColorTokens colors) {
    final int currentAge = _ageInYears(birthday);
    final int weekOffset = currentAge * 52;
    const int weeksPerYear = 52;
    final int filledInYear =
        (totalWeeksLived - weekOffset).clamp(0, weeksPerYear);

    final int yearLabel = currentAge + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Year $yearLabel',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: colors.labelTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(4, (quarterIdx) {
            final int start = quarterIdx * 13;
            const int count = 13;
            final int filledInQuarter =
                (filledInYear - start).clamp(0, count);

            return Column(
              children: [
                _DotRow(count: count, filledCount: filledInQuarter, colors: colors),
                SizedBox(height: quarterIdx < 3 ? 14 : 0),
              ],
            );
          }),
        ],
      ),
    );
  }

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

// ── Dot row widget ────────────────────────────────────────────────────────────
class _DotRow extends StatelessWidget {
  final int count;
  final int filledCount;
  final AppColorTokens colors;

  const _DotRow({
    required this.count,
    required this.filledCount,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(count, (i) {
        final bool filled = i < filledCount;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: filled ? colors.dotFilled : colors.dotEmpty,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
