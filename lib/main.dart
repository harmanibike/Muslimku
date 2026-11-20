import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MuslimkuApp());
}

const Color green = Color(0xFF157A4B);
const Color greenDark = Color(0xFF0C4D2F);
const Color greenLight = Color(0xFF239B62);
const Color greenSoft = Color(0xFFE7F5EE);
const Color pageBg = Color(0xFFF4F7F5);
const Color ink = Color(0xFF182A22);
const Color muted = Color(0xFF6B7C73);

class MuslimkuApp extends StatelessWidget {
  const MuslimkuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Muslimku',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: pageBg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: green,
            surface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: pageBg,
            surfaceTintColor: Colors.transparent,
            foregroundColor: ink,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ink,
              letterSpacing: -0.3,
            ),
          ),
        ),
        home: const MainShell(),
      );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  final pages = const [
    HomePage(),
    PrayerPage(),
    QuranPage(),
    LibraryPage(),
    MorePage(),
  ];

  final titles = const [
    'Muslimku',
    'Waktu Salat',
    'Al-Qur’an',
    'Perpustakaan',
    'Lainnya',
  ];

  final navItems = const [
    (Icons.home_outlined, Icons.home_rounded, 'Beranda'),
    (Icons.access_time_outlined, Icons.access_time_filled_rounded, 'Salat'),
    (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Qur’an'),
    (Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Kitab'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Lainnya'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [greenLight, greenDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: green.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.nightlight_round,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                titles[index],
                key: ValueKey(titles[index]),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: ink,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(index),
          child: pages[index],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (i) {
                final selected = i == index;
                final item = navItems[i];
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (index != i) {
                        HapticFeedback.selectionClick();
                        setState(() => index = i);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? greenSoft : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected ? item.$2 : item.$1,
                            color: selected ? green : muted,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.$3,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w500,
                              color: selected ? greenDark : muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String _greeting(int hour) {
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5ECE8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_weekday(now.weekday)}, ${now.day} ${_month(now.month)} ${now.year}',
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [greenLight, green, greenDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: green.withOpacity(0.28),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -24,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: -18,
                child: Icon(
                  Icons.mosque_rounded,
                  size: 110,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ASSALAMU’ALAIKUM',
                        style: TextStyle(
                          color: Colors.white,
                          letterSpacing: 1.3,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${_greeting(now.hour)},\ndi Muslimku',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Teman ibadah harian Anda dengan jadwal salat, Al-Qur’an, dan doa.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Mulai ibadah hari ini'),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.92,
          children: [
            QuickTile(
              'Jadwal salat',
              Icons.access_time_filled_rounded,
              const Color(0xFFE6F4EC),
              green,
              () => _push(
                context,
                Scaffold(
                  appBar: AppBar(title: const Text('Waktu Salat')),
                  body: const PrayerPage(),
                ),
              ),
            ),
            QuickTile(
              'Al-Qur’an',
              Icons.menu_book_rounded,
              const Color(0xFFE6F2F8),
              const Color(0xFF1A6B96),
              () => _push(
                context,
                Scaffold(
                  appBar: AppBar(title: const Text('Al-Qur’an')),
                  body: const QuranPage(),
                ),
              ),
            ),
            QuickTile(
              'Murottal',
              Icons.headphones_rounded,
              const Color(0xFFF3ECFA),
              const Color(0xFF6B3FA0),
              () => _push(
                context,
                Scaffold(
                  appBar: AppBar(title: const Text('Murottal')),
                  body: const QuranPage(),
                ),
              ),
            ),
            QuickTile(
              'Arah kiblat',
              Icons.explore_rounded,
              const Color(0xFFFEF3E2),
              const Color(0xFFC2780A),
              () => _push(context, const QiblaPage()),
            ),
            QuickTile(
              'Tasbih',
              Icons.fingerprint_rounded,
              const Color(0xFFE8F5F3),
              const Color(0xFF0F766E),
              () => _push(context, const TasbihPage()),
            ),
            QuickTile(
              'Doa harian',
              Icons.volunteer_activism_rounded,
              const Color(0xFFFCEBF0),
              const Color(0xFFB83260),
              () => _push(context, const DuaPage()),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionTitle('Pengingat'),
        const SizedBox(height: 12),
        const InfoCard(
          icon: Icons.notifications_active_rounded,
          title: 'Jaga waktu salat',
          text:
              'Aktifkan izin notifikasi di perangkat untuk menerima pengingat ibadah. Jadwal salat dihitung otomatis dari lokasi perangkat.',
        ),
      ],
    );
  }
}

class PrayerTimesResult {
  final String regionName;
  final String province;
  final Map<String, String> times;
  final bool fromCache;

  const PrayerTimesResult({
    required this.regionName,
    required this.province,
    required this.times,
    required this.fromCache,
  });
}

class AladhanPrayerTimesService {
  static Future<PrayerTimesResult> loadForCurrentLocation() async {
    final position = await _getPosition();
    final now = DateTime.now();

    final dateStr = '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.year.toString().padLeft(4, '0')}';

    final lat = position.latitude;
    final lng = position.longitude;
    final cacheKey = 'aladhan_times_$dateStr';
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic>? data;
    var fromCache = false;

    try {
      final uri = Uri.parse(
        'https://api.aladhan.com/v1/timings/$dateStr'
        '?latitude=$lat&longitude=$lng&method=20',
      );
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception(
          'Server jadwal mengembalikan HTTP ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['data'] is! Map) {
        throw Exception('Format data jadwal dari server tidak sesuai.');
      }

      data = Map<String, dynamic>.from(decoded['data'] as Map);
      await prefs.setString(cacheKey, jsonEncode(data));
    } catch (e) {
      final cached = prefs.getString(cacheKey);
      if (cached == null) {
        throw Exception('Gagal memuat jadwal salat: $e');
      }
      final decoded = jsonDecode(cached);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Data offline rusak. Sambungkan internet lalu coba lagi.');
      }
      data = decoded;
      fromCache = true;
    }

    final timings = data['timings'] as Map<String, dynamic>? ?? {};
    final meta = data['meta'] as Map<String, dynamic>? ?? {};
    final timezone = (meta['timezone'] ?? 'Asia/Jakarta').toString();

    final place = await _getCityAndProvince(lat, lng, prefs, timezone);

    String cleanTime(String key) {
      final raw = timings[key]?.toString() ?? '--:--';
      return raw.split(' ').first;
    }

    final sunrise = cleanTime('Sunrise');
    final dhuha = _addMinutes(sunrise, 20);

    return PrayerTimesResult(
      regionName: place.$1,
      province: place.$2,
      fromCache: fromCache,
      times: {
        'Imsak': cleanTime('Imsak'),
        'Subuh': cleanTime('Fajr'),
        'Terbit': sunrise,
        'Duha': dhuha,
        'Zuhur': cleanTime('Dhuhr'),
        'Asar': cleanTime('Asr'),
        'Magrib': cleanTime('Maghrib'),
        'Isya': cleanTime('Isha'),
      },
    );
  }

  static Future<(String, String)> _getCityAndProvince(
    double lat,
    double lng,
    SharedPreferences prefs,
    String timezone,
  ) async {
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client'
        '?latitude=$lat&longitude=$lng&localityLanguage=id',
      );
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final city = (decoded['city']?.toString().trim().isNotEmpty == true)
              ? decoded['city'].toString().trim()
              : (decoded['locality']?.toString().trim().isNotEmpty == true)
                  ? decoded['locality'].toString().trim()
                  : 'Lokasi GPS Terdeteksi';

          final province = (decoded['principalSubdivision']
                      ?.toString()
                      .trim()
                      .isNotEmpty ==
                  true)
              ? decoded['principalSubdivision'].toString().trim()
              : timezone;

          await prefs.setString('last_city', city);
          await prefs.setString('last_province', province);
          return (city, province);
        }
      }
    } catch (_) {}

    final savedCity = prefs.getString('last_city');
    final savedProvince = prefs.getString('last_province');
    if (savedCity != null && savedCity.isNotEmpty) {
      return (savedCity, savedProvince ?? timezone);
    }

    return (
      'Lokasi GPS Terdeteksi',
      '${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)} • $timezone',
    );
  }

  static String _addMinutes(String hhmm, int minutesToAdd) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return '--:--';
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return '--:--';
    final total = (h * 60 + m + minutesToAdd) % (24 * 60);
    final newH = (total ~/ 60).toString().padLeft(2, '0');
    final newM = (total % 60).toString().padLeft(2, '0');
    return '$newH:$newM';
  }

  static Future<Position> _getPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception(
        'GPS belum aktif. Aktifkan lokasi perangkat lalu coba lagi.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermiss
