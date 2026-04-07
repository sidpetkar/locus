import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import '../../models/memory_item.dart';
import '../../theme/app_theme.dart';

class MediaCarouselItem extends StatefulWidget {
  final MemoryItem memory;

  const MediaCarouselItem({Key? key, required this.memory}) : super(key: key);

  @override
  _MediaCarouselItemState createState() => _MediaCarouselItemState();
}

class _MediaCarouselItemState extends State<MediaCarouselItem> {
  VideoPlayerController? _videoController;
  bool _isPlaying = true;
  bool _isMuted = true;

  bool get _isNetworkContent =>
      widget.memory.content.startsWith('http://') ||
      widget.memory.content.startsWith('https://');

  @override
  void initState() {
    super.initState();
    if (widget.memory.type == MemoryType.video) {
      final useNetwork = kIsWeb || _isNetworkContent;
      _videoController = useNetwork
          ? VideoPlayerController.networkUrl(Uri.parse(widget.memory.content))
          : VideoPlayerController.file(File(widget.memory.content));
      _videoController!.initialize().then((_) {
        _videoController!.setVolume(0.0);
        _videoController!.setLooping(true);
        _videoController!.play();
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _videoController!.play();
      } else {
        _videoController!.pause();
      }
    });
  }

  void _toggleMute() {
    if (_videoController == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (widget.memory.type == MemoryType.image) {
      final useNetwork = kIsWeb || _isNetworkContent;
      if (useNetwork) {
        return Image.network(
          widget.memory.content,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: colors.labelSecondary,
                strokeWidth: 2,
              ),
            );
          },
          errorBuilder: (_, error, ___) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_not_supported, size: 48, color: colors.labelSecondary),
                const SizedBox(height: 8),
                Text("Image unavailable",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.labelSecondary)),
              ],
            ),
          ),
        );
      }
      return Image.file(
        File(widget.memory.content),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Center(
          child: Icon(Icons.broken_image, size: 48, color: colors.labelSecondary),
        ),
      );
    }

    if (widget.memory.type == MemoryType.video &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      return GestureDetector(
        onTap: _togglePlayPause,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
            if (!_isPlaying)
              const Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.play_arrow, color: Colors.white, size: 40),
                  ),
                ),
              ),
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: _toggleMute,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      );
    }

    // Fallback/Loading
    return Center(child: CircularProgressIndicator(color: colors.labelPrimary));
  }
}
