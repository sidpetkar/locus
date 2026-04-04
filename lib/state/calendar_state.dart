import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/day_data.dart';
import '../models/memory_item.dart';

class CalendarStateProvider extends ChangeNotifier {
  final Box _box;

  Map<String, DayData> _dayDataMap = {};
  
  // For the cross-screen search highlighting
  final ValueNotifier<DateTime?> pulseDate = ValueNotifier(null);

  CalendarStateProvider(this._box) {
    _loadFromHive();
  }

  void _loadFromHive() {
    _dayDataMap.clear();
    for (var key in _box.keys) {
      final jsonStr = _box.get(key) as String;
      _dayDataMap[key.toString()] = DayData.fromJson(jsonDecode(jsonStr));
    }
    notifyListeners();
  }

  DayData getDayData(DateTime date) {
    final key = _formatDateKey(date);
    return _dayDataMap[key] ?? DayData(date: date, memories: []);
  }

  void addMemory(DateTime date, MemoryItem item) {
    final key = _formatDateKey(date);
    final currentData = getDayData(date);
    final updatedMemories = List<MemoryItem>.from(currentData.memories)..add(item);
    
    final updatedData = DayData(date: date, memories: updatedMemories);
    _dayDataMap[key] = updatedData;
    
    _box.put(key, jsonEncode(updatedData.toJson()));
    notifyListeners();
  }

  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
