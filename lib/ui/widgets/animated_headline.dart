import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/nudge_service.dart';
import '../../theme/app_theme.dart';

/// Fixed height for the headline area.
/// Fits: single-line title (48px × 1.1) and two-line nudges (32px × 1.1 × 2).
const double kHeadlineHeight = 72.0;

class AnimatedHeadline extends StatefulWidget {
  /// Bold portion of the static title (e.g. "April" or "Momento").
  final String titleBold;

  /// Light portion of the static title (e.g. " 2026" or " Mori").
  final String titleLight;

  final List<ResolvedNudge> nudges;

  const AnimatedHeadline({
    Key? key,
    required this.titleBold,
    required this.titleLight,
    required this.nudges,
  }) : super(key: key);

  @override
  State<AnimatedHeadline> createState() => _AnimatedHeadlineState();
}

class _AnimatedHeadlineState extends State<AnimatedHeadline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  /// Slot indices: 0 = static title, 1..n = nudge (1-indexed).
  int _displayedSlot = 0;
  int _incomingSlot = 0;
  int _nudgeCursor = 0;

  Timer? _holdTimer;
  bool _animating = false;

  static const _holdDuration = Duration(seconds: 5);
  static const _slideDuration = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _slideDuration);
    _controller.addStatusListener(_onAnimStatus);
    _scheduleNext();
  }

  @override
  void didUpdateWidget(AnimatedHeadline old) {
    super.didUpdateWidget(old);
    if (old.nudges != widget.nudges ||
        old.titleBold != widget.titleBold ||
        old.titleLight != widget.titleLight) {
      _holdTimer?.cancel();
      _controller.reset();
      _animating = false;
      _displayedSlot = 0;
      _incomingSlot = 0;
      _nudgeCursor = 0;
      _scheduleNext();
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.removeStatusListener(_onAnimStatus);
    _controller.dispose();
    super.dispose();
  }

  void _scheduleNext() {
    _holdTimer?.cancel();
    if (widget.nudges.isEmpty) return;
    _holdTimer = Timer(_holdDuration, _beginTransition);
  }

  void _beginTransition() {
    if (!mounted || _animating) return;

    int next;
    if (_displayedSlot == 0) {
      next = _nudgeCursor + 1;
    } else {
      _nudgeCursor = (_nudgeCursor + 1) % widget.nudges.length;
      next = 0;
    }

    setState(() {
      _incomingSlot = next;
      _animating = true;
    });

    _controller.forward(from: 0.0);
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _displayedSlot = _incomingSlot;
        _animating = false;
        _controller.reset();
      });
      _scheduleNext();
    }
  }

  // ---------------------------------------------------------------------------
  // Content builders
  // ---------------------------------------------------------------------------

  Widget _buildTitle(AppColorTokens colors) {
    return SizedBox(
      height: kHeadlineHeight,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: widget.titleBold,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: colors.labelPrimary,
                  height: 1.1,
                  letterSpacing: -2,
                ),
              ),
              TextSpan(
                text: widget.titleLight,
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
    );
  }

  Widget _buildNudge(ResolvedNudge nudge, AppColorTokens colors) {
    final hasNewline = nudge.rawText.contains('\n');
    final double fontSize = hasNewline ? 32.0 : 48.0;

    return SizedBox(
      height: kHeadlineHeight,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: RichText(
          maxLines: 2,
          overflow: TextOverflow.clip,
          text: TextSpan(
            children: nudge.spans.map((span) {
              return TextSpan(
                text: span.text,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: fontSize,
                  fontWeight: span.bold ? FontWeight.bold : FontWeight.w300,
                  color: span.bold
                      ? colors.labelPrimary
                      : colors.labelSecondary,
                  height: 1.1,
                  letterSpacing: hasNewline ? -1.0 : -2.0,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _slotWidget(int slot, AppColorTokens colors) {
    if (slot == 0) return _buildTitle(colors);
    final idx = slot - 1;
    if (idx < widget.nudges.length) return _buildNudge(widget.nudges[idx], colors);
    return _buildTitle(colors);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (widget.nudges.isEmpty) {
      return _buildTitle(colors);
    }

    return SizedBox(
      height: kHeadlineHeight,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeInOutCubic.transform(_controller.value);
            final outOffset = Offset(0, -t);
            final inOffset = Offset(0, 1.0 - t);

            return Stack(
              children: [
                FractionalTranslation(
                  translation: _animating ? outOffset : Offset.zero,
                  child: _slotWidget(_displayedSlot, colors),
                ),
                if (_animating)
                  FractionalTranslation(
                    translation: inOffset,
                    child: _slotWidget(_incomingSlot, colors),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
