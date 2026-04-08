import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum NotificationSlot { morning, afternoon, evening, night }

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  factory NotificationService() => instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'locus_daily';
  static const _channelName = 'Daily Reminders';
  static const _channelDesc = 'Four daily nudges to capture your life';

  // ── ID ranges: morning 1000-1013, afternoon 2000, evening 3000, night 4000
  static const _morningBaseId = 1000;
  static const _afternoonBaseId = 2000;
  static const _eveningBaseId = 3000;
  static const _nightBaseId = 4000;

  // ── Fixed times within each window ──
  static const _morningHour = 7;
  static const _afternoonHour = 13;
  static const _eveningHour = 18;
  static const _eveningMinute = 30;
  static const _nightHour = 22;
  static const _nightMinute = 30;

  // ── Copy pools ──

  static const List<String> _morningMessages = [
    "The obstacle is the way. What will you conquer today?",
    "Amor fati — love what is. Now go make something of it.",
    "You woke up. Millions didn't. That's your edge. Use it.",
    "Discipline equals freedom. What's one thing you'll own today?",
    "The sun doesn't wait. Neither should you.",
    "Memento mori. Today is not guaranteed — make it count.",
    "A stoic doesn't hope for an easy day. They prepare for a worthy one.",
    "You've survived every bad day so far. Today, go beyond surviving.",
    "No one's coming to save your morning. You are the cavalry.",
    "Be the person your future self will thank.",
    "What stands in the way becomes the way. Move.",
    "Your comfort zone is where ambition goes to die. Step out.",
    "Marcus Aurelius ruled an empire and journaled daily. You can too.",
    "This morning is raw material. Shape it with intention.",
    "The best time to plant a tree was 20 years ago. Second best is right now.",
    "Waste no more time arguing about what a good person should be. Be one.",
    "You control your effort and your attitude. Nothing else matters.",
    "Rise. Not because it's easy, but because you chose this life.",
    "Every morning is a small resurrection. What will you do with yours?",
    "Difficulty is what wakes up the genius. Let's go.",
  ];

  static const List<String> _afternoonMessages = [
    "Something just happened worth remembering. Capture it.",
    "What's around you right now? Snap it. Describe it. Save it.",
    "Your afternoon self has stories your evening self will forget.",
    "One photo. One voice note. One sentence. That's all it takes.",
    "Life is happening — don't let this moment dissolve into routine.",
    "The best memories hide in ordinary moments. Look around.",
    "Midday check-in: what made you smile in the last hour?",
    "Quick — what's one thing you'd tell someone about today so far?",
  ];

  static const List<String> _eveningMessages = [
    "Put the phone down. Call someone you love.",
    "The commute home is short. The memories are long. Be present.",
    "Dinner with friends, a walk alone, a sunset — enjoy it fully.",
    "Life isn't just work. Who can you make smile tonight?",
    "The people around you right now — they won't be here forever.",
    "Send that text. Make that call. Show up for someone.",
    "Evenings are for living, not scrolling. Look up.",
    "The best part of your day might be happening right now. Notice it.",
  ];

  static const List<String> _nightMessages = [
    "No pressure. Just you and today. What was the highlight?",
    "Before you sleep — one thing you're grateful for today?",
    "Your day had a story. Take 30 seconds to save it.",
    "No judgement, no rules. Just — what happened today?",
    "Tomorrow you'll barely remember today. Unless you write it down.",
    "End the day with yourself. What moment made you feel alive?",
    "It's just you and your thoughts now. Let them out.",
    "The world is quiet. Perfect time to capture today's chapter.",
  ];

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Request Android 13+ notification permission
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  Future<void> scheduleAll() async {
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);

    // Morning: unique copy per day for 14 days, no repeats within 2 weeks
    final morningIndices = _pickMorningIndices(14);
    for (var i = 0; i < 14; i++) {
      final scheduled = _nextInstanceOfTime(
        now.add(Duration(days: i)),
        _morningHour,
        0,
      );
      if (scheduled.isAfter(now)) {
        await _scheduleOne(
          id: _morningBaseId + i,
          title: 'Locus',
          body: _morningMessages[morningIndices[i]],
          when: scheduled,
        );
      }
    }

    // Afternoon: 14 days, random pick from pool each day
    for (var i = 0; i < 14; i++) {
      final scheduled = _nextInstanceOfTime(
        now.add(Duration(days: i)),
        _afternoonHour,
        0,
      );
      if (scheduled.isAfter(now)) {
        await _scheduleOne(
          id: _afternoonBaseId + i,
          title: 'Locus',
          body: _afternoonMessages[i % _afternoonMessages.length],
          when: scheduled,
        );
      }
    }

    // Evening: 14 days
    for (var i = 0; i < 14; i++) {
      final scheduled = _nextInstanceOfTime(
        now.add(Duration(days: i)),
        _eveningHour,
        _eveningMinute,
      );
      if (scheduled.isAfter(now)) {
        await _scheduleOne(
          id: _eveningBaseId + i,
          title: 'Locus',
          body: _eveningMessages[i % _eveningMessages.length],
          when: scheduled,
        );
      }
    }

    // Night: 14 days
    for (var i = 0; i < 14; i++) {
      final scheduled = _nextInstanceOfTime(
        now.add(Duration(days: i)),
        _nightHour,
        _nightMinute,
      );
      if (scheduled.isAfter(now)) {
        await _scheduleOne(
          id: _nightBaseId + i,
          title: 'Locus',
          body: _nightMessages[i % _nightMessages.length],
          when: scheduled,
        );
      }
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Fire an immediate test notification for the given [slot].
  Future<void> triggerTestNotification(NotificationSlot slot) async {
    final rng = Random();
    late String body;
    late int id;

    switch (slot) {
      case NotificationSlot.morning:
        body = _morningMessages[rng.nextInt(_morningMessages.length)];
        id = 9000;
        break;
      case NotificationSlot.afternoon:
        body = _afternoonMessages[rng.nextInt(_afternoonMessages.length)];
        id = 9001;
        break;
      case NotificationSlot.evening:
        body = _eveningMessages[rng.nextInt(_eveningMessages.length)];
        id = 9002;
        break;
      case NotificationSlot.night:
        body = _nightMessages[rng.nextInt(_nightMessages.length)];
        id = 9003;
        break;
    }

    await _plugin.show(
      id,
      'Locus (${slot.name})',
      body,
      _notificationDetails(),
    );
  }

  // ── Helpers ──

  List<int> _pickMorningIndices(int count) {
    try {
      final box = Hive.box('calendarBox');
      final usedRaw = box.get('used_morning_indices') as List<dynamic>? ?? [];
      final used = usedRaw.cast<int>().toSet();

      var available =
          List.generate(_morningMessages.length, (i) => i)
              .where((i) => !used.contains(i))
              .toList();

      if (available.length < count) {
        available = List.generate(_morningMessages.length, (i) => i);
        used.clear();
      }

      available.shuffle(Random());
      final picked = available.take(count).toList();

      final newUsed = {...used, ...picked}.toList();
      if (newUsed.length >= _morningMessages.length) {
        box.put('used_morning_indices', picked);
      } else {
        box.put('used_morning_indices', newUsed);
      }

      return picked;
    } catch (e) {
      debugPrint('Error picking morning indices: $e');
      final indices = List.generate(_morningMessages.length, (i) => i);
      indices.shuffle(Random());
      return indices.take(count).toList();
    }
  }

  tz.TZDateTime _nextInstanceOfTime(DateTime base, int hour, int minute) {
    return tz.TZDateTime(
      tz.local,
      base.year,
      base.month,
      base.day,
      hour,
      minute,
    );
  }

  Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }
}
