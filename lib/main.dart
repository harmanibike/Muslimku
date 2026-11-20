import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MuslimkuApp());

const Color green = Color(0xFF167A4A);
const Color greenDark = Color(0xFF105D39);
const Color greenSoft = Color(0xFFE8F3EC);
const Color pageBg = Color(0xFFF6F8F6);
const Color ink = Color(0xFF20332A);
const Color muted = Color(0xFF718078);

class MuslimkuApp extends StatelessWidget {
  const MuslimkuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Muslimku',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: pageBg,
          colorScheme: ColorScheme.fromSeed(seedColor: green),
          appBarTheme: const AppBarTheme(
            backgroundColor: pageBg,
            foregroundColor: ink,
            elevation: 0,
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 66,
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: greenSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.nightlight_round, color: green),
              ),
              const SizedBox(width: 10),
              Text(
                titles[index],
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: NavigationBar(
          height: 70,
          selectedIndex: index,
          onDestinationSelected: (v) => setState(() => index = v),
          backgroundColor: Colors.white,
          indicatorColor: greenSoft,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: green),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.access_time),
              selectedIcon: Icon(Icons.access_time_filled, color: green),
              label: 'Salat',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book, color: green),
              label: 'Qur’an',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories, color: green),
              label: 'Kitab',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view, color: green),
              label: 'Lainnya',
            ),
          ],
        ),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          '${_weekday(now.weekday)},${now.day} ${_month(now.month)}${now.year}',
          style: const TextStyle(color: muted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF218A59), greenDark],
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ASSALAMU’ALAIKUM',
                style: TextStyle(
                  color: Color(0xFFD8F0E1),
                  letterSpacing: 1.4,
                  fontSize: 11,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Selamat datang\ndi Muslimku',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Teman ibadah Anda setiap hari.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Mulai ibadah hari ini'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: .95,
          children: [
            QuickTile(
              'Jadwal salat',
              Icons.access_time,
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
              Icons.menu_book,
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
              Icons.headphones,
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
              Icons.explore,
              () => _push(context, const QiblaPage()),
            ),
            QuickTile(
              'Tasbih',
              Icons.fingerprint,
              () => _push(context, const TasbihPage()),
            ),
            QuickTile(
              'Doa harian',
              Icons.volunteer_activism,
              () => _push(context, const DuaPage()),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionTitle('Pengingat'),
        const SizedBox(height: 9),
        const InfoCard(
          icon: Icons.notifications_active_outlined,
          title: 'Jaga waktu salat',
          text:
              'Aktifkan izin notifikasi di perangkat untuk menerima pengingat ibadah. Jadwal salat dihitung dari lokasi perangkat.',
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
        '${now.month.toString().padLeft(2, '0')}-' '${now.year.toString().padLeft(4, '0')}';

    final lat = position.latitude;
    final lng = position.longitude;
    final cacheKey = 'aladhan_times_$dateStr';
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic>? data;
    var fromCache = false;

    try {
      // method=20 adalah metode Kementerian Agama Republik Indonesia (KEMENAG)
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
    } catch (
      
