import 'dart:ui';
import 'dart:async'; // Add Timer import
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/calendar_state.dart';
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
  
  int _currentMonthIndex = DateTime.now().month - 1;
  int _currentYearIndex = 500;
  final Map<int, GlobalKey<_YearViewState>> _yearKeys = {};

  final TextEditingController _searchController = TextEditingController();
  Timer? _headerTimer;
  
  bool _isHeaderVisible = true;

  @override
  void initState() {
    super.initState();
    _yearController = PageController(initialPage: 500); // 500 = current year
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
      // Already on the same year, just animate the month
      _yearKeys[yearIndex]?.currentState?.scrollToMonth(monthIndex);
    } else {
      // Animate year; it will spawn the new YearView at _currentMonthIndex naturally!
      _yearController.animateToPage(
        yearIndex, 
        duration: const Duration(milliseconds: 600), 
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSearchOverlay() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.1),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.white.withOpacity(0.1),
              child: SafeArea(
                child: Stack(
                  children: [
                    Positioned(
                      top: 16,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Where you\nwant look?",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                letterSpacing: -2,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 40),
                            TextField(
                              controller: _searchController,
                              style: GoogleFonts.spaceGrotesk(fontSize: 24, letterSpacing: -1),
                              decoration: InputDecoration(
                                hintText: "e.g. 14 May 2026",
                                hintStyle: GoogleFonts.spaceGrotesk(color: Colors.grey, fontSize: 24),
                                border: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black87)
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black87, width: 2)
                                ),
                              ),
                              onSubmitted: (val) {
                                _handleSearch(val);
                              },
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                onPressed: () => _handleSearch(_searchController.text),
                                child: Text(
                                  "Search", 
                                  style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600)
                                ),
                              ),
                            )
                          ],
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
    
    // Simple parsing logic (MVP). In production, use natural language parser.
    try {
      final now = DateTime.now();
      int? d, m, y;
      
      // Look for year
      final RegExp yearReg = RegExp(r'\b(20\d{2})\b');
      final yearMatch = yearReg.firstMatch(query);
      y = yearMatch != null ? int.parse(yearMatch.group(1)!) : now.year;

      // Look for month word
      List<String> months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
      String qLower = query.toLowerCase();
      for (int i=0; i<months.length; i++) {
        if (qLower.contains(months[i])) {
          m = i + 1;
          break;
        }
      }
      
      // Look for day standalone
      final RegExp dayReg = RegExp(r'\b([1-9]|[12]\d|3[01])\b');
      final dayMatches = dayReg.allMatches(query);
      for (var match in dayMatches) {
        int parsed = int.parse(match.group(1)!);
        // Exclude year match if it somehow conflicted (unlikely with \b bounds, but just safe)
        if (parsed != y) {
          d = parsed;
          break;
        }
      }

      if (m != null) {
        d ??= 1;
        int targetYearIndex = 500 + (y - now.year);
        int targetMonthIndex = m - 1;
        
        Navigator.of(context).pop(); // close dialog
        _navigateTo(targetYearIndex, targetMonthIndex);
        
        // Fire pulse via provider
        final DateTime targetDate = DateTime(y, m, d);
        Provider.of<CalendarStateProvider>(context, listen: false).pulseDate.value = targetDate;
      }
    } catch (e) {
      debugPrint("Search failed: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalendarStateProvider>(context);
    final user = provider.currentUser;

    return Scaffold(
      key: GlobalKey<ScaffoldState>(), // Individual key if needed, or just use Builder
      drawer: const LocusSidebar(),
      backgroundColor: Colors.white,
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
                    // Only handle vertical scrolling for header hiding
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
                color: Colors.white.withOpacity(0.95),
                child: Builder(
                  builder: (context) {
                    bool isCurrentMonth = _currentYearIndex == 500 && _currentMonthIndex == (DateTime.now().month - 1);
                    
                    Widget leftWidget = Image.asset('assets/locus-icon.png', width: 28, height: 28);
                    if (user != null && user.photoURL != null) {
                      leftWidget = CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(user.photoURL!),
                      );
                    }

                    return LocusHeader(
                      leftIcon: leftWidget,
                      onLeftTap: () => Scaffold.of(context).openDrawer(),
                      rightIcon1: isCurrentMonth ? null : const Icon(Icons.location_on_outlined, size: 28),
                      rightIcon2: const Icon(Icons.search, size: 28),
                      onRight1Tap: isCurrentMonth ? null : _jumpToPresent,
                      onRight2Tap: _showSearchOverlay,
                    );
                  }
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
    return PageView.builder(
      controller: _monthController,
      scrollDirection: Axis.vertical,
      itemCount: 12,
      onPageChanged: widget.onMonthChanged,
      itemBuilder: (context, monthIndex) {
        final month = monthIndex + 1;
        final monthName = DateFormat('MMMM').format(DateTime(widget.year, month));

        return Padding(
          padding: const EdgeInsets.only(top: 100.0), // header offset only — grid extends to bottom edge
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: monthName,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.1,
                          letterSpacing: -2,
                        ),
                      ),
                      TextSpan(
                        text: " ${widget.year}",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          color: Colors.black54,
                          height: 1.1,
                          letterSpacing: -2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Weekday Headers (Rows in normal calendars, but Columns here! Wait.)
              // User said: Columns = weeks, Rows = weekdays.
              // So we don't display Weekday headers horizontally?
              // The reference image doesn't show headers. Let's just draw the grid.
              
              Expanded(
                child: VerticalMonthGrid(year: widget.year, month: month),
              ),
            ],
          ),
        );
      },
    );
  }
}
