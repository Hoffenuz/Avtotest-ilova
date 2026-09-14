import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'app_strings.dart';
import 'question_service.dart';

/// A question a day, as a notification.
///
/// WHY A QUESTION AND NOT A REMINDER: "come back and study" is a nag people
/// turn off. A real question with a real answer is worth opening on its own,
/// and answering one is the smallest possible unit of practice — which is the
/// point. Tapping it opens the app.
///
/// Everything here is local. The question bank is already on the device, so
/// there is no server, no push token, no account required, and it works with
/// the phone in flight mode.
class DailyQuestionService {
  DailyQuestionService._();

  static const _enabledKey = 'daily_question_enabled';
  static const _hourKey = 'daily_question_hour';

  /// Fires in the evening by default — after work, before bed, when someone
  /// actually has five minutes.
  static const int defaultHour = 20;

  /// Android channel. Named so it is recognisable in system settings, where
  /// the user may well go to silence it.
  static const _channelId = 'daily_question';

  /// One fixed id, so scheduling again replaces the pending one rather than
  /// stacking up a queue of yesterdays.
  static const int _notificationId = 1001;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static bool _initialized = false;

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<int> hour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_hourKey) ?? defaultHour;
  }

  static Future<void> _init() async {
    if (_initialized || !isSupported) return;
    tz.initializeTimeZones();
    // Uzbekistan has no DST and one zone, so this is exact rather than a
    // guess; getting it wrong would fire the notification at the wrong hour.
    tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  /// Asks the OS for permission. Returns false if the user declined, which is
  /// their answer and must be respected — the toggle stays off.
  static Future<bool> requestPermission() async {
    if (!isSupported) return false;
    await _init();
    try {
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await android?.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    } catch (e) {
      debugPrint('DailyQuestionService.requestPermission: $e');
      return false;
    }
  }

  /// Turns the daily question on or off and (re)schedules accordingly.
  static Future<bool> setEnabled(
    bool enabled, {
    required String lang,
    int? atHour,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (!enabled) {
      await prefs.setBool(_enabledKey, false);
      await cancel();
      return false;
    }

    final granted = await requestPermission();
    if (!granted) {
      await prefs.setBool(_enabledKey, false);
      return false;
    }

    await prefs.setBool(_enabledKey, true);
    if (atHour != null) await prefs.setInt(_hourKey, atHour);
    await schedule(lang: lang);
    return true;
  }

  static Future<void> setHour(int value, {required String lang}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, value.clamp(0, 23));
    if (await isEnabled()) await schedule(lang: lang);
  }

  /// Schedules tomorrow's (or today's, if the hour has not passed) question.
  ///
  /// Only ONE is ever pending. A daily repeat with a *different* question each
  /// day is not something the OS can do on its own — the app has to pick the
  /// question — so it re-schedules whenever it is opened. Someone who never
  /// opens the app still gets the one that is already queued, which is exactly
  /// the person the reminder is for.
  static Future<void> schedule({required String lang}) async {
    if (!isSupported || !await isEnabled()) return;
    await _init();

    try {
      final questions = await QuestionService.loadAllQuestions();
      if (questions.isEmpty) return;

      // Seeded by the day, so the same day always yields the same question —
      // re-scheduling on every app open must not shuffle it.
      final now = tz.TZDateTime.now(tz.local);
      final daySeed = now.year * 10000 + now.month * 100 + now.day;
      final question = questions[Random(daySeed).nextInt(questions.length)];

      final at = _nextOccurrence(await hour());

      await _plugin.zonedSchedule(
        id: _notificationId,
        title: AppStrings.get('daily_question_title', lang),
        body: question.getText(lang),
        scheduledDate: at,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            AppStrings.get('daily_question', lang),
            channelDescription: AppStrings.get('daily_question_sub', lang),
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            // The question is longer than one line; without this it is cut off
            // and the notification is useless.
            styleInformation: BigTextStyleInformation(question.getText(lang)),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // A reminder is a convenience. It must never be why anything else fails.
      debugPrint('DailyQuestionService.schedule: $e');
    }
  }

  static tz.TZDateTime _nextOccurrence(int atHour) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, atHour);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next;
  }

  static Future<void> cancel() async {
    if (!isSupported) return;
    await _init();
    try {
      await _plugin.cancel(id: _notificationId);
    } catch (e) {
      debugPrint('DailyQuestionService.cancel: $e');
    }
  }

  /// Called at start-up: keeps the queued question current without the user
  /// having to do anything.
  static Future<void> refreshOnLaunch({required String lang}) async {
    if (!isSupported) return;
    if (!await isEnabled()) return;
    await schedule(lang: lang);
  }
}
