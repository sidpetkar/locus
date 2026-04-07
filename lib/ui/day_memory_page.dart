import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../state/calendar_state.dart';
import '../models/memory_item.dart';
import '../theme/app_theme.dart';
import 'widgets/locus_header.dart';
import 'widgets/media_carousel_item.dart';
import 'record_memory_page.dart';

class DayMemoryPage extends StatefulWidget {
  final DateTime date;
  final String heroTag;
  final bool openGalleryOnLoad;

  const DayMemoryPage({
    Key? key,
    required this.date,
    required this.heroTag,
    this.openGalleryOnLoad = false,
  }) : super(key: key);

  @override
  _DayMemoryPageState createState() => _DayMemoryPageState();
}

class _DayMemoryPageState extends State<DayMemoryPage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final PageController _pageController = PageController(viewportFraction: 0.92);

  bool _isTyping = false;
  bool _isDeleteMode = false;
  bool _isUploading = false;
  int _currentImageIndex = 0;
  String? _deleteModeItemId;
  bool _showConfirmModal = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _textFocusNode.addListener(() {
      setState(() {
        _isTyping = _textFocusNode.hasFocus;
      });
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingText();
      if (widget.openGalleryOnLoad) {
        _uploadMedia();
      }
    });
  }
  
  void _loadExistingText() {
    final provider = Provider.of<CalendarStateProvider>(context, listen: false);
    final dayData = provider.getDayData(widget.date);
    final textMemories = dayData.memories.where((m) => m.type == MemoryType.text).toList();
    
    if (textMemories.isNotEmpty) {
      _textController.text = textMemories.first.content;
    }
  }
  
  Future<void> _saveText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    final provider = Provider.of<CalendarStateProvider>(context, listen: false);
    final dayData = provider.getDayData(widget.date);
    
    final existingTextMemories = dayData.memories.where((m) => m.type == MemoryType.text).toList();
    
    if (existingTextMemories.isNotEmpty) {
      await provider.removeMemory(widget.date, existingTextMemories.first.id);
    }
    
    final item = MemoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: MemoryType.text,
      content: text,
      createdAt: DateTime.now(),
    );
    await provider.addMemory(widget.date, item);
  }

  @override
  void dispose() {
    _saveText();
    _textController.dispose();
    _textFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showAddOverlay() {
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
                                "How do you\nwant to capture\nthis memory?",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                  letterSpacing: -2,
                                  color: c.labelPrimary,
                                ),
                              ),
                              const SizedBox(height: 60),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildOverlayOption(Icons.camera_alt_outlined, "Capture", colors: c, onTap: () {
                                    Navigator.of(context).pop();
                                    _captureCamera();
                                  }),
                                  _buildOverlayOption(Icons.file_upload_outlined, "Upload", colors: c, onTap: () {
                                    Navigator.of(context).pop();
                                    _uploadMedia();
                                  }),
                                  _buildOverlayOption(Icons.mic_none, "Record", colors: c, onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => RecordMemoryPage(date: widget.date),
                                      ),
                                    );
                                  }),
                                ],
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

  Widget _buildOverlayOption(IconData icon, String label, {required AppColorTokens colors, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: colors.icon),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: -1,
              color: colors.labelPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<XFile?> _compressImage(XFile file) async {
    if (kIsWeb) return file;
    
    try {
      // Check file size — skip compression if already under 500 KB
      final bytes = await file.length();
      if (bytes < 500 * 1024) return file;

      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 72,
        minWidth: 1280,
        minHeight: 720,
        format: CompressFormat.jpeg,
      );
      
      return result;
    } catch (e) {
      debugPrint("Image compression error: $e");
      return file;
    }
  }

  Future<XFile?> _compressVideo(XFile file) async {
    if (kIsWeb) return file;
    
    try {
      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.HighestQuality,
        deleteOrigin: false,
      );
      
      if (info != null && info.file != null) {
        return XFile(info.file!.path);
      }
    } catch (e) {
      debugPrint("Video compression error: $e");
    }
    return file;
  }

  Future<String?> _uploadFileToFirebase(XFile file, String userId, {bool isVideo = false}) async {
    try {
      XFile fileToUpload = file;
      
      if (!kIsWeb) {
        if (isVideo) {
          fileToUpload = await _compressVideo(file) ?? file;
        } else {
          fileToUpload = await _compressImage(file) ?? file;
        }
      }
      
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${fileToUpload.name}";
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(userId)
          .child('media')
          .child(fileName);

      TaskSnapshot uploadTask;
      if (kIsWeb) {
        uploadTask = await storageRef.putData(await fileToUpload.readAsBytes());
      } else {
        uploadTask = await storageRef.putFile(File(fileToUpload.path));
      }
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Firebase Upload Error: $e");
      return null;
    }
  }

  Future<void> _uploadMedia() async {
    final provider = Provider.of<CalendarStateProvider>(context, listen: false);
    try {
      final List<XFile> medias = await _picker.pickMultipleMedia();
      if (medias.isNotEmpty) {
        setState(() => _isUploading = true);

        Future<void> processOne(XFile mediaFile) async {
          final isVideo = mediaFile.name.toLowerCase().endsWith('.mp4') ||
              mediaFile.name.toLowerCase().endsWith('.mov') ||
              mediaFile.name.toLowerCase().endsWith('.avi');

          String content = mediaFile.path;

          if (provider.isLoggedIn) {
            final url = await _uploadFileToFirebase(
              mediaFile,
              provider.currentUser!.uid,
              isVideo: isVideo,
            );
            if (url != null) content = url;
          }

          final item = MemoryItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: isVideo ? MemoryType.video : MemoryType.image,
            content: content,
            createdAt: DateTime.now(),
          );
          provider.addMemory(widget.date, item);
        }

        // Upload all selected files in parallel
        await Future.wait(medias.map(processOne));
      }
    } catch (e) {
      debugPrint("Media selection error: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _captureCamera() async {
    final provider = Provider.of<CalendarStateProvider>(context, listen: false);
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() => _isUploading = true);
        
        String content = image.path;
        if (provider.isLoggedIn) {
          final url = await _uploadFileToFirebase(
            image, 
            provider.currentUser!.uid,
            isVideo: false,
          );
          if (url != null) content = url;
        }

        final item = MemoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: MemoryType.image,
          content: content,
          createdAt: DateTime.now(),
        );
        provider.addMemory(widget.date, item);
      }
    } catch (e) {
      debugPrint("Camera capture error: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dayData = context.watch<CalendarStateProvider>().getDayData(widget.date);
    final mediaMemories = dayData.memories.where((m) => m.type == MemoryType.image || m.type == MemoryType.video).toList();
    final audioMemories = dayData.memories.where((m) => m.type == MemoryType.audio).toList();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                LocusHeader(
                  leftIcon: const Icon(Icons.arrow_back),
                  rightIcon1: _isDeleteMode ? const Icon(Icons.delete_outline, size: 26) : null,
                  onLeftTap: () {
                    if (_isDeleteMode) {
                      setState(() => _isDeleteMode = false);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  onRight1Tap: _isDeleteMode ? () => _showDeleteConfirmation(context) : null,
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Date — bold day/month + thin year
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
                                        color: colors.labelPrimary,
                                        height: 1.1,
                                        letterSpacing: -2,
                                      ),
                                    ),
                                    TextSpan(
                                      text: " ${widget.date.year}",
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
                          ),
                        ),
                        
                        if (_isDeleteMode)
                          const SizedBox(height: 60),

                        if (!_isDeleteMode && !_isTyping && mediaMemories.isEmpty)
                          GestureDetector(
                            onTap: _uploadMedia,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              height: 380,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: colors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, size: 28, color: colors.labelSecondary),
                                  const SizedBox(height: 12),
                                  Text(
                                    "This looks empty add\nyour memory",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 16,
                                      color: colors.labelTertiary,
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
                                      return GestureDetector(
                                        onLongPress: () {
                                          setState(() {
                                            _isDeleteMode = true;
                                            _deleteModeItemId = memory.id;
                                            _currentImageIndex = index;
                                          });
                                        },
                                        child: Visibility(
                                          visible: !_isDeleteMode || _deleteModeItemId == memory.id,
                                          maintainState: true,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 3),
                                            decoration: const BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius: BorderRadius.all(Radius.circular(16)),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: MediaCarouselItem(memory: memory),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (mediaMemories.isNotEmpty && !_isDeleteMode)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(mediaMemories.length, (index) {
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: _currentImageIndex == index ? 24 : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _currentImageIndex == index
                                              ? colors.labelPrimary
                                              : colors.carouselDotInactive,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      );
                                    }),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Audio pills
                        if (!_isTyping && audioMemories.isNotEmpty)
                          SizedBox(
                            height: 60,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: audioMemories
                                    .map((m) => Padding(
                                          padding: const EdgeInsets.only(right: 10),
                                          child: Visibility(
                                            visible: !_isDeleteMode || _deleteModeItemId == m.id,
                                            child: _AudioPill(
                                              memory: m,
                                              onLongPress: () {
                                                setState(() {
                                                  _isDeleteMode = true;
                                                  _deleteModeItemId = m.id;
                                                });
                                              },
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),

                        // Text Area
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onVerticalDragUpdate: (details) {
                            if (details.delta.dy < -5) {
                              _textFocusNode.requestFocus();
                            } else if (details.delta.dy > 5) {
                              _textFocusNode.unfocus();
                            }
                          },
                          onTap: () {
                            _textFocusNode.requestFocus();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            child: Visibility(
                              visible: !_isDeleteMode,
                              child: TextField(
                                controller: _textController,
                                focusNode: _textFocusNode,
                                maxLines: null,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18, 
                                  height: 1.3,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Write a memory...',
                                  hintStyle: GoogleFonts.spaceGrotesk(
                                    color: colors.labelTertiary,
                                  ),
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

            // Deletion Confirmation Modal
            if (_showConfirmModal)
              _buildConfirmationDialog(colors),

            // Uploading progress overlay
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  color: colors.background.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                      ),
                      child: CircularProgressIndicator(color: colors.labelPrimary),
                    ),
                  ),
                ),
              ),

            // Keyboard Accessory Row (Mic & Done)
            if (_isTyping)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  height: 48,
                  color: colors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.mic, size: 24, color: colors.icon),
                        onPressed: () async {
                          await _saveText();
                          if (mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RecordMemoryPage(date: widget.date),
                              ),
                            );
                          }
                        },
                      ),
                      TextButton(
                        onPressed: () async {
                          await _saveText();
                          _textFocusNode.unfocus();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colors.background,
                          backgroundColor: colors.labelPrimary,
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
      floatingActionButton: (!_isTyping && !_isDeleteMode) ? FloatingActionButton(
        onPressed: _showAddOverlay,
        backgroundColor: colors.labelPrimary,
        elevation: 0,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: colors.background),
      ) : null,
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    setState(() => _showConfirmModal = true);
  }

  Widget _buildConfirmationDialog(AppColorTokens colors) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.05),
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Delete memory?",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.labelPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "This item will be removed forever from your Locus timeline.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: colors.labelSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => setState(() => _showConfirmModal = false),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.spaceGrotesk(
                            color: colors.labelSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.labelPrimary,
                          foregroundColor: colors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          if (_deleteModeItemId != null) {
                            final provider = Provider.of<CalendarStateProvider>(context, listen: false);
                            provider.removeMemory(widget.date, _deleteModeItemId!);
                            setState(() {
                              _isDeleteMode = false;
                              _deleteModeItemId = null;
                              _showConfirmModal = false;
                            });
                          }
                        },
                        child: Text(
                          "Delete",
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Audio Pill Widget (stateful for playback)
// ---------------------------------------------------------------------------
class _AudioPill extends StatefulWidget {
  final MemoryItem memory;
  final VoidCallback? onLongPress;
  const _AudioPill({required this.memory, this.onLongPress});

  @override
  State<_AudioPill> createState() => _AudioPillState();
}

class _AudioPillState extends State<_AudioPill> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isUnavailable = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // blob: URLs are session-only in browsers — they die on page reload
  bool get _isBlobUrl => widget.memory.content.startsWith('blob:');
  bool get _isNetworkUrl => widget.memory.content.startsWith('http');

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
    _preload();
  }

  Future<void> _preload() async {
    final content = widget.memory.content;
    // blob: URLs only live for the current browser session — skip preload
    if (_isBlobUrl) {
      if (mounted) setState(() => _isUnavailable = true);
      return;
    }
    try {
      if (_isNetworkUrl) {
        await _player.setSourceUrl(content);
      } else if (!kIsWeb) {
        await _player.setSourceDeviceFile(content);
      }
    } catch (_) {
      if (mounted) setState(() => _isUnavailable = true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isUnavailable) return;
    final content = widget.memory.content;
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_position >= _duration && _duration > Duration.zero) {
        await _player.seek(Duration.zero);
      }
      try {
        if (_isNetworkUrl) {
          await _player.play(UrlSource(content));
        } else if (!kIsWeb) {
          await _player.play(DeviceFileSource(content));
        }
      } catch (_) {
        if (mounted) setState(() => _isUnavailable = true);
      }
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final samples = widget.memory.waveformData ?? [];
    final displayDuration = _duration > Duration.zero ? _duration : null;
    final colors = context.appColors;

    if (_isUnavailable) {
      return GestureDetector(
        onLongPress: widget.onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: colors.divider),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic_off, size: 18, color: colors.labelTertiary),
              const SizedBox(width: 8),
              Text(
                'Unavailable',
                style: TextStyle(fontSize: 12, color: colors.labelTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggle,
      onLongPress: widget.onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: colors.divider),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: colors.accent,
              size: 22,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTapDown: (details) {
                if (_duration > Duration.zero) {
                  final x = details.localPosition.dx;
                  const width = 80.0;
                  final pct = (x / width).clamp(0.0, 1.0);
                  _player.seek(Duration(
                      milliseconds: (_duration.inMilliseconds * pct).toInt()));
                }
              },
              child: SizedBox(
                width: 80,
                height: 28,
                child: samples.isEmpty
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          14,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            width: 2.5,
                            height: 6 + (i % 4) * 3.0,
                            decoration: BoxDecoration(
                              color: colors.labelTertiary,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      )
                    : CustomPaint(
                        painter: _PillWaveformPainter(
                          samples: samples,
                          progress: _duration > Duration.zero
                              ? (_position.inMilliseconds /
                                  _duration.inMilliseconds)
                              : 0.0,
                          playedColor: colors.labelPrimary,
                          unplayedColor: colors.divider,
                        ),
                        child: const SizedBox.expand(),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              displayDuration != null ? _fmt(displayDuration) : '--:--',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.labelPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini waveform painter for the pill (shows progress tint)
// ---------------------------------------------------------------------------
class _PillWaveformPainter extends CustomPainter {
  final List<double> samples;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;

  const _PillWaveformPainter({
    required this.samples,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barW = 2.5;
    const gap = 2.0;
    const step = barW + gap;
    const minH = 3.0;

    final maxBars = (size.width / step).floor();
    final slice = samples.length > maxBars
        ? _downsample(samples, maxBars)
        : samples;

    final playedBars = (slice.length * progress).floor();
    final cy = size.height / 2;
    double x = 0;

    for (int i = 0; i < slice.length; i++) {
      final barH = minH + slice[i] * (size.height - minH);
      final paint = Paint()
        ..color = i < playedBars ? playedColor : unplayedColor
        ..strokeWidth = barW
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x + barW / 2, cy - barH / 2),
        Offset(x + barW / 2, cy + barH / 2),
        paint,
      );
      x += step;
    }
  }

  List<double> _downsample(List<double> src, int target) {
    final result = <double>[];
    final ratio = src.length / target;
    for (int i = 0; i < target; i++) {
      result.add(src[(i * ratio).floor()]);
    }
    return result;
  }

  @override
  bool shouldRepaint(_PillWaveformPainter old) =>
      old.samples != samples || old.progress != progress ||
      old.playedColor != playedColor || old.unplayedColor != unplayedColor;
}
