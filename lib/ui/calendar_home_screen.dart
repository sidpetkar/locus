import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/calendar_state.dart';
import '../theme/app_theme.dart';
import '../services/nudge_service.dart';
import 'widgets/animated_headline.dart';
import 'widgets/vertical_month_grid.dart';
import 'widgets/locus_header.dart';
import 'widgets/locus_sidebar.dart';

class CalendarHomeScreen extends StatefulWidget {
  const CalendarHomeScreen({Key? key}) : super(key: key);

  @override
  _CalendarHomeScreenState createState() => _CalendarHomeScreenState();
}

class _CalendarHomeScreenState extends State<CalendarHomeScreen> {
  late PageController _yearController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  int _currentMonthIndex = DateTime.now().month - 1;
  int _currentYearIndex = 500;
  final Map<int, GlobalKey<_YearViewState>> _yearKeys = {};

  final TextEditingController _searchController = TextEditingController();
  Timer? _headerTimer;
  
  bool _isHeaderVisible = true;

  @override
  void initState() {
    super.initState();
    _yearController = PageController(initialPage: 500);
  }

  @override
  void dispose() {
    _headerTimer?.cancel();
    _yearController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int getYearFromIndex(int index) {
    return DateTime.now().year + (index - 500);
  }

  void _jumpToPresent() {
    int targetYearIndex = 500;
    int targetMonthIndex = DateTime.now().month - 1;
    _navigateTo(targetYearIndex, targetMonthIndex);
  }

  void _navigateTo(int yearIndex, int monthIndex) {
    setState(() {
      _currentMonthIndex = monthIndex;
    });

    if (_yearController.page?.round() == yearIndex) {
      _yearKeys[yearIndex]?.currentState?.scrollToMonth(monthIndex);
    } else {
      _yearController.animateToPage(
        yearIndex, 
        duration: const Duration(milliseconds: 600), 
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSearchOverlay() {
    final colors = context.appColors;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: colors.barrier,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        final c = context.appColors;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: c.inputSurface,
              child: SafeArea(
                child: Column(
                  children: [
                    LocusHeader(
                      leftIcon: const Icon(Icons.close, size: 28),
                      onLeftTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Where do you\nwant to look?",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                  letterSpacing: -2,
                                  color: c.labelPrimary,
                                ),
                              ),
                              const SizedBox(height: 40),
                              TextField(
                                controller: _searchController,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 28,
                                  letterSpacing: -0.5,
                                  color: c.labelPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: "e.g. 14 May 2026",
                                  hintStyle: GoogleFonts.spaceGrotesk(
                                    color: c.labelTertiary,
                                    fontSize: 28,
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(color: c.labelPrimary),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: c.labelPrimary, width: 2),
                                  ),
                                ),
                                autofocus: true,
                                onSubmitted: (val) {
                                  _handleSearch(val);
                                },
                              ),
                              const SizedBox(height: 28),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: c.labelPrimary,
                                    foregroundColor: c.background,
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                    elevation: 0,
                                  ),
                                  onPressed: () => _handleSearch(_searchController.text),
                                  child: Text(
                                    "Search",
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;
    
    try {
      final now = DateTime.now();
      int? d, m, y;
      
      final RegExp yearReg = RegExp(r'\b(20\d{2})\b');
      final yearMatch = yearReg.firstMatch(query);
      y = yearMatch != null ? int.parse(yearMatch.group(1)!) : now.year;

      List<String> months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
      String qLower = query.toLowerCase();
      for (int i=0; i<months.length; i++) {
        if (qLower.contains(months[i])) {
          m = i + 1;
          break;
        }
      }
      
      final RegExp dayReg = RegExp(r'\b([1-9]|[12]\d|3[01])\b');
      final dayMatches = dayReg.allMatches(query);
      for (var match in dayMatches) {
        int parsed = int.parse(match.group(1)!);
        if (parsed != y) {
          d = parsed;
          break;
        }
      }

      if (m != null) {
        d ??= 1;
        int targetYearIndex = 500 + (y - now.year);
        int targetMonthIndex = m - 1;
        
        Navigator.of(context).pop();
        _navigateTo(targetYearIndex, targetMonthIndex);
        
        final DateTime targetDate = DateTime(y, m, d);
        Provider.of<CalendarStateProvider>(context, listen: false).pulseDate.value = targetDate;
      }
    } catch (e) {
      debugPrint("Search failed: $e");
    }
  }

  /// Whether the currently-visible month is entirely in the future.
  /// Used in time-aware mode to flip the header to light tokens.
  bool _isVisibleMonthInFuture(CalendarStateProvider provider) {
    if (!provider.isTimeAwareMode) return false;
    final now = DateTime.now();
    final year = getYearFromIndex(_currentYearIndex);
    final month = _currentMonthIndex + 1;
    return year > now.year || (year == now.year && month > now.month);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalendarStateProvider>(context);
    final user = provider.currentUser;
    final colors = context.appColors;

    final bool headerUsesLight = _isVisibleMonthInFuture(provider);
    final AppColorTokens headerColors =
        headerUsesLight ? lightTokens : colors;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const LocusSidebar(),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _yearController,
              scrollDirection: Axis.horizontal,
              itemCount: 1000,
              onPageChanged: (yearIndex) {
                setState(() {
                  _currentYearIndex = yearIndex;
                });
              },
              itemBuilder: (context, yearIndex) {
                final int year = getYearFromIndex(yearIndex);
                
                if(!_yearKeys.containsKey(yearIndex)) {
                  _yearKeys[yearIndex] = GlobalKey<_YearViewState>();
                }
                
                return NotificationListener<ScrollNotification>(
                  onNotification: (notif) {
                    if (notif is ScrollUpdateNotification && notif.metrics.axis == Axis.vertical) {
                      if (notif.scrollDelta != null && notif.scrollDelta! > 2 && _isHeaderVisible) {
                        setState(() => _isHeaderVisible = false);
                      } else if (notif.scrollDelta != null && notif.scrollDelta! < -2 && !_isHeaderVisible) {
                        setState(() => _isHeaderVisible = true);
                      }
                    }
                    if (notif is ScrollEndNotification && notif.metrics.axis == Axis.vertical) {
                      _headerTimer?.cancel();
                      _headerTimer = Timer(const Duration(seconds: 2), () {
                        if (mounted && !_isHeaderVisible) {
                          setState(() => _isHeaderVisible = true);
                        }
                      });
                    }
                    return false;
                  },
                  child: _YearView(
                    key: _yearKeys[yearIndex],
                    year: year,
                    initialMonthIndex: _currentMonthIndex,
                    onMonthChanged: (monthIndex) {
                      setState(() {
                        _currentMonthIndex = monthIndex;
                      });
                    },
                  ),
                );
              },
            ),
            
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: _isHeaderVisible ? 0 : -100, 
              left: 0, right: 0,
              child: Container(
                color: headerColors.background.withOpacity(0.95),
                child: Theme(
                  data: headerUsesLight ? AppTheme.light : Theme.of(context),
                  child: Builder(
                    builder: (ctx) {
                      bool isCurrentMonth = _currentYearIndex == 500 && _currentMonthIndex == (DateTime.now().month - 1);
                      
                      Widget leftWidget;
                      if (user != null && user.photoURL != null) {
                        leftWidget = Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(user.photoURL!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      } else {
                        leftWidget = const Icon(Icons.menu_rounded, size: 28);
                      }

                      return LocusHeader(
                        leftIcon: leftWidget,
                        onLeftTap: () => _scaffoldKey.currentState?.openDrawer(),
                        rightIcon1: isCurrentMonth ? null : const Icon(Icons.location_on_outlined, size: 28),
                        rightIcon2: const Icon(Icons.search, size: 28),
                        onRight1Tap: isCurrentMonth ? null : _jumpToPresent,
                        onRight2Tap: _showSearchOverlay,
                      );
                    }
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearView extends StatefulWidget {
  final int year;
  final int initialMonthIndex;
  final ValueChanged<int> onMonthChanged;

  const _YearView({
    Key? key,
    required this.year,
    required this.initialMonthIndex,
    required this.onMonthChanged,
  }) : super(key: key);

  @override
  State<_YearView> createState() => _YearViewState();
}

class _YearViewState extends State<_YearView> {
  late PageController _monthController;

  @override
  void initState() {
    super.initState();
    _monthController = PageController(initialPage: widget.initialMonthIndex);
  }

  @override
  void dispose() {
    _monthController.dispose();
    super.dispose();
  }

  void scrollToMonth(int index) {
    if (_monthController.hasClients) {
      _monthController.animateToPage(
        index, 
        duration: const Duration(milliseconds: 600), 
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarStateProvider>();
    final isTimeAware = provider.isTimeAwareMode;

    return PageView.builder(
      controller: _monthController,
      scrollDirection: Axis.vertical,
      itemCount: 12,
      onPageChanged: widget.onMonthChanged,
      itemBuilder: (context, monthIndex) {
        final month = monthIndex + 1;
        final monthName = DateFormat('MMMM').format(DateTime(widget.year, month));

        // Determine if this entire month is in the future for time-aware theming
        final now = DateTime.now();
        final isMonthInFuture = isTimeAware &&
            (widget.year > now.year ||
                (widget.year == now.year && month > now.month));

        final ThemeData? localTheme =
            isTimeAware && isMonthInFuture ? AppTheme.light : null;
        final Color pageBg = isTimeAware
            ? (isMonthInFuture ? lightTokens.background : darkTokens.background)
            : Theme.of(context).scaffoldBackgroundColor;

        Widget page = Container(
          color: pageBg,
          padding: const EdgeInsets.only(top: 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AnimatedHeadline(
                  titleBold: monthName,
                  titleLight: ' ${widget.year}',
                  nudges: provider.nudgesEnabled
                      ? NudgeService.getNudgesForNow(widget.year, month)
                      : const [],
                ),
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: VerticalMonthGrid(year: widget.year, month: month),
              ),
            ],
          ),
        );

        if (localTheme != null) {
          page = Theme(data: localTheme, child: page);
        }

        return page;
      },
    );
  }
}
