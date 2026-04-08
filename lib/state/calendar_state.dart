import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/day_data.dart';
import '../models/memory_item.dart';
import '../models/user_profile.dart';

enum AppThemeMode { system, light, dark, timeAware }

class CalendarStateProvider extends ChangeNotifier {
  final Box _box;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, DayData> _dayDataMap = {};
  Map<String, DayData> _firestoreDataMap = {};
  
  User? _currentUser;
  UserProfile? _userProfile;
  StreamSubscription? _authSubscription;
  StreamSubscription? _firestoreSubscription;

  DateTime? _birthday;
  AppThemeMode _appThemeMode = AppThemeMode.light;
  bool _nudgesEnabled = true;

  final ValueNotifier<DateTime?> pulseDate = ValueNotifier(null);

  CalendarStateProvider(this._box) {
    _loadFromHive();
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((user) async {
      _currentUser = user;
      if (user != null) {
        _setupFirestoreListener(user.uid);
        await _loadUserProfile(user.uid);
      } else {
        _firestoreSubscription?.cancel();
        _firestoreDataMap.clear();
        _userProfile = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userProfile = UserProfile.fromJson(doc.data()!);
        // Load birthday from Firestore if available
        final data = doc.data()!;
        if (data['birthday'] != null) {
          _birthday = DateTime.tryParse(data['birthday'] as String);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading user profile: $e");
    }
  }

  DateTime? get birthday => _birthday;

  AppThemeMode get appThemeMode => _appThemeMode;

  bool get isTimeAwareMode => _appThemeMode == AppThemeMode.timeAware;

  bool get nudgesEnabled => _nudgesEnabled;

  Future<void> setNudgesEnabled(bool value) async {
    _nudgesEnabled = value;
    await _box.put('nudges_enabled', value);
    notifyListeners();
  }

  /// Maps our custom enum to Flutter's ThemeMode for MaterialApp.
  /// Time-aware mode uses the dark scaffold/chrome.
  ThemeMode get flutterThemeMode {
    switch (_appThemeMode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.timeAware:
        return ThemeMode.dark;
    }
  }

  Future<void> setAppThemeMode(AppThemeMode mode) async {
    _appThemeMode = mode;
    await _box.put('app_theme_mode', mode.index);
    notifyListeners();
  }

  Future<void> setBirthday(DateTime date) async {
    _birthday = date;
    // Persist locally in Hive
    await _box.put('user_birthday', date.toIso8601String());
    // Persist remotely if logged in
    if (isLoggedIn) {
      try {
        await _firestore.collection('users').doc(_currentUser!.uid).update({
          'birthday': date.toIso8601String(),
        });
      } catch (e) {
        debugPrint("Error saving birthday to Firestore: $e");
      }
    }
    notifyListeners();
  }

  void _setupFirestoreListener(String uid) {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('days')
        .snapshots()
        .listen((snapshot) {
      _firestoreDataMap.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _firestoreDataMap[doc.id] = DayData.fromJson(data);
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  bool get isLoggedIn => _currentUser != null;
  User? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;
  String? get username => _userProfile?.username;

  void _loadFromHive() {
    _dayDataMap.clear();
    for (var key in _box.keys) {
      if (key == 'user_birthday') continue;
      if (key == 'app_theme_mode') continue;
      if (key == 'nudges_enabled') continue;
      final jsonStr = _box.get(key) as String;
      _dayDataMap[key.toString()] = DayData.fromJson(jsonDecode(jsonStr));
    }
    // Load birthday from Hive
    final birthdayStr = _box.get('user_birthday') as String?;
    if (birthdayStr != null) {
      _birthday = DateTime.tryParse(birthdayStr);
    }
    // Load theme mode from Hive
    final themeModeInt = _box.get('app_theme_mode') as int?;
    if (themeModeInt != null) {
      _appThemeMode = AppThemeMode.values[themeModeInt.clamp(0, AppThemeMode.values.length - 1)];
    }
    // Load nudges toggle (defaults to true if not set)
    final nudgesVal = _box.get('nudges_enabled');
    if (nudgesVal is bool) {
      _nudgesEnabled = nudgesVal;
    }
    notifyListeners();
  }

  DayData getDayData(DateTime date) {
    final key = _formatDateKey(date);
    if (isLoggedIn) {
      return _firestoreDataMap[key] ?? DayData(date: date, memories: []);
    }
    return _dayDataMap[key] ?? DayData(date: date, memories: []);
  }

  Future<void> addMemory(DateTime date, MemoryItem item) async {
    return addMemories(date, [item]);
  }

  Future<void> addMemories(DateTime date, List<MemoryItem> items) async {
    if (items.isEmpty) return;
    final key = _formatDateKey(date);
    final currentData = getDayData(date);
    final updatedMemories = List<MemoryItem>.from(currentData.memories)..addAll(items);
    final updatedData = DayData(date: date, memories: updatedMemories);

    if (isLoggedIn) {
      _firestoreDataMap[key] = updatedData;
      notifyListeners();
      try {
        await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('days')
            .doc(key)
            .set(updatedData.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error adding memories to Firestore: $e");
      }
    } else {
      _dayDataMap[key] = updatedData;
      await _box.put(key, jsonEncode(updatedData.toJson()));
      notifyListeners();
    }
  }

  /// Swap a memory's content (e.g. local path → Firebase URL) after a
  /// background upload finishes. No-op if the item no longer exists.
  Future<void> updateMemoryContent(DateTime date, String itemId, String newContent) async {
    final key = _formatDateKey(date);
    final currentData = getDayData(date);
    final idx = currentData.memories.indexWhere((m) => m.id == itemId);
    if (idx == -1) return;

    final old = currentData.memories[idx];
    final updated = MemoryItem(
      id: old.id,
      type: old.type,
      content: newContent,
      createdAt: old.createdAt,
      waveformData: old.waveformData,
    );

    final updatedMemories = List<MemoryItem>.from(currentData.memories);
    updatedMemories[idx] = updated;
    final updatedData = DayData(date: date, memories: updatedMemories);

    if (isLoggedIn) {
      _firestoreDataMap[key] = updatedData;
      notifyListeners();
      try {
        await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('days')
            .doc(key)
            .set(updatedData.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error updating memory content: $e");
      }
    } else {
      _dayDataMap[key] = updatedData;
      await _box.put(key, jsonEncode(updatedData.toJson()));
      notifyListeners();
    }
  }

  Future<void> removeMemory(DateTime date, String itemId) async {
    final key = _formatDateKey(date);
    final currentData = getDayData(date);
    
    // Find the item first to check for Firebase Storage URLs
    final itemToRemove = currentData.memories.firstWhere((m) => m.id == itemId, 
      orElse: () => MemoryItem(id: '', type: MemoryType.text, content: '', createdAt: DateTime.now()));

    if (itemToRemove.id.isEmpty) return;

    // Delete from Firebase Storage if it's a hosted file
    if (isLoggedIn && itemToRemove.content.startsWith('https://firebasestorage.googleapis.com')) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(itemToRemove.content);
        await ref.delete();
      } catch (e) {
        debugPrint("Error deleting file from storage: $e");
      }
    }

    final updatedMemories = List<MemoryItem>.from(currentData.memories)
      ..removeWhere((m) => m.id == itemId);
    final updatedData = DayData(date: date, memories: updatedMemories);

    if (isLoggedIn) {
      if (updatedMemories.isEmpty) {
        _firestoreDataMap.remove(key);
      } else {
        _firestoreDataMap[key] = updatedData;
      }
      notifyListeners();
      try {
        if (updatedMemories.isEmpty) {
          await _firestore
              .collection('users')
              .doc(_currentUser!.uid)
              .collection('days')
              .doc(key)
              .delete();
        } else {
          await _firestore
              .collection('users')
              .doc(_currentUser!.uid)
              .collection('days')
              .doc(key)
              .set(updatedData.toJson());
        }
      } catch (e) {
        debugPrint("Error removing memory from Firestore: $e");
      }
    } else {
      _dayDataMap[key] = updatedData;
      await _box.put(key, jsonEncode(updatedData.toJson()));
      notifyListeners();
    }
  }

  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
