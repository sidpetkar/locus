import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/calendar_state.dart';
import '../../models/memory_item.dart';
import '../day_memory_page.dart';

class DateCell extends StatefulWidget {
  final DateTime? date;

  const DateCell({Key? key, this.date}) : super(key: key);

  @override
  State<DateCell> createState() => _DateCellState();
}

class _DateCellState extends State<DateCell> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.date == null) {
      return Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.transparent)),
      );
    }

    final provider = context.watch<CalendarStateProvider>();
    final dayData = provider.getDayData(widget.date!);
    final hasMemories = dayData.memories.isNotEmpty;
    
    // Check pulse logic
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

    final isToday = widget.date!.year == DateTime.now().year &&
                    widget.date!.month == DateTime.now().month &&
                    widget.date!.day == DateTime.now().day;

    final heroTag = 'day_cell_${widget.date!.year}_${widget.date!.month}_${widget.date!.day}';
    final items = dayData.memories.take(3).toList();

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
                              Colors.black.withOpacity(0.15),
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: isToday 
                    ? Border.all(color: Colors.black87, width: 2.5)
                    : Border.all(color: Colors.grey.shade200, width: 0.5),
              ),
              child: Stack(
                children: [
                  // Text formatting updated to 0 letterSpacing
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Text(
                      '${widget.date!.day}',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0, 
                        color: widget.date!.weekday == 7 ? Colors.red : Colors.black87,
                      ),
                    ),
                  ),
                  if (hasMemories)
                    Positioned(
                      bottom: 4,
                      right: 4, // Stick bottom-right edge to match design rules securely
                      child: SizedBox(
                        width: 32 + ((items.length - 1) * 18.0), // Spaced out more
                        height: 48, // Taller baseline 
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: List.generate(items.length, (index) {
                            int physicalIndex = items.length - 1 - index; // Ensure 0 is painted natively last
                            final m = items[physicalIndex];
                            
                            return Positioned(
                              left: physicalIndex * 18.0, // Wider overlap offsets
                              child: Container(
                                width: 32, 
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  border: Border.all(color: Colors.white, width: 3.0), // Thicker 3.0 frames
                                  borderRadius: BorderRadius.circular(12), // Smoother large rounds
                                ),
                                clipBehavior: Clip.antiAlias, // Ensures internal image is clipped
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9), // Inner clip radius to match outer border natively
                                  child: m.type == MemoryType.image 
                                      ? (kIsWeb 
                                          ? Image.network(
                                              m.content, fit: BoxFit.cover, 
                                              errorBuilder: (_,__,___) => const Icon(Icons.error_outline, size: 14, color: Colors.grey)
                                            )
                                          : Image.file(
                                              File(m.content), fit: BoxFit.cover,
                                              errorBuilder: (_,__,___) => const Icon(Icons.error_outline, size: 14, color: Colors.grey)
                                            ))
                                      : const Icon(Icons.videocam, size: 16, color: Colors.black54),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
