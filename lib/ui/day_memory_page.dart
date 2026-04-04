import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

import '../state/calendar_state.dart';
import '../models/memory_item.dart';
import 'widgets/locus_header.dart'; // To use identical header design just not identical actions
import 'widgets/media_carousel_item.dart';

class DayMemoryPage extends StatefulWidget {
  final DateTime date;
  final String heroTag;

  const DayMemoryPage({Key? key, required this.date, required this.heroTag}) : super(key: key);

  @override
  _DayMemoryPageState createState() => _DayMemoryPageState();
}

class _DayMemoryPageState extends State<DayMemoryPage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final PageController _pageController = PageController(viewportFraction: 0.92);

  bool _isTyping = false;
  int _currentImageIndex = 0;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _textFocusNode.addListener(() {
      setState(() {
        _isTyping = _textFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showAddOverlay() {
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
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "How you want\nto capture\nmemory?",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                letterSpacing: -2,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 60),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildOverlayOption(Icons.camera_alt_outlined, "Capture", () {
                                  Navigator.of(context).pop();
                                  _captureCamera();
                                }),
                                _buildOverlayOption(Icons.file_upload_outlined, "Upload", () {
                                  Navigator.of(context).pop();
                                  _uploadMedia();
                                }),
                                _buildOverlayOption(Icons.mic_none, "Record", () {}),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        onPressed: () => Navigator.of(context).pop(),
                        backgroundColor: Colors.black87,
                        elevation: 0,
                        shape: const CircleBorder(),
                        child: const Icon(Icons.close, color: Colors.white),
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

  Widget _buildOverlayOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: -1,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadMedia() async {
    try {
      final List<XFile> medias = await _picker.pickMultipleMedia();
      if (medias.isNotEmpty) {
        final provider = Provider.of<CalendarStateProvider>(context, listen: false);
        for (var mediaFile in medias) {
          final isVideo = mediaFile.path.toLowerCase().endsWith('.mp4') || 
                          mediaFile.path.toLowerCase().endsWith('.mov');
          
          final item = MemoryItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: isVideo ? MemoryType.video : MemoryType.image,
            content: mediaFile.path,
            createdAt: DateTime.now(),
          );
          provider.addMemory(widget.date, item);
        }
      }
    } catch (e) {
      debugPrint("Media selection error: \$e");
    }
  }

  Future<void> _captureCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        final provider = Provider.of<CalendarStateProvider>(context, listen: false);
        final item = MemoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: MemoryType.image, // Future note: use pickVideo for camera video
          content: image.path,
          createdAt: DateTime.now(),
        );
        provider.addMemory(widget.date, item);
      }
    } catch (e) {
      debugPrint("Camera capture error: \$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('d MMMM').format(widget.date);
    
    final dayData = context.watch<CalendarStateProvider>().getDayData(widget.date);
    final mediaMemories = dayData.memories.where((m) => m.type == MemoryType.image || m.type == MemoryType.video).toList();
    final audioMemories = dayData.memories.where((m) => m.type == MemoryType.audio).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Header (Reusing Component Design)
                LocusHeader(
                  leftIcon: const Icon(Icons.arrow_back),
                  onLeftTap: () => Navigator.of(context).pop(),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Date
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Hero(
                            tag: widget.heroTag,
                            child: Material(
                              color: Colors.transparent,
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "${widget.date.day} ${DateFormat('MMMM').format(widget.date)}",
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        height: 1.1,
                                        letterSpacing: -2,
                                      ),
                                    ),
                                    TextSpan(
                                      text: " ${widget.date.year}",
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
                          ),
                        ),
                        
                        if (!_isTyping && mediaMemories.isEmpty)
                          GestureDetector(
                            onTap: _uploadMedia, // Open gallery instantly instead of the overlay
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              height: 380,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add, size: 28, color: Colors.black54),
                                  const SizedBox(height: 12),
                                  Text(
                                    "This looks empty add\nyour memory",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 16,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (mediaMemories.isNotEmpty)
                          const SizedBox(height: 24),
                        
                        // Carousel
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.fastLinearToSlowEaseIn,
                          height: _isTyping ? 0 : (mediaMemories.isEmpty ? 0 : 420),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 380,
                                  child: PageView.builder(
                                    controller: _pageController,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: mediaMemories.length,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentImageIndex = index;
                                      });
                                    },
                                    itemBuilder: (context, index) {
                                      final memory = mediaMemories[index];
                                      return Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: MediaCarouselItem(memory: memory),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Dot indicator
                                if (mediaMemories.isNotEmpty)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(mediaMemories.length, (index) {
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: _currentImageIndex == index ? 24 : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _currentImageIndex == index ? Colors.black87 : Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      );
                                    }),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Audio area (placeholder)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.fastLinearToSlowEaseIn,
                          height: _isTyping ? 0 : (audioMemories.isEmpty ? 0 : 60),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20, left: 24, right: 24),
                              child: Row(
                                children: audioMemories.map((m) => _buildAudioPill()).toList(),
                              ),
                            ),
                          ),
                        ),

                        // Text Area
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onVerticalDragUpdate: (details) {
                            if (details.delta.dy < -5) { // Swiped up
                              _textFocusNode.requestFocus();
                            } else if (details.delta.dy > 5) { // Swiped down
                              _textFocusNode.unfocus();
                            }
                          },
                          onTap: () {
                            _textFocusNode.requestFocus();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            child: TextField(
                              controller: _textController,
                              focusNode: _textFocusNode,
                              maxLines: null,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18, 
                                height: 1.5,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Write a memory...',
                                hintStyle: GoogleFonts.spaceGrotesk(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Keyboard Accessory Row (Mic & Done)
            if (_isTyping)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  height: 48, // 32px constraints usually need padding
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.mic, size: 24, color: Colors.black87),
                        onPressed: () {},
                      ),
                      TextButton(
                        onPressed: () {
                          _textFocusNode.unfocus();
                          // In real implementation, save text here.
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: const Size(60, 32),
                        ),
                        child: Text("Done", style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
      floatingActionButton: !_isTyping ? FloatingActionButton(
        onPressed: _showAddOverlay,
        backgroundColor: Colors.black87,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildAudioPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_circle_outline, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 8),
          Row(
            children: List.generate(12, (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 2.5,
              height: 10 + (index % 4) * 4.0,
              color: Colors.grey.shade400,
            )),
          ),
          const SizedBox(width: 8),
          Text(
            "0:05",
            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}
