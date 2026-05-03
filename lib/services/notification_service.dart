import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _dailyId = 1;
  static const _weeklyId = 2;
  static const _keyDaily = 'notif_daily';
  static const _keyWeekly = 'notif_weekly';

  // Sabit kanal ID'leri — değiştirilmemeli (Android kanal kaydı kalıcıdır)
  static const _channelIdDaily  = 'stilya_daily_reminder';
  static const _channelIdWeekly = 'stilya_weekly_agenda';

  // ── Başlatma ──────────────────────────────────────────────────────
  Future<void> init() async {
    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );
  }

  // ── İzin iste (Android 13+) ───────────────────────────────────────
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  // ── Kayıtlı tercihleri oku ────────────────────────────────────────
  Future<Map<String, bool>> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      _keyDaily: prefs.getBool(_keyDaily) ?? false,
      _keyWeekly: prefs.getBool(_keyWeekly) ?? false,
    };
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // ── Günlük sabah hatırlatıcı (08:00) ──────────────────────────────
  Future<void> scheduleDailyReminder(bool enable) async {
    await _savePref(_keyDaily, enable);
    if (!enable) {
      await _plugin.cancel(id: _dailyId);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, 8, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _dailyId,
      title: 'Günaydın! ☀️',
      body: 'Bugün ne giyeceğini planladın mı? Stilya seni bekliyor.',
      scheduledDate: scheduled,
      notificationDetails: _details(_channelIdDaily, 'Günlük Hatırlatıcı'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── Haftalık ajanda hatırlatıcı (Pazar 20:00) ─────────────────────
  Future<void> scheduleWeeklyReminder(bool enable) async {
    await _savePref(_keyWeekly, enable);
    if (!enable) {
      await _plugin.cancel(id: _weeklyId);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var daysUntilSunday = (DateTime.sunday - now.weekday + 7) % 7;
    if (daysUntilSunday == 0 && now.hour >= 20) daysUntilSunday = 7;

    final scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysUntilSunday,
      20,
      0,
    );

    await _plugin.zonedSchedule(
      id: _weeklyId,
      title: 'Haftana hazır mısın? 📅',
      body: 'Bu haftanın kombinlerini planlamak için Ajanda\'ya bak!',
      scheduledDate: scheduled,
      notificationDetails: _details(_channelIdWeekly, 'Haftalık Ajanda'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ── Tüm bildirimleri iptal et ─────────────────────────────────────
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    await _savePref(_keyDaily, false);
    await _savePref(_keyWeekly, false);
  }

  NotificationDetails _details(String channelId, String channelName) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }
}
