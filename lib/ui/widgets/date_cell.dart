import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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

class _DateCellState extends State<DateCell> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _minuteTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
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
    _pulseController.dispose();
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
    );

    // Time-aware today: progressive fill (dark overlay clipped from top)
    if (isTimeAware && isToday) {
      final dayProgress = (now.hour * 60 + now.minute) / 1440.0;

      final darkContent = _buildCellContent(
        cellColors: darkTokens,
        isToday: true,
        hasMemories: hasMemories,
        items: items,
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

  /// Builds the visual cell rectangle (background + border + day number + thumbnails).
  Widget _buildCellContent({
    required AppColorTokens cellColors,
    required bool isToday,
    required bool hasMemories,
    required List<MemoryItem> items,
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
                              ? ((kIsWeb || m.content.startsWith('http'))
                                  ? Image.network(
                                      m.content,
                                      fit: BoxFit.cover,
                                      cacheWidth: 64,
                                      loadingBuilder: (ctx, child, progress) =>
                                          progress == null
                                              ? child
                                              : Container(color: cellColors.surfaceVariant),
                                      errorBuilder: (_, __, ___) =>
                                          Icon(Icons.error_outline, size: 14, color: cellColors.labelSecondary),
                                    )
                                  : Image.file(
                                      File(m.content),
                                      fit: BoxFit.cover,
                                      cacheWidth: 64,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(Icons.error_outline, size: 14, color: cellColors.labelSecondary),
                                    ))
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
