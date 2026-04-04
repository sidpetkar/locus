enum MemoryType { image, video, audio, text }

class MemoryItem {
  final String id;
  final MemoryType type;
  final String content; // text content or local path to media
  final DateTime createdAt;
  final List<double>? waveformData; // Added for audio visuals

  MemoryItem({
    required this.id,
    required this.type,
    required this.content,
    required this.createdAt,
    this.waveformData,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'waveformData': waveformData,
      };

  factory MemoryItem.fromJson(Map<String, dynamic> json) => MemoryItem(
        id: json['id'],
        type: MemoryType.values[json['type']],
        content: json['content'],
        createdAt: DateTime.parse(json['createdAt']),
        waveformData: json['waveformData'] != null ? List<double>.from(json['waveformData'].map((x) => x.toDouble())) : null,
      );
}
