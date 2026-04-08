import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/moon_phase_service.dart';
import '../../state/calendar_state.dart';
import '../../models/memory_item.dart';
import '../../theme/app_theme.dart';
import '../day_memory_page.dart';

class DateCell extends StatefulWidget {
  final DateTime? date;
  final int? monthYear;
  final int? monthMonth;
  final bool emptyIsBeforeMonth;

  const DateCell({
    Key? key,
    this.date,
    this.monthYear,
    this.monthMonth,
    this.emptyIsBeforeMonth = true,
  }) : super(key: key);

  @override
  State<DateCell> createState() => _DateCellState();
}

class _DateCellState extends State<DateCell> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _moonController;
  Timer? _minuteTimer;
  Timer? _moonHoldTimer;
  MoonPhase? _moonPhase;
  bool _showingMoon = false;

  static const _moonHoldDuration = Duration(seconds: 12);
  static const _moonInitialDelay = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _moonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _moonPhase = widget.date != null
        ? MoonPhaseService.getPhase(widget.date!)
        : null;
    if (_moonPhase != null) {
      _moonController.addStatusListener(_onMoonAnimDone);
      _moonHoldTimer = Timer(_moonInitialDelay, _triggerMoonSlide);
    }
  }

  void _triggerMoonSlide() {
    if (!mounted) return;
    _moonController.forward(from: 0.0);
  }

  void _onMoonAnimDone(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _showingMoon = !_showingMoon;
    _moonController.reset();
    setState(() {});
    _moonHoldTimer?.cancel();
    _moonHoldTimer = Timer(_moonHoldDuration, _triggerMoonSlide);
  }

  void _ensureMinuteTimer(bool shouldRun) {
    if (shouldRun && _minuteTimer == null) {
      _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!shouldRun && _minuteTimer != null) {
      _minuteTimer!.cancel();
      _minuteTimer = null;
    }
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    _moonHoldTimer?.cancel();
    if (_moonPhase != null) {
      _moonController.removeStatusListener(_onMoonAnimDone);
    }
    _pulseController.dispose();
    _moonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.date == null) {
      final provider = context.watch<CalendarStateProvider>();
      if (provider.isTimeAwareMode && widget.monthYear != null && widget.monthMonth != null) {
        final now = DateTime.now();
        final isPastMonth = widget.monthYear! < now.year ||
            (widget.monthYear! == now.year && widget.monthMonth! < now.month);
        final isFutureMonth = widget.monthYear! > now.year ||
            (widget.monthYear! == now.year && widget.monthMonth! > now.month);

        final bool showDark;
        if (isPastMonth) {
          showDark = true;
        } else if (isFutureMonth) {
          showDark = false;
        } else {
          // Current month: before day 1 = past (dark), after last day = future (light)
          showDark = widget.emptyIsBeforeMonth;
        }
        return Container(color: showDark ? darkTokens.background : lightTokens.background);
      }
      return Container(
        decoration: const BoxDecoration(border: Border.fromBorderSide(BorderSide(color: Colors.transparent))),
      );
    }

    final provider = context.watch<CalendarStateProvider>();
    final dayData = provider.getDayData(widget.date!);
    final hasMemories = dayData.memories.isNotEmpty;
    final colors = context.appColors;
    final isTimeAware = provider.isTimeAwareMode;

    if (provider.pulseDate.value == widget.date) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pulseController.forward(from: 0).then((_) {
            _pulseController.forward(from: 0).then((_) {
              _pulseController.forward(from: 0);
            });
          });
          provider.pulseDate.value = null;
        }
      });
    }

    final now = DateTime.now();
    final isToday = widget.date!.year == now.year &&
                    widget.date!.month == now.month &&
                    widget.date!.day == now.day;

    // Manage timer: only tick when this IS today AND time-aware mode
    _ensureMinuteTimer(isTimeAware && isToday);

    // Resolve per-cell colors for time-aware mode
    AppColorTokens cellColors;
    if (isTimeAware) {
      final todayMidnight = DateTime(now.year, now.month, now.day);
      if (isToday) {
        cellColors = lightTokens; // base layer is light; dark overlay is clipped on top
      } else if (widget.date!.isBefore(todayMidnight)) {
        cellColors = darkTokens;
      } else {
        cellColors = lightTokens;
      }
    } else {
      cellColors = colors;
    }

    final bool isDarkCell;
    if (isTimeAware) {
      isDarkCell = cellColors == darkTokens;
    } else {
      isDarkCell = Theme.of(context).brightness == Brightness.dark;
    }

    final heroTag = 'day_cell_${widget.date!.year}_${widget.date!.month}_${widget.date!.day}';
    final imageItems = dayData.memories
        .where((m) => m.type == MemoryType.image || m.type == MemoryType.video)
        .take(3)
        .toList();
    final items = imageItems.isNotEmpty ? imageItems : dayData.memories.take(3).toList();

    Widget cellContent = _buildCellContent(
      cellColors: cellColors,
      isToday: isToday,
      hasMemories: hasMemories,
      items: items,
      isDark: isDarkCell,
    );

    // Time-aware today: progressive fill (dark overlay clipped from top)
    if (isTimeAware && isToday) {
      final dayProgress = (now.hour * 60 + now.minute) / 1440.0;

      final darkContent = _buildCellContent(
        cellColors: darkTokens,
        isToday: true,
        hasMemories: hasMemories,
        items: items,
        isDark: true,
      );

      cellContent = Stack(
        children: [
          // Bottom: full light cell
          cellContent,
          // Top: dark cell clipped to progress fraction from top
          ClipRect(
            clipper: _TopFractionClipper(dayProgress),
            child: darkContent,
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            reverseTransitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) {
              return DayMemoryPage(date: widget.date!, heroTag: heroTag);
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      onDoubleTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (context, animation, secondaryAnimation) {
              return DayMemoryPage(
                date: widget.date!,
                heroTag: heroTag,
                openGalleryOnLoad: true,
              );
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: Material(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                children: [
                  child!,
                  if (_pulseController.isAnimating)
                    Positioned.fill(
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment(-1.5 + (_pulseController.value * 3), -1.0),
                            end: Alignment(-0.5 + (_pulseController.value * 3), 1.0),
                            colors: [
                              Colors.transparent,
                              cellColors.labelPrimary.withOpacity(0.15),
                              Colors.transparent
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcOver,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                ],
              );
            },
            child: cellContent,
          ),
        ),
      ),
    );
  }

  Widget _buildDayNumber(AppColorTokens cellColors, bool isToday) {
    return SizedBox(
      height: 20,
      child: Text(
        '${widget.date!.day}',
        style: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 0,
          color: widget.date!.weekday == 7
              ? Colors.red
              : (isToday ? cellColors.labelPrimary : cellColors.labelSecondary),
          decoration: isToday ? TextDecoration.underline : null,
          decorationColor: cellColors.labelPrimary,
          decorationThickness: 2.5,
        ),
      ),
    );
  }

  Widget _buildMoonSvg(bool isDark) {
    final svgPath = MoonPhaseService.getAssetPath(_moonPhase!, isDark: isDark);
    return Image.asset(
      svgPath,
      height: 20,
      width: 20,
      fit: BoxFit.contain,
    );
  }

  Widget _buildMoonTransition(AppColorTokens cellColors, bool isToday, bool isDark) {
    final Widget outgoing = _showingMoon
        ? _buildMoonSvg(isDark)
        : _buildDayNumber(cellColors, isToday);
    final Widget incoming = _showingMoon
        ? _buildDayNumber(cellColors, isToday)
        : _buildMoonSvg(isDark);

    return SizedBox(
      height: 20,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _moonController,
          builder: (context, _) {
            final t = Curves.easeInOutCubic.transform(_moonController.value);
            return Stack(
              children: [
                FractionalTranslation(
                  translation: Offset(0, -t),
                  child: outgoing,
                ),
                if (_moonController.isAnimating)
                  FractionalTranslation(
                    translation: Offset(0, 1.0 - t),
                    child: incoming,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCellContent({
    required AppColorTokens cellColors,
    required bool isToday,
    required bool hasMemories,
    required List<MemoryItem> items,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cellColors.background,
        border: isToday
            ? Border.all(color: cellColors.labelPrimary, width: 2.5)
            : Border.all(color: cellColors.divider, width: 0.5),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: _moonPhase != null
                ? _buildMoonTransition(cellColors, isToday, isDark)
                : _buildDayNumber(cellColors, isToday),
          ),
          if (hasMemories)
            Positioned(
              bottom: 4,
              right: 4,
              child: SizedBox(
                width: 32 + ((items.length - 1) * 18.0),
                height: 48,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: List.generate(items.length, (index) {
                    int physicalIndex = items.length - 1 - index;
                    final m = items[physicalIndex];

                    return Positioned(
                      left: physicalIndex * 18.0,
                      child: Container(
                        width: 32,
                        height: 48,
                        decoration: BoxDecoration(
                          color: cellColors.surfaceVariant,
                          border: Border.all(color: cellColors.background, width: 3.0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: m.type == MemoryType.image
                              ? _buildThumbnail(m.content, cellColors)
                              : Center(child: Icon(Icons.videocam, size: 16, color: cellColors.labelSecondary)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildThumbnail(String content, AppColorTokens colors) {
    final isNetwork = content.startsWith('http') || content.startsWith('blob:');

    if (kIsWeb || isNetwork) {
      return Image.network(
        content,
        fit: BoxFit.cover,
        cacheWidth: 64,
        loadingBuilder: (ctx, child, progress) =>
            progress == null ? child : Container(color: colors.surfaceVariant),
        errorBuilder: (_, __, ___) =>
            Icon(Icons.error_outline, size: 14, color: colors.labelSecondary),
      );
    }

    return Image.file(
      File(content),
      fit: BoxFit.cover,
      cacheWidth: 64,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.error_outline, size: 14, color: colors.labelSecondary),
    );
  }
}

// ---------------------------------------------------------------------------
// Clips a child to the top fraction of its bounds.
// fraction 0.0 = nothing visible, 1.0 = fully visible.
// ---------------------------------------------------------------------------
class _TopFractionClipper extends CustomClipper<Rect> {
  final double fraction;

  const _TopFractionClipper(this.fraction);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width, size.height * fraction);
  }

  @override
  bool shouldReclip(_TopFractionClipper oldClipper) =>
      oldClipper.fraction != fraction;
}
