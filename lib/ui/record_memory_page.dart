import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../state/calendar_state.dart';
import '../models/memory_item.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// State Enum
// ---------------------------------------------------------------------------
enum _RecordPhase { initial, recording, stopped }

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------
class RecordMemoryPage extends StatefulWidget {
  final DateTime date;

  const RecordMemoryPage({Key? key, required this.date}) : super(key: key);

  @override
  State<RecordMemoryPage> createState() => _RecordMemoryPageState();
}

class _RecordMemoryPageState extends State<RecordMemoryPage> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  _RecordPhase _phase = _RecordPhase.initial;
  String? _audioPath;

  Timer? _timer;
  int _elapsed = 0;

  final List<double> _samples = [];
  StreamSubscription<Amplitude>? _ampSub;

  bool _isPlaying = false;
  Duration _playDuration = Duration.zero;
  Duration _playPosition = Duration.zero;

  @override
  void initState() {
    super.initState();

    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _playDuration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _playPosition = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() {
        _isPlaying = false;
        _playPosition = Duration.zero;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _startRecording());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ampSub?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Recording
  // -------------------------------------------------------------------------
  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }

    String path;
    if (kIsWeb) {
      path = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    if (!mounted) return;
    setState(() {
      _phase = _RecordPhase.recording;
      _elapsed = 0;
      _samples.clear();
    });

    _startTimer();

    _ampSub?.cancel();
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((amp) {
      if (!mounted || _phase != _RecordPhase.recording) return;
      const minDb = -60.0;
      final raw = (amp.current - minDb) / (-minDb);
      final value = raw.clamp(0.0, 1.0);
      setState(() => _samples.add(value));
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _ampSub?.cancel();

    final path = await _recorder.stop();
    if (path == null || !mounted) return;

    setState(() {
      _phase = _RecordPhase.stopped;
      _audioPath = path;
    });

    if (path.startsWith('blob:') || path.startsWith('http')) {
      await _player.setSourceUrl(path);
    } else if (!kIsWeb) {
      await _player.setSourceDeviceFile(path);
    }
  }

  // -------------------------------------------------------------------------
  // Playback
  // -------------------------------------------------------------------------
  Future<void> _togglePlayback() async {
    if (_audioPath == null) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_playPosition >= _playDuration && _playDuration > Duration.zero) {
        await _player.seek(Duration.zero);
      }
      final path = _audioPath!;
      if (path.startsWith('blob:') || path.startsWith('http')) {
        await _player.play(UrlSource(path));
      } else {
        await _player.play(DeviceFileSource(path));
      }
    }
  }

  // -------------------------------------------------------------------------
  // Retake
  // -------------------------------------------------------------------------
  void _retake() {
    _player.stop();
    setState(() {
      _audioPath = null;
      _samples.clear();
      _elapsed = 0;
      _playPosition = Duration.zero;
      _playDuration = Duration.zero;
      _phase = _RecordPhase.initial;
    });
    _startRecording();
  }

  // -------------------------------------------------------------------------
  // Save
  // -------------------------------------------------------------------------
  Future<void> _saveRecording() async {
    if (_audioPath == null) return;

    final provider = Provider.of<CalendarStateProvider>(context, listen: false);
    final date = widget.date;
    final localPath = _audioPath!;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final item = MemoryItem(
      id: id,
      type: MemoryType.audio,
      content: localPath,
      createdAt: DateTime.now(),
      waveformData: List<double>.from(_samples),
    );
    provider.addMemory(date, item);

    // Fire background upload before popping so the Future stays alive
    if (provider.isLoggedIn && !kIsWeb) {
      _backgroundUploadAudio(provider, date, id, localPath);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _backgroundUploadAudio(
    CalendarStateProvider provider,
    DateTime date,
    String memoryId,
    String localPath,
  ) async {
    try {
      final uid = provider.currentUser!.uid;
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('audio')
          .child(fileName);

      final task = await ref.putFile(File(localPath));
      final url = await task.ref.getDownloadURL();
      await provider.updateMemoryContent(date, memoryId, url);
    } catch (e) {
      debugPrint('Audio background upload error: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Timer
  // -------------------------------------------------------------------------
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
  }

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const Spacer(flex: 3),

                // Waveform
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: _samples.isEmpty
                        ? Center(
                            child: Container(
                              height: 3,
                              width: 120,
                              decoration: BoxDecoration(
                                color: colors.divider,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTapDown: (details) {
                              if (_phase == _RecordPhase.stopped && _playDuration > Duration.zero) {
                                final x = details.localPosition.dx;
                                final width = MediaQuery.of(context).size.width - 48;
                                final seekPos = (x / width).clamp(0.0, 1.0);
                                final seekDuration = Duration(milliseconds: (_playDuration.inMilliseconds * seekPos).toInt());
                                _player.seek(seekDuration);
                              }
                            },
                            child: CustomPaint(
                              painter: _WaveformPainter(
                                samples: List<double>.from(_samples),
                                progress: _phase == _RecordPhase.stopped &&
                                        _playDuration > Duration.zero
                                    ? (_playPosition.inMilliseconds /
                                        _playDuration.inMilliseconds)
                                    : (_phase == _RecordPhase.recording ? 1.0 : 0.0),
                                playedColor: colors.labelPrimary,
                                unplayedColor: colors.divider,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Timer label
                Text(
                  _phase == _RecordPhase.stopped
                      ? _fmt(_playDuration.inSeconds > 0
                          ? _playDuration.inSeconds
                          : _elapsed)
                      : _fmt(_elapsed),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colors.labelSecondary,
                    letterSpacing: 1,
                  ),
                ),

                const Spacer(flex: 3),

                // Controls
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 48, left: 32, right: 32),
                  child: _buildControls(colors),
                ),
              ],
            ),

            // Close button
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(Icons.close, color: colors.labelSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // (upload runs silently in background after save)
          ],
        ),
      ),
    );
  }

  Widget _buildControls(AppColorTokens colors) {
    switch (_phase) {
      case _RecordPhase.recording:
        return Center(
          child: GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.divider, width: 2),
              ),
              child: Center(
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: colors.labelPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        );

      case _RecordPhase.stopped:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _pillButton('Retake', _retake, colors: colors),

            GestureDetector(
              onTap: _togglePlayback,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.labelPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                  color: colors.background,
                  size: 28,
                ),
              ),
            ),

            _pillButton('Save', _saveRecording, colors: colors),
          ],
        );

      default:
        return const SizedBox(height: 72);
    }
  }

  Widget _pillButton(String label, VoidCallback onTap, {required AppColorTokens colors}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: colors.labelPrimary,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.background,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom Painter – bar waveform with playback progress colouring
// ---------------------------------------------------------------------------
class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;

  const _WaveformPainter({
    required this.samples,
    this.progress = 1.0,
    required this.playedColor,
    required this.unplayedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 3.0;
    const gap = 3.0;
    const step = barWidth + gap;
    const minBarHeight = 4.0;

    final maxBars = (size.width / step).floor();
    final drawSlice = samples.length > maxBars
        ? samples.sublist(samples.length - maxBars)
        : samples;

    final totalWidth = drawSlice.length * step - gap;
    double x = (size.width - totalWidth) / 2;
    final cy = size.height / 2;
    final playedCount = (drawSlice.length * progress).floor();

    for (int i = 0; i < drawSlice.length; i++) {
      final barHeight = minBarHeight + drawSlice[i] * (size.height - minBarHeight);
      final paint = Paint()
        ..color = i < playedCount ? playedColor : unplayedColor
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x + barWidth / 2, cy - barHeight / 2),
        Offset(x + barWidth / 2, cy + barHeight / 2),
        paint,
      );
      x += step;
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.samples != samples || old.progress != progress ||
      old.playedColor != playedColor || old.unplayedColor != unplayedColor;
}
