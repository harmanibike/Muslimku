import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class AzanNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // v2 penting: suara pada notification channel Android bersifat immutable
  // setelah channel pertama kali dibuat.
  static const String _channelId = 'muslimku_azan_v3';
  static const String _channelName = 'Notifikasi Azan';
  static const String _channelDesc =
      'Pengingat waktu salat Zuhur, Asar, Magrib, dan Isya';
  static const String _subuhChannelId = 'muslimku_azan_subuh_v3';
  static const String _subuhChannelName = 'Notifikasi Azan Subuh';
  static const String _subuhChannelDesc =
      'Pengingat waktu salat Subuh dengan suara azan Subuh';

  static const List<String> prayerKeys = ['Subuh', 'Zuhur', 'Asar', 'Magrib', 'Isya'];
  static const int _firstPrayerId = 100;
  static const int _testNotificationId = 999;
  static final AudioPlayer _testPlayer = AudioPlayer();
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
          // Hanya menghentikan suara/notifikasi yang sedang tampil. Jangan
          // membatalkan jadwal salat hari-hari berikutnya.
          await _testPlayer.stop();
          await _plugin.cancel(response.id ?? _testNotificationId);
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
    final locationName = switch (offsetHours) {
      8 => 'Asia/Makassar',
      9 => 'Asia/Jayapura',
      _ => 'Asia/Jakarta',
    };
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
        sound: RawResourceAndroidNotificationSound(
          isSubuh ? 'azan_subuh' : 'azan',
        ),
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        autoCancel: false,
        ongoing: true,
        actions: const [
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

    for (var i = 0; i < prayerKeys.length; i++) {
      await _plugin.cancel(_firstPrayerId + i);
    }
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    for (var i = 0; i < prayerKeys.length; i++) {
      final name = prayerKeys[i];
      if (!(prefs.getBool('azan_$name') ?? true)) continue;
      final hhmm = times[name];
      if (hhmm == null || !_isValidTime(hhmm)) continue;
      final parts = hhmm.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
      if (!scheduled.isAfter(now)) scheduled = scheduled.add(const Duration(days: 1));
      final isSubuh = name == 'Subuh';

      try {
        await _schedule(_firstPrayerId + i, name, hhmm, scheduled, isSubuh,
            AndroidScheduleMode.exactAllowWhileIdle);
      } catch (_) {
        // Tetap berfungsi pada perangkat yang tidak memberi akses exact alarm.
        await _schedule(_firstPrayerId + i, name, hhmm, scheduled, isSubuh,
            AndroidScheduleMode.inexactAllowWhileIdle);
      }
    }
  }

  static bool _isValidTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    return h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60;
  }

  static Future<void> _schedule(
    int id,
    String name,
    String hhmm,
    tz.TZDateTime scheduled,
    bool isSubuh,
    AndroidScheduleMode mode,
  ) {
    return _plugin.zonedSchedule(
      id,
      'Waktu Salat $name',
      'Telah masuk waktu salat $name ($hhmm). Mari tunaikan salat.',
      scheduled,
      _azanDetails(isSubuh: isSubuh),
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> testAzan({bool isSubuh = false}) async {
    // Putar langsung dari aset Flutter agar tombol uji tetap membuktikan
    // audio bekerja walaupun izin notifikasi perangkat belum diberikan.
    await _testPlayer.stop();
    await _testPlayer.play(AssetSource(
      isSubuh ? 'audio/azan_subuh.mp3' : 'audio/azan.mp3',
    ));
    try {
      await init();
      await _plugin.show(
        _testNotificationId,
        isSubuh ? 'Tes Notifikasi Azan Subuh' : 'Tes Notifikasi Azan',
        'Suara azan offline sedang diputar.',
        _azanDetails(isSubuh: isSubuh),
      );
    } catch (_) {
      // Audio langsung tetap menjadi fallback ketika notifikasi diblokir.
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('azan_enabled', enabled);
    if (!enabled) {
      await stopAllAzan();
    }
  }

  static Future<void> setPrayerEnabled(String prayer, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('azan_$prayer', enabled);
    if (!enabled) {
      final index = prayerKeys.indexOf(prayer);
      if (index >= 0) {
        await init();
        await _plugin.cancel(_firstPrayerId + index);
      }
    }
  }

  static Future<void> stopTestAzan() async {
    await _testPlayer.stop();
    if (_initialized) await _plugin.cancel(_testNotificationId);
  }

  static Future<void> stopAllAzan() async {
    await init();
    await _testPlayer.stop();
    await _plugin.cancel(_testNotificationId);
    for (var i = 0; i < prayerKeys.length; i++) {
      await _plugin.cancel(_firstPrayerId + i);
    }
  }
}
