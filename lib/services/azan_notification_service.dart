import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class AzanNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'muslimku_azan_v1';
  static const String _channelName = 'Notifikasi Azan';
  static const String _channelDesc = 'Pengingat waktu salat (Zuhur, Asar, Magrib, Isya)';

  static const String _subuhChannelId = 'muslimku_azan_subuh_v1';
  static const String _subuhChannelName = 'Notifikasi Azan Subuh';
  static const String _subuhChannelDesc = 'Pengingat waktu salat Subuh dengan suara azan Subuh';

  static const List<String> prayerKeys = ['Subuh', 'Zuhur', 'Asar', 'Magrib', 'Isya'];

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    _setLocalTimezone();

    const androidInit = AndroidInitializationSettings('@android:drawable/sym_def_app_icon');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        if (response.actionId == 'stop_azan') {
          await stopAllAzan();
        }
      },
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  static void _setLocalTimezone() {
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    String locationName = 'Asia/Jakarta';
    if (offsetHours == 8) {
      locationName = 'Asia/Makassar';
    } else if (offsetHours == 9) {
      locationName = 'Asia/Jayapura';
    }
    try {
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }
  }

  static NotificationDetails _azanDetails({bool isSubuh = false}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        isSubuh ? _subuhChannelId : _channelId,
        isSubuh ? _subuhChannelName : _channelName,
        channelDescription: isSubuh ? _subuhChannelDesc : _channelDesc,
        importance: Importance.max,
        priority: Priority.max,
        sound: RawResourceAndroidNotificationSound(isSubuh ? 'azan_subuh' : 'azan'),
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        autoCancel: true,
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            'stop_azan',
            'Hentikan Azan',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
    );
  }

  static Future<void> scheduleDailyPrayers(Map<String, String> times) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('azan_enabled') ?? true;

    for (int i = 0; i < prayerKeys.length; i++) {
      await _plugin.cancel(100 + i);
    }
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < prayerKeys.length; i++) {
      final name = prayerKeys[i];
      final prayerEnabled = prefs.getBool('azan_$name') ?? true;
      if (!prayerEnabled) continue;

      final hhmm = times[name];
      if (hhmm == null) continue;
      final parts = hhmm.split(':');
      if (parts.length != 2) continue;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) continue;

      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final isSubuh = name == 'Subuh';

      try {
        await _plugin.zonedSchedule(
          100 + i,
          'Waktu Salat $name',
          'Telah masuk waktu salat $name ($hhmm). Mari tunaikan salat.',
          scheduled,
          _azanDetails(isSubuh: isSubuh),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {
        await _plugin.zonedSchedule(
          100 + i,
          'Waktu Salat $name',
          'Telah masuk waktu salat $name ($hhmm). Mari tunaikan salat.',
          scheduled,
          _azanDetails(isSubuh: isSubuh),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  static Future<void> testAzan({bool isSubuh = false}) async {
    await init();
    await _plugin.show(
      999,
      isSubuh ? 'Tes Notifikasi Azan Subuh' : 'Tes Notifikasi Azan',
      'Suara azan offline aktif. Tekan "Hentikan Azan" untuk mematikan.',
      _azanDetails(isSubuh: isSubuh),
    );
  }

  static Future<void> stopAllAzan() async {
    await init();
    await _plugin.cancel(999);
    for (int i = 0; i < prayerKeys.length; i++) {
      await _plugin.cancel(100 + i);
    }
  }
}
