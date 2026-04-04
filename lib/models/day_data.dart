import 'memory_item.dart';

class DayData {
  final DateTime date;
  final List<MemoryItem> memories;

  DayData({required this.date, required this.memories});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'memories': memories.map((e) => e.toJson()).toList(),
      };

  factory DayData.fromJson(Map<String, dynamic> json) => DayData(
        date: DateTime.parse(json['date']),
        memories: (json['memories'] as List).map((e) => MemoryItem.fromJson(e)).toList(),
      );
}
