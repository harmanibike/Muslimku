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

import 'services/prayer_times_service.dart';
import 'services/azan_notification_service.dart';
import 'data/kitab_data.dart';
import 'services/kitab_data_service.dart';
import 'screens/sholawat_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
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
          colorScheme: ColorScheme.fromSeed(seedColor: green, surface: Colors.white),
          appBarTheme: const AppBarTheme(
            backgroundColor: pageBg,
            surfaceTintColor: Colors.transparent,
            foregroundColor: ink,
            elevation: 0,
            titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink),
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
  final List<(String, Widget)> subPages = [];

  @override
  void initState() {
    super.initState();
    // Activity Android sudah terpasang setelah frame pertama. Meminta izin
    // sebelum titik ini dapat membuat POST_NOTIFICATIONS tidak muncul.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AzanNotificationService.init());
    });
  }

  void _selectTab(int newIndex) {
    if (index != newIndex || subPages.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        index = newIndex;
        subPages.clear();
      });
    }
  }

  void openSubPage(String title, Widget page) {
    HapticFeedback.selectionClick();
    setState(() => subPages.add((title, page)));
  }

  void updateTopSubPageTitle(String title) {
    if (subPages.isEmpty || !mounted) return;
    final lastIdx = subPages.length - 1;
    if (subPages[lastIdx].$1 == title) return;
    setState(() {
      subPages[lastIdx] = (title, subPages[lastIdx].$2);
    });
  }

  void _popSubPage() {
    if (subPages.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() => subPages.removeLast());
    }
  }

  final titles = const ['Muslimku', 'Waktu Salat', 'Al-Qur’an', 'Perpustakaan', 'Lainnya'];
  final navItems = const [
    (Icons.home_outlined, Icons.home_rounded, 'Beranda'),
    (Icons.access_time_outlined, Icons.access_time_filled_rounded, 'Salat'),
    (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Qur’an'),
    (Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Kitab'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Lainnya'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onSelectTab: _selectTab),
      const PrayerPage(),
      const QuranPage(),
      const LibraryPage(),
      const MorePage(),
    ];

    final hasSub = subPages.isNotEmpty;
    final currentTitle = hasSub ? subPages.last.$1 : titles[index];
    final currentBody = hasSub ? subPages.last.$2 : pages[index];
    final currentKey = hasSub
        ? ValueKey('sub_${subPages.length}_${subPages.last.$1}')
        : ValueKey('tab_$index');

    return PopScope(
      canPop: !hasSub,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && subPages.isNotEmpty) {
          _popSubPage();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 68,
          automaticallyImplyLeading: false,
          title: Row(children: [
            if (hasSub) ...[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5ECE8)),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: _popSubPage,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: ink),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [greenLight, greenDark]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: green.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.nightlight_round, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    currentTitle,
                    key: ValueKey(currentTitle),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink),
                  ),
                ),
              ),
            ),
          ]),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: KeyedSubtree(key: currentKey, child: currentBody),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: List.generate(navItems.length, (i) {
                  final sel = !hasSub && i == index;
                  final item = navItems[i];
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _selectTab(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? greenSoft : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(sel ? item.$2 : item.$1, color: sel ? green : muted, size: 24),
                          const SizedBox(height: 4),
                          Text(item.$3, style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w800 : FontWeight.w500, color: sel ? greenDark : muted)),
                        ]),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuranBookmarkStore {
  static const _lastReadKey = 'quran_last_read';
  static const _bookmarksKey = 'quran_bookmarks';

  static Future<Map<String, dynamic>?> getLastRead() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_lastReadKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setLastRead({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _lastReadKey,
      jsonEncode({
        'surahNumber': surahNumber,
        'surahName': surahName,
        'ayahNumber': ayahNumber,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_bookmarksKey) ?? const [];
    final result = <Map<String, dynamic>>[];
    for (final item in list) {
      try {
        result.add(Map<String, dynamic>.from(jsonDecode(item) as Map));
      } catch (_) {}
    }
    return result;
  }

  static Future<bool> toggleBookmark({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
    required String arabText,
    required String translation,
  }) async {
    final p = await SharedPreferences.getInstance();
    final current = await getBookmarks();
    final id = '$surahNumber:$ayahNumber';
    final existsIdx = current.indexWhere((e) => '${e['surahNumber']}:${e['ayahNumber']}' == id);
    bool added;
    if (existsIdx >= 0) {
      current.removeAt(existsIdx);
      added = false;
    } else {
      current.insert(0, {
        'surahNumber': surahNumber,
        'surahName': surahName,
        'ayahNumber': ayahNumber,
        'arabText': arabText,
        'translation': translation,
        'savedAt': DateTime.now().toIso8601String(),
      });
      added = true;
    }
    await p.setStringList(_bookmarksKey, current.map((e) => jsonEncode(e)).toList());
    return added;
  }

  static Future<void> removeBookmark(int surahNumber, int ayahNumber) async {
    final p = await SharedPreferences.getInstance();
    final current = await getBookmarks();
    current.removeWhere((e) => e['surahNumber'] == surahNumber && e['ayahNumber'] == ayahNumber);
    await p.setStringList(_bookmarksKey, current.map((e) => jsonEncode(e)).toList());
  }
}

class HomePage extends StatefulWidget {
  final ValueChanged<int> onSelectTab;
  const HomePage({super.key, required this.onSelectTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PrayerTimesResult? _prayerResult;
  Map<String, dynamic>? _lastRead;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final lr = await QuranBookmarkStore.getLastRead();
    if (mounted) setState(() => _lastRead = lr);
    try {
      final pt = await AladhanPrayerTimesService.loadForCurrentLocation();
      if (mounted) setState(() => _prayerResult = pt);
      await AzanNotificationService.scheduleDailyPrayers(pt.times);
    } catch (_) {}
  }

  String _greeting(int h) => h < 11 ? 'Selamat pagi' : h < 15 ? 'Selamat siang' : h < 18 ? 'Selamat sore' : 'Selamat malam';

  (String name, String time, Duration remaining)? _nextPrayerCountdown() {
    if (_prayerResult == null) return null;
    final now = DateTime.now();
    for (final e in _prayerResult!.times.entries) {
      if (e.key == 'Imsak' || e.key == 'Terbit' || e.key == 'Duha') continue;
      final p = e.value.split(':');
      if (p.length != 2) continue;
      final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
      if (h == null || m == null) continue;
      final target = DateTime(now.year, now.month, now.day, h, m);
      if (target.isAfter(now)) {
        return (e.key, e.value, target.difference(now));
      }
    }
    final subuh = _prayerResult!.times['Subuh'];
    if (subuh != null) {
      final p = subuh.split(':');
      if (p.length == 2) {
        final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
        if (h != null && m != null) {
          final tomorrowSubuh = DateTime(now.year, now.month, now.day + 1, h, m);
          return ('Subuh', subuh, tomorrowSubuh.difference(now));
        }
      }
    }
    return null;
  }

  String _formatDuration(Duration d) {
    final totalMin = d.inMinutes;
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    if (h > 0) return '$h jam $m mnt lagi';
    return '$m menit lagi';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nextInfo = _nextPrayerCountdown();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5ECE8))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.calendar_today_rounded, size: 13, color: green),
              const SizedBox(width: 6),
              Text('${_weekday(now.weekday)}, ${now.day} ${_month(now.month)} ${now.year}',
                  style: const TextStyle(color: ink, fontWeight: FontWeight.w600, fontSize: 12)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(colors: [greenLight, green, greenDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: green.withOpacity(0.28), blurRadius: 22, offset: const Offset(0, 10))],
          ),
          child: Stack(children: [
            Positioned(right: -24, top: -24, child: Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)))),
            Positioned(right: 16, bottom: -18, child: Icon(Icons.mosque_rounded, size: 110, color: Colors.white.withOpacity(0.08))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(20)),
                  child: const Text('ASSALAMU’ALAIKUM', style: TextStyle(color: Colors.white, letterSpacing: 1.3, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 14),
                Text('${_greeting(now.hour)},\ndi Muslimku', style: const TextStyle(color: Colors.white, fontSize: 26, height: 1.2, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Teman ibadah harian Anda dengan jadwal salat, Al-Qur’an, dan doa.', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.45)),
                if (nextInfo != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Menuju ${nextInfo.$1} (${nextInfo.$2})',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            _formatDuration(nextInfo.$3),
                            style: const TextStyle(color: greenDark, fontWeight: FontWeight.w800, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ]),
            ),
          ]),
        ),
        if (_lastRead != null) ...[
          const SizedBox(height: 16),
          Container(
            decoration: cardDecoration(),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: greenSoft, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.bookmark_rounded, color: green, size: 22),
              ),
              title: const Text('Terakhir Dibaca', style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${_lastRead!['surahName']} • Ayat ${_lastRead!['ayahNumber']}',
                style: const TextStyle(fontSize: 15, color: ink, fontWeight: FontWeight.w800),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: green),
              onTap: () async {
                await _pushAsync(
                  context,
                  _lastRead!['surahName']?.toString() ?? 'Al-Qur’an',
                  SurahPage(
                    number: (_lastRead!['surahNumber'] as num).toInt(),
                    name: _lastRead!['surahName']?.toString() ?? '',
                    initialAyah: (_lastRead!['ayahNumber'] as num).toInt(),
                  ),
                );
                _loadDashboardData();
              },
            ),
          ),
        ],
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
            QuickTile('Jadwal salat', Icons.access_time_filled_rounded, const Color(0xFFE6F4EC), green, () => widget.onSelectTab(1)),
            QuickTile('Al-Qur’an', Icons.menu_book_rounded, const Color(0xFFE6F2F8), const Color(0xFF1A6B96), () => widget.onSelectTab(2)),
            QuickTile('Kitab Kuning', Icons.auto_stories_rounded, const Color(0xFFEFECE1), const Color(0xFF8A6A25), () => _push(context, 'Kitab Kuning Pesantren', const KitabListPage())),
            QuickTile('Murottal', Icons.headphones_rounded, const Color(0xFFF3ECFA), const Color(0xFF6B3FA0), () => widget.onSelectTab(2)),
            QuickTile('Arah kiblat', Icons.explore_rounded, const Color(0xFFFEF3E2), const Color(0xFFC2780A), () => _push(context, 'Arah Kiblat', const QiblaPage())),
            QuickTile('Tasbih', Icons.fingerprint_rounded, const Color(0xFFE8F5F3), const Color(0xFF0F766E), () => _push(context, 'Tasbih Digital', const TasbihPage())),
            QuickTile('Doa harian', Icons.volunteer_activism_rounded, const Color(0xFFFCEBF0), const Color(0xFFB83260), () => _push(context, 'Doa Harian', const DuaPage())),
            QuickTile('Sholawat', Icons.favorite_rounded, const Color(0xFFFCEBF0), const Color(0xFFB83260), () => _push(context, 'Sholawat', const SholawatPage()),),
          ],
        ),
        const SizedBox(height: 24),
        const SectionTitle('Pengingat'),
        const SizedBox(height: 12),
        const InfoCard(icon: Icons.notifications_active_rounded, title: 'Jaga waktu salat',
            text: 'Aktifkan izin notifikasi di perangkat untuk menerima pengingat ibadah. Jadwal salat dihitung otomatis dari lokasi perangkat.'),
      ],
    );
  }
}

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});
  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  PrayerTimesResult? result;
  String? error;
  bool loading = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await AladhanPrayerTimesService.loadForCurrentLocation();
      if (!mounted) return;
      setState(() {
        result = data;
        loading = false;
      });
      await AzanNotificationService.scheduleDailyPrayers(data.times);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  String? _nextPrayer(Map<String, String> times) {
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    for (final e in times.entries) {
      final p = e.value.split(':');
      if (p.length != 2) continue;
      final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
      if (h != null && m != null && h * 60 + m > nowMin) return e.key;
    }
    return 'Subuh';
  }

  String _countdownText(Map<String, String> times, String nextName) {
    final raw = times[nextName];
    if (raw == null) return '';
    final p = raw.split(':');
    if (p.length != 2) return '';
    final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
    if (h == null || m == null) return '';
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, h, m);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    final diff = target.difference(now);
    final hrs = diff.inHours;
    final mins = diff.inMinutes % 60;
    return hrs > 0 ? '$hrs jam $mins mnt lagi' : '$mins menit lagi';
  }

  IconData _icon(String name) => switch (name) {
        'Imsak' => Icons.nights_stay_rounded,
        'Subuh' => Icons.wb_twilight_rounded,
        'Terbit' => Icons.wb_sunny_outlined,
        'Duha' => Icons.wb_sunny_rounded,
        'Zuhur' => Icons.light_mode_rounded,
        'Asar' => Icons.sunny_snowing,
        'Magrib' => Icons.nights_stay_outlined,
        _ => Icons.bedtime_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final nextName = result != null ? _nextPrayer(result!.times) : null;
    final countdown = (result != null && nextName != null) ? _countdownText(result!.times, nextName) : '';

    return RefreshIndicator(
      color: green,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [greenLight, green, greenDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: green.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Lokasi perangkat', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                      Text(result?.regionName ?? 'Mendeteksi lokasi...', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      if (result != null) Text(result!.province, style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 12)),
                    ]),
                  ),
                  Material(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                    child: IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh_rounded, color: Colors.white)),
                  ),
                ]),
                if (nextName != null && countdown.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Berikutnya: $nextName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                        Text(countdown, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (loading) const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: green))),
          if (error != null) InfoCard(icon: Icons.info_outline_rounded, title: 'Jadwal belum tersedia', text: error!),
          if (result != null) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const SectionTitle('Jadwal salat hari ini'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: greenSoft, borderRadius: BorderRadius.circular(12)),
                child: Text(result!.fromCache ? 'Offline' : 'Kemenag RI', style: const TextStyle(color: greenDark, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 12),
            for (final entry in result!.times.entries)
              Builder(builder: (context) {
                final isNext = entry.key == nextName;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isNext ? greenSoft : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isNext ? green.withOpacity(0.45) : const Color(0xFFE7EFEA), width: isNext ? 1.5 : 1),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: isNext ? green : greenSoft, borderRadius: BorderRadius.circular(12)),
                      child: Icon(_icon(entry.key), color: isNext ? Colors.white : green, size: 20),
                    ),
                    title: Row(children: [
                      Text(entry.key, style: TextStyle(fontWeight: FontWeight.w800, color: isNext ? greenDark : ink)),
                      if (isNext) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(8)),
                          child: const Text('Berikutnya', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ]),
                    trailing: Text(entry.value, style: TextStyle(fontSize: 18, color: isNext ? green : greenDark, fontWeight: FontWeight.w800)),
                  ),
                );
              }),
            const SizedBox(height: 6),
            Text(result!.fromCache ? 'Jadwal menggunakan data tersimpan (offline).' : 'Sumber jadwal: Aladhan API (Metode Kemenag RI).',
                textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});
  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  List<dynamic> surahs = [];
  String query = '';
  bool loading = true;
  String? error;
  Map<String, dynamic>? lastRead;
  int bookmarkCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
    _fetch();
  }

  Future<void> _loadSavedState() async {
    final lr = await QuranBookmarkStore.getLastRead();
    final bm = await QuranBookmarkStore.getBookmarks();
    if (!mounted) return;
    setState(() {
      lastRead = lr;
      bookmarkCount = bm.length;
    });
  }

  Future<void> _fetch() async {
    try {
      final r = await http.get(Uri.parse('https://equran.id/api/v2/surat')).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) throw Exception('Gagal mengambil daftar surah.');
      final d = jsonDecode(r.body);
      if (!mounted) return;
      setState(() {
        surahs = d['data'] as List<dynamic>;
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _openSurah({
    required int number,
    required String name,
    int? initialAyah,
  }) async {
    _push(
      context,
      name,
      SurahPage(
        number: number,
        name: name,
        allSurahs: surahs,
        initialAyah: initialAyah,
        onSavedChanged: _loadSavedState,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = query.isEmpty
        ? surahs
        : surahs.where((item) {
            final s = item as Map<String, dynamic>;
            final q = query.toLowerCase();
            return (s['namaLatin'] ?? '').toString().toLowerCase().contains(q) ||
                (s['arti'] ?? '').toString().toLowerCase().contains(q) ||
                (s['nomor'] ?? '').toString() == q;
          }).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: cardDecoration(),
                child: TextField(
                  onChanged: (v) => setState(() => query = v.trim()),
                  decoration: const InputDecoration(
                    hintText: 'Cari surah (contoh: Yasin, Al-Kahfi)...',
                    hintStyle: TextStyle(color: muted, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: green),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _push(
                  context,
                  'Ayat Tersimpan',
                  BookmarksPage(
                    allSurahs: surahs,
                    onChanged: _loadSavedState,
                  ),
                ),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE7EFEA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bookmarks_rounded, color: green, size: 21),
                      if (bookmarkCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: greenSoft, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            '$bookmarkCount',
                            style: const TextStyle(color: greenDark, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      if (lastRead != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: Material(
            color: greenSoft,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openSurah(
                number: (lastRead!['surahNumber'] as num).toInt(),
                name: lastRead!['surahName']?.toString() ?? 'Surah',
                initialAyah: (lastRead!['ayahNumber'] as num).toInt(),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(11)),
                      child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Terakhir dibaca',
                            style: TextStyle(fontSize: 11, color: greenDark, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${lastRead!['surahName']} • Ayat ${lastRead!['ayahNumber']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, color: ink, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Lanjut',
                      style: TextStyle(fontSize: 12, color: green, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded, color: green, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      if (loading)
        const Expanded(child: Center(child: CircularProgressIndicator(color: green)))
      else if (error != null)
        Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('$error\nPeriksa koneksi internet lalu buka ulang halaman.', textAlign: TextAlign.center))))
      else
        Expanded(
          child: RefreshIndicator(
            color: green,
            onRefresh: () async {
              await _loadSavedState();
              await _fetch();
            },
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              itemCount: filtered.length,
              itemBuilder: (c, i) {
                final s = filtered[i] as Map<String, dynamic>;
                final surahName = s['namaLatin']?.toString() ?? '';
                final isLastReadSurah = lastRead != null && lastRead!['surahNumber'] == s['nomor'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: cardDecoration(),
                  child: ListTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isLastReadSurah ? green : greenSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${s['nomor']}',
                        style: TextStyle(
                          color: isLastReadSurah ? Colors.white : greenDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    title: Text(surahName, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
                    subtitle: Text('${s['arti'] ?? ''} • ${s['jumlahAyat'] ?? ''} ayat', style: const TextStyle(color: muted, fontSize: 12)),
                    trailing: Text(s['nama']?.toString() ?? '', style: const TextStyle(fontSize: 20, color: greenDark)),
                    onTap: () => _openSurah(
                      number: s['nomor'] as int,
                      name: surahName,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
    ]);
  }
}

class BookmarksPage extends StatefulWidget {
  final List<dynamic> allSurahs;
  final VoidCallback? onChanged;

  const BookmarksPage({
    super.key,
    this.allSurahs = const [],
    this.onChanged,
  });

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<Map<String, dynamic>> bookmarks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await QuranBookmarkStore.getBookmarks();
    if (!mounted) return;
    setState(() {
      bookmarks = list;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: green));
    }
    if (bookmarks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_border_rounded, size: 54, color: muted),
              SizedBox(height: 12),
              Text(
                'Belum ada ayat tersimpan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink),
              ),
              SizedBox(height: 6),
              Text(
                'Ketuk ikon bookmark pada ayat saat membaca Al-Qur’an untuk menyimpannya di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: muted, height: 1.45),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final item = bookmarks[index];
        final surahNum = (item['surahNumber'] as num).toInt();
        final ayahNum = (item['ayahNumber'] as num).toInt();
        final surahName = item['surahName']?.toString() ?? 'Surah $surahNum';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: greenSoft, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      '$surahName • Ayat $ayahNum',
                      style: const TextStyle(color: greenDark, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Hapus bookmark',
                    onPressed: () async {
                      await QuranBookmarkStore.removeBookmark(surahNum, ayahNum);
                      widget.onChanged?.call();
                      await _load();
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: muted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item['arabText']?.toString() ?? '',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 23, height: 1.9, color: ink),
              ),
              const SizedBox(height: 8),
              Text(
                item['translation']?.toString() ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted, fontSize: 12.5, height: 1.45),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _push(
                    context,
                    surahName,
                    SurahPage(
                      number: surahNum,
                      name: surahName,
                      allSurahs: widget.allSurahs,
                      initialAyah: ayahNum,
                      onSavedChanged: () {
                        widget.onChanged?.call();
                        _load();
                      },
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16, color: green),
                  label: const Text(
                    'Buka di surah',
                    style: TextStyle(color: green, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SurahPage extends StatefulWidget {
  final int number;
  final String name;
  final List<dynamic> allSurahs;
  final int? initialAyah;
  final VoidCallback? onSavedChanged;

  const SurahPage({
    super.key,
    required this.number,
    required this.name,
    this.allSurahs = const [],
    this.initialAyah,
    this.onSavedChanged,
  });

  @override
  State<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends State<SurahPage> {
  late int _currentNumber;
  late String _currentName;
  int? _highlightedAyah;
  Map<String, dynamic>? data;
  String? error;
  bool loading = true;
  final player = AudioPlayer();
  String? playingQari;

  Set<String> _bookmarkedIds = {};
  Map<String, dynamic>? _lastRead;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};

  @override
  void initState() {
    super.initState();
    _currentNumber = widget.number;
    _currentName = widget.name;
    _highlightedAyah = widget.initialAyah;
    _loadBookmarksAndLastRead();
    _get();
    player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => playingQari = null);
    });
  }

  Future<void> _loadBookmarksAndLastRead() async {
    final bm = await QuranBookmarkStore.getBookmarks();
    final lr = await QuranBookmarkStore.getLastRead();
    if (!mounted) return;
    setState(() {
      _bookmarkedIds = bm.map((e) => '${e['surahNumber']}:${e['ayahNumber']}').toSet();
      _lastRead = lr;
    });
  }

  Future<void> _get() async {
    try {
      await player.stop();
      if (!mounted) return;
      setState(() {
        loading = true;
        error = null;
        playingQari = null;
        _ayahKeys.clear();
      });
      final r = await http
          .get(Uri.parse('https://equran.id/api/v2/surat/$_currentNumber'))
          .timeout(const Duration(seconds: 20));
      final j = jsonDecode(r.body);
      if (r.statusCode != 200 || j['data'] == null) {
        throw Exception('Konten surah tidak tersedia.');
      }
      if (!mounted) return;
      final fetchedName = j['data']['namaLatin']?.toString() ?? _currentName;
      setState(() {
        data = j['data'];
        _currentName = fetchedName;
        loading = false;
      });
      _syncShellTitle(fetchedName);

      if (_highlightedAyah != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToAyah(_highlightedAyah!);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  void _scrollToAyah(int ayahNumber) {
    final key = _ayahKeys[ayahNumber];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.12,
      );
    }
  }

  void _syncShellTitle(String title) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final shell = context.findAncestorStateOfType<_MainShellState>();
      shell?.updateTopSubPageTitle(title);
    });
  }

  void _goToSurah(int targetNumber) {
    if (targetNumber < 1 || targetNumber > 114 || loading) return;
    HapticFeedback.selectionClick();
    final targetName = _surahName(targetNumber) ?? 'Surah $targetNumber';
    setState(() {
      _currentNumber = targetNumber;
      _currentName = targetName;
      _highlightedAyah = null;
    });
    _syncShellTitle(targetName);
    _get();
  }

  String? _surahName(int number) {
    for (final item in widget.allSurahs) {
      if (item is Map && item['nomor'] == number) {
        return item['namaLatin']?.toString();
      }
    }
    return null;
  }

  String _qariLabel(String key, int index) {
    final clean = key.trim();
    if (clean.isEmpty) return 'Qari ${'0${index + 1}'}';
    if (RegExp(r'^\d+$').hasMatch(clean)) {
      return 'Qari ${clean.padLeft(2, '0')}';
    }
    return clean;
  }

  Future<void> _markLastRead(int ayahNumber) async {
    HapticFeedback.selectionClick();
    await QuranBookmarkStore.setLastRead(
      surahNumber: _currentNumber,
      surahName: _currentName,
      ayahNumber: ayahNumber,
    );
    await _loadBookmarksAndLastRead();
    widget.onSavedChanged?.call();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ditandai terakhir dibaca: $_currentName ayat $ayahNumber'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleAyahBookmark(Map<String, dynamic> ayah) async {
    HapticFeedback.selectionClick();
    final ayahNum = (ayah['nomorAyat'] as num).toInt();
    final added = await QuranBookmarkStore.toggleBookmark(
      surahNumber: _currentNumber,
      surahName: _currentName,
      ayahNumber: ayahNum,
      arabText: ayah['teksArab']?.toString() ?? '',
      translation: ayah['teksIndonesia']?.toString() ?? '',
    );
    await _loadBookmarksAndLastRead();
    widget.onSavedChanged?.call();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? 'Ayat $ayahNum ditambahkan ke bookmark'
              : 'Ayat $ayahNum dihapus dari bookmark',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: green));
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(error!, textAlign: TextAlign.center),
        ),
      );
    }

    final audioEntries = data!['audioFull'] != null
        ? (data!['audioFull'] as Map<String, dynamic>).entries.take(4).toList()
        : <MapEntry<String, dynamic>>[];

    final prevName = _surahName(_currentNumber - 1);
    final nextName = _surahName(_currentNumber + 1);

    return ListView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        if (audioEntries.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.headphones_rounded, color: green, size: 19),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Audio Murottal',
                        style: TextStyle(fontWeight: FontWeight.w800, color: ink),
                      ),
                    ),
                    if (playingQari != null)
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          await player.stop();
                          if (mounted) setState(() => playingQari = null);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stop_rounded, size: 16, color: Colors.redAccent),
                              SizedBox(width: 3),
                              Text(
                                'Stop',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 8.0;
                    final cols = constraints.maxWidth < 360 ? 2 : 4;
                    final itemWidth =
                        (constraints.maxWidth - gap * (cols - 1)) / cols;

                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: List.generate(audioEntries.length, (idx) {
                        final entry = audioEntries[idx];
                        final isPlaying = playingQari == entry.key;
                        final label = _qariLabel(entry.key, idx);

                        return SizedBox(
                          width: itemWidth,
                          child: Material(
                            color: isPlaying ? green : greenSoft,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                try {
                                  await player.stop();
                                  if (isPlaying) {
                                    setState(() => playingQari = null);
                                  } else {
                                    setState(() => playingQari = entry.key);
                                    await player.play(UrlSource(entry.value.toString()));
                                  }
                                } catch (_) {
                                  if (mounted) {
                                    setState(() => playingQari = null);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Audio gagal diputar. Periksa koneksi.'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 9,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isPlaying
                                          ? Icons.graphic_eq_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 16,
                                      color: isPlaying ? Colors.white : greenDark,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isPlaying ? Colors.white : greenDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        for (final item in data!['ayat'] as List<dynamic>)
          Builder(
            builder: (context) {
              final a = item as Map<String, dynamic>;
              final ayahNum = (a['nomorAyat'] as num).toInt();
              final ayahKey = _ayahKeys.putIfAbsent(ayahNum, () => GlobalKey());
              final isBookmarked = _bookmarkedIds.contains('$_currentNumber:$ayahNum');
              final isLastRead = _lastRead != null &&
                  _lastRead!['surahNumber'] == _currentNumber &&
                  _lastRead!['ayahNumber'] == ayahNum;
              final isHighlighted = _highlightedAyah == ayahNum;

              return Container(
                key: ayahKey,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isHighlighted ? const Color(0xFFF3FBF7) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isLastRead || isHighlighted)
                        ? green.withOpacity(0.55)
                        : const Color(0xFFE7EFEA),
                    width: (isLastRead || isHighlighted) ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.035),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLastRead ? green : greenSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Ayat $ayahNum',
                            style: TextStyle(
                              color: isLastRead ? Colors.white : greenDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (isLastRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: greenSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Terakhir dibaca',
                              style: TextStyle(
                                color: greenDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _markLastRead(ayahNum),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLastRead
                                      ? Icons.check_circle_rounded
                                      : Icons.auto_stories_outlined,
                                  size: 16,
                                  color: green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isLastRead ? 'Ditandai' : 'Tandai baca',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: greenDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                          tooltip: isBookmarked ? 'Hapus bookmark' : 'Simpan bookmark',
                          onPressed: () => _toggleAyahBookmark(a),
                          icon: Icon(
                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: isBookmarked ? green : muted,
                            size: 21,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      a['teksArab']?.toString() ?? '',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontSize: 28, height: 2.0, color: ink),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      a['teksLatin']?.toString() ?? '',
                      style: const TextStyle(
                        color: greenDark,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a['teksIndonesia']?.toString() ?? '',
                      style: const TextStyle(color: muted, height: 1.55),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _SurahNavButton(
                title: 'Sebelumnya',
                subtitle: _currentNumber > 1
                    ? (prevName ?? 'Surah ${_currentNumber - 1}')
                    : 'Awal Qur’an',
                icon: Icons.chevron_left_rounded,
                enabled: _currentNumber > 1,
                isNext: false,
                onTap: () => _goToSurah(_currentNumber - 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SurahNavButton(
                title: 'Selanjutnya',
                subtitle: _currentNumber < 114
                    ? (nextName ?? 'Surah ${_currentNumber + 1}')
                    : 'Akhir Qur’an',
                icon: Icons.chevron_right_rounded,
                enabled: _currentNumber < 114,
                isNext: true,
                onTap: () => _goToSurah(_currentNumber + 1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SurahNavButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final bool isNext;
  final VoidCallback onTap;

  const _SurahNavButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.isNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? Colors.white : const Color(0xFFF0F4F2),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: enabled ? const Color(0xFFE7EFEA) : const Color(0xFFEAEFEA),
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (!isNext) ...[
                Icon(
                  icon,
                  size: 20,
                  color: enabled ? green : muted.withOpacity(0.45),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      isNext ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: enabled ? green : muted.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: enabled ? ink : muted.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (isNext) ...[
                const SizedBox(width: 6),
                Icon(
                  icon,
                  size: 20,
                  color: enabled ? green : muted.withOpacity(0.45),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});
  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  double? bearing;
  String? error;

  @override
  void initState() {
    super.initState();
    _calc();
  }

  Future<void> _calc() async {
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi dibutuhkan untuk menentukan arah kiblat.');
      }
      final pos = await Geolocator.getCurrentPosition();
      const latK = 21.4225, lonK = 39.8262;
      final lat1 = pos.latitude * math.pi / 180, lat2 = latK * math.pi / 180, dLon = (lonK - pos.longitude) * math.pi / 180;
      final y = math.sin(dLon), x = math.cos(lat1) * math.tan(lat2) - math.sin(lat1) * math.cos(dLon);
      if (mounted) setState(() => bearing = (math.atan2(y, x) * 180 / math.pi + 360) % 360);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.explore_rounded, color: green, size: 46),
            const SizedBox(height: 12),
            const Text('Arah Ka’bah', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 8),
            if (error != null) Text(error!, textAlign: TextAlign.center),
            if (bearing != null) ...[
              Text('${bearing!.toStringAsFixed(1)}° dari utara sejati', style: const TextStyle(fontSize: 16, color: greenDark, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              StreamBuilder<CompassEvent>(
                stream: FlutterCompass.events,
                builder: (c, s) => Transform.rotate(
                  angle: (bearing! - (s.data?.heading ?? 0)) * math.pi / 180,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: green, width: 3)),
                    child: const Icon(Icons.navigation_rounded, size: 120, color: green),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Putar perangkat sampai penunjuk mengarah ke atas.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
            ],
            const SizedBox(height: 18),
            FilledButton.tonalIcon(onPressed: _calc, icon: const Icon(Icons.refresh_rounded), label: const Text('Perbarui lokasi')),
          ]),
        ),
      );
}

class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key});
  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> {
  int count = 0, target = 33;
  String phrase = 'Subhanallah';
  bool pressed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        count = p.getInt('tasbih_count') ?? 0;
        target = p.getInt('tasbih_target') ?? 33;
        phrase = p.getString('tasbih_phrase') ?? 'Subhanallah';
      });
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('tasbih_count', count);
    await p.setInt('tasbih_target', target);
    await p.setString('tasbih_phrase', phrase);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (count % target) / target;
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            decoration: cardDecoration(),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: phrase,
                items: const ['Subhanallah', 'Alhamdulillah', 'Allahu Akbar', 'Astaghfirullah', 'La ilaha illallah']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontWeight: FontWeight.w700))))
                    .toList(),
                onChanged: (v) { if (v != null) setState(() => phrase = v); _save(); },
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text('$count', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w800, color: greenDark)),
          Text('Target $target', style: const TextStyle(color: muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 26),
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 215,
              height: 215,
              child: CircularProgressIndicator(
                value: count > 0 && count % target == 0 ? 1.0 : progress,
                strokeWidth: 8,
                backgroundColor: greenSoft,
                color: greenLight,
                strokeCap: StrokeCap.round,
              ),
            ),
            GestureDetector(
              onTapDown: (_) => setState(() => pressed = true),
              onTapUp: (_) => setState(() => pressed = false),
              onTapCancel: () => setState(() => pressed = false),
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => count++);
                _save();
                if (count == target) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alhamdulillah, target zikir tercapai!')));
                }
              },
              child: AnimatedScale(
                scale: pressed ? 0.93 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  width: 185,
                  height: 185,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [greenLight, greenDark]),
                    boxShadow: [BoxShadow(color: green.withOpacity(0.32), blurRadius: 22, offset: const Offset(0, 10))],
                  ),
                  child: const Center(child: Text('ZIKIR', style: TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 2, fontWeight: FontWeight.w800))),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 26),
          Wrap(spacing: 12, children: [
            OutlinedButton.icon(onPressed: () { setState(() => count = 0); _save(); }, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Reset')),
            FilledButton.tonalIcon(
              onPressed: () async {
                final v = await showDialog<int>(
                  context: context,
                  builder: (c) {
                    int n = target;
                    return AlertDialog(
                      title: const Text('Atur target'),
                      content: StatefulBuilder(
                        builder: (c, setD) => DropdownButton<int>(
                          value: n,
                          items: [33, 99, 100, 1000].map((x) => DropdownMenuItem(value: x, child: Text('$x'))).toList(),
                          onChanged: (x) { if (x != null) setD(() => n = x); },
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
                        TextButton(onPressed: () => Navigator.pop(c, n), child: const Text('Simpan')),
                      ],
                    );
                  },
                );
                if (v != null) { setState(() => target = v); _save(); }
              },
              icon: const Icon(Icons.flag_rounded, size: 18),
              label: const Text('Target'),
            ),
          ]),
        ]),
      ),
    );
  }
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          const InfoCard(icon: Icons.auto_stories_rounded, title: 'Perpustakaan Muslimku', text: 'Kumpulan kitab kuning pesantren, doa harian, dan hadis ringkas.'),
          const SizedBox(height: 14),
          _navTile(context, 'Kitab Kuning Pesantren', Icons.menu_book_rounded, 'Kitab Kuning Pesantren', const KitabListPage()),
          _navTile(context, 'Doa harian', Icons.volunteer_activism_rounded, 'Doa Harian', const DuaPage()),
          _navTile(context, 'Hadis pilihan', Icons.format_quote_rounded, 'Hadis Pilihan', const HadithPage()),
        ],
      );
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _navTile(context, 'Kitab Kuning Reader', Icons.menu_book_rounded, 'Kitab Kuning Pesantren', const KitabListPage()),
          _navTile(context, 'Arah kiblat', Icons.explore_rounded, 'Arah Kiblat', const QiblaPage()),
          _navTile(context, 'Tasbih digital', Icons.fingerprint_rounded, 'Tasbih Digital', const TasbihPage()),
          _navTile(context, 'Ayat tersimpan', Icons.bookmarks_rounded, 'Ayat Tersimpan', const BookmarksPage()),
          _navTile(context, 'Doa harian', Icons.volunteer_activism_rounded, 'Doa Harian', const DuaPage()),
          _navTile(context, 'Hadis pilihan', Icons.auto_stories_rounded, 'Hadis Pilihan', const HadithPage()),
          _navTile(context, 'Kalkulator zakat', Icons.calculate_rounded, 'Kalkulator Zakat Mal', const ZakatPage()),
          _navTile(context, 'Pengingat salat', Icons.notifications_active_rounded, 'Pengingat Salat', const ReminderPage()),
          _navTile(context, 'Sholawat', Icons.favorite_rounded, 'Sholawat', const SholawatPage(),),
          _navTile(context, 'Pengaturan', Icons.settings_rounded, 'Pengaturan', const SettingsPage()),
          const SizedBox(height: 14),
          const InfoCard(icon: Icons.info_outline_rounded, title: 'Tentang Muslimku', text: 'Versi 1.4.0 • Aplikasi pendamping ibadah.'),
          
        ],
      );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<KitabBab> _books = const [];
  bool _loading = true;
  bool _hasImportedKitab = false;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final books = await KitabDataService.load();
      final hasImported = await KitabDataService.hasImportedKitab();
      if (mounted) setState(() {
        _books = books;
        _hasImportedKitab = hasImported;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteImportedKitab() async {
    final first = TextEditingController();
    final second = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Hapus kitab impor?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Data kitab impor akan dihapus dari aplikasi dan kitab bawaan akan digunakan kembali.'),
                const SizedBox(height: 14),
                TextField(
                  controller: first,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(labelText: 'Ketik: hapus'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: second,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(labelText: 'Ketik: yakin'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: first.text.trim().toLowerCase() == 'hapus' && second.text.trim().toLowerCase() == 'yakin'
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: const Text('Hapus sekarang'),
            ),
          ],
        ),
      ),
    );
    first.dispose();
    second.dispose();
    if (confirmed != true || !mounted) return;
    await KitabDataService.deleteImportedKitab();
    setState(() => _loading = true);
    await _loadBooks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kitab impor dihapus. Data bawaan dipulihkan.')));
  }

  Future<void> _importBooks() async {
    try {
      final count = await KitabDataService.importFromPicker();
      if (count == 0 || !mounted) return;
      final books = await KitabDataService.load();
      setState(() => _books = books);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count bab kitab berhasil diimpor.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import gagal: $e')),
      );
    }
  }

  Future<void> _exportBackup() async {
    try {
      final path = await KitabDataService.exportBackup(books: _books);
      if (!mounted || path == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup tersimpan: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup gagal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          const InfoCard(
            icon: Icons.settings_rounded,
            title: 'Pengaturan Muslimku',
            text: 'Kelola cadangan data dan kitab yang Anda impor. Data bawaan aplikasi tetap aman.',
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined, color: green),
                  title: const Text('Import kitab / backup', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
                  subtitle: const Text('Pilih file JSON dari perangkat'),
                  onTap: _importBooks,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.save_alt_rounded, color: green),
                  title: const Text('Export backup Muslimku', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
                  subtitle: Text(_loading ? 'Menyiapkan data...' : '${_books.length} bab kitab akan dicadangkan'),
                  onTap: _loading ? null : _exportBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              enabled: _hasImportedKitab && !_loading,
              leading: Icon(Icons.delete_forever_rounded, color: _hasImportedKitab ? Colors.red.shade700 : muted),
              title: Text('Hapus kitab impor', style: TextStyle(fontWeight: FontWeight.w800, color: _hasImportedKitab ? Colors.red.shade700 : muted)),
              subtitle: Text(_hasImportedKitab
                  ? 'Wajib mengetik “hapus” lalu “yakin”. Kitab bawaan akan dipulihkan.'
                  : 'Tidak ada kitab impor yang tersimpan.'),
              onTap: _hasImportedKitab && !_loading ? _deleteImportedKitab : null,
            ),
          ),
        ],
      );
}

class DuaPage extends StatelessWidget {
  const DuaPage({super.key});
  static const duas = [
    ('Doa sebelum makan', 'بِسْمِ اللَّهِ', 'Bismillah.', 'Dengan nama Allah.'),
    ('Doa sesudah makan', 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا', 'Alhamdulillahil ladzi ath’amana wa saqana.', 'Segala puji bagi Allah yang telah memberi kami makan dan minum.'),
    ('Doa masuk rumah', 'بِسْمِ اللَّهِ وَلَجْنَا وَبِسْمِ اللَّهِ خَرَجْنَا', 'Bismillahi walajna wa bismillahi kharajna.', 'Dengan nama Allah kami masuk dan dengan nama Allah kami keluar.'),
  ];
  @override
  Widget build(BuildContext context) => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          for (final d in duas)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: cardDecoration(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(d.$1, style: const TextStyle(fontWeight: FontWeight.w800, color: greenDark)),
                const SizedBox(height: 12),
                Text(d.$2, textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 25, height: 1.8)),
                const SizedBox(height: 8),
                Text(d.$3, style: const TextStyle(fontStyle: FontStyle.italic, color: green)),
                const SizedBox(height: 5),
                Text(d.$4, style: const TextStyle(color: muted)),
              ]),
            ),
        ],
      );
}

class HadithPage extends StatelessWidget {
  const HadithPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: const [
          InfoCard(
            icon: Icons.menu_book_rounded,
            title: 'Niat',
            text: '“Sesungguhnya amal itu tergantung niatnya.”\nHR. Bukhari dan Muslim.',
          ),
          InfoCard(
            icon: Icons.menu_book_rounded,
            title: 'Berkata baik',
            text: '“Barang siapa beriman kepada Allah dan hari akhir, hendaklah berkata baik atau diam.”\nHR. Bukhari dan Muslim.',
          ),
          InfoCard(
            icon: Icons.menu_book_rounded,
            title: 'Memudahkan',
            text: '“Mudahkanlah dan jangan mempersulit, berilah kabar gembira dan jangan membuat orang lari.”\nHR. Bukhari dan Muslim.',
          ),
        ],
      );
}

class ZakatPage extends StatefulWidget {
  const ZakatPage({super.key});
  @override
  State<ZakatPage> createState() => _ZakatPageState();
}

class _ZakatPageState extends State<ZakatPage> {
  final c = TextEditingController();
  double result = 0;
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: c,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Nilai harta (Rupiah)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)), prefixText: 'Rp '),
            onChanged: (_) => setState(() => result = (double.tryParse(c.text.replaceAll('.', '').replaceAll(',', '')) ?? 0) * .025),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: greenSoft, borderRadius: BorderRadius.circular(18)),
            child: Text('Estimasi zakat 2,5%: Rp ${result.toStringAsFixed(0)}', style: const TextStyle(color: greenDark, fontSize: 19, fontWeight: FontWeight.w800)),
          ),
        ],
      );
}

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});
  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  bool enabled = true;
  final Map<String, bool> prayerEnabled = {
    for (final name in AzanNotificationService.prayerKeys) name: true,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      enabled = prefs.getBool('azan_enabled') ?? true;
      for (final name in AzanNotificationService.prayerKeys) {
        prayerEnabled[name] = prefs.getBool('azan_$name') ?? true;
      }
    });
  }

  Future<void> _setEnabled(bool value) async {
    setState(() => enabled = value);
    await AzanNotificationService.setEnabled(value);
    if (value && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Buka halaman Salat untuk menjadwalkan ulang azan.'),
      ));
    }
  }

  Future<void> _setPrayerEnabled(String name, bool value) async {
    setState(() => prayerEnabled[name] = value);
    await AzanNotificationService.setPrayerEnabled(name, value);
  }

  Future<void> _testAzan({bool isSubuh = false}) async {
    try {
      await AzanNotificationService.testAzan(isSubuh: isSubuh);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Suara azan sedang diputar. Periksa volume media perangkat.'),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Uji suara gagal: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const InfoCard(
            icon: Icons.notifications_active_rounded,
            title: 'Pengaturan notifikasi azan',
            text: 'Notifikasi dan suara azan dijadwalkan setiap hari dari waktu salat terakhir yang dimuat.',
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Column(children: [
              SwitchListTile(
                value: enabled,
                onChanged: _setEnabled,
                activeColor: green,
                title: const Text('Aktifkan azan', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
                subtitle: const Text('Berbunyi saat masuk waktu salat.'),
              ),
              const Divider(height: 1),
              for (final name in AzanNotificationService.prayerKeys)
                SwitchListTile(
                  value: enabled && (prayerEnabled[name] ?? true),
                  onChanged: enabled ? (value) => _setPrayerEnabled(name, value) : null,
                  activeColor: green,
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: ink)),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _testAzan,
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('Uji suara azan'),
            style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _testAzan(isSubuh: true),
            icon: const Icon(Icons.wb_twilight_rounded),
            label: const Text('Uji suara azan Subuh'),
            style: OutlinedButton.styleFrom(foregroundColor: green, side: const BorderSide(color: green)),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: AzanNotificationService.stopTestAzan,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Hentikan uji suara'),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
          ),
        ],
      );
}

// ============================================================================
// FITUR KITAB KUNING PESANTREN (ARAB + LATIN INDONESIA + TERJEMAHAN)
// ============================================================================
class KitabListPage extends StatefulWidget {
  const KitabListPage({super.key});

  @override
  State<KitabListPage> createState() => _KitabListPageState();
}

class _KitabListPageState extends State<KitabListPage> {
  String _selectedCategory = 'Semua';
  String _query = '';
  final _searchController = TextEditingController();
  List<KitabBab> _books = const [];
  bool _loading = true;
  String? _error;

  List<KitabBab> _sortBooks(Iterable<KitabBab> source) {
    final indexed = source.toList().asMap().entries.toList();
    int chapterNumber(String title) {
      final match = RegExp(r'\b(?:bab|fasal)?\s*(\d+)', caseSensitive: false).firstMatch(title);
      return int.tryParse(match?.group(1) ?? '') ?? 1 << 30;
    }
    int sectionOrder(KitabBab book) => book.urutan ?? chapterNumber(book.judulBab);

    indexed.sort((a, b) {
      final bookCompare = a.value.namaKitab.toLowerCase().compareTo(b.value.namaKitab.toLowerCase());
      if (bookCompare != 0) return bookCompare;
      final chapterCompare = sectionOrder(a.value).compareTo(sectionOrder(b.value));
      if (chapterCompare != 0) return chapterCompare;
      final titleCompare = a.value.judulBab.toLowerCase().compareTo(b.value.judulBab.toLowerCase());
      return titleCompare != 0 ? titleCompare : a.key.compareTo(b.key);
    });
    return indexed.map((entry) => entry.value).toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final books = await KitabDataService.load();
      if (!mounted) return;
      setState(() {
        _books = books;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: green));
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Data kitab gagal dimuat:\n$_error', textAlign: TextAlign.center),
      ));
    }
    final categories = ['Semua', ..._books.map((k) => k.kategori).toSet()];
    final categoryFiltered = _selectedCategory == 'Semua'
        ? _books
        : _books.where((k) => k.kategori == _selectedCategory).toList();
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? categoryFiltered
        : categoryFiltered.where((book) {
            final haystack = [
              book.namaKitab,
              book.judulBab,
              book.kategori,
              ...book.isi.expand((item) => [
                    item.nomor,
                    item.jenis,
                    item.urutan?.toString() ?? '',
                    item.judulBab,
                    item.arab,
                    item.latin,
                    item.terjemah,
                    item.ringkasan,
                    ...item.poinPenting,
                    item.catatan,
                  ]),
            ].join(' ').toLowerCase();
            return haystack.contains(query);
          }).toList();
    final orderedBooks = _sortBooks(filtered);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Cari kitab, bab, Arab, latin, atau terjemahan',
              prefixIcon: const Icon(Icons.search_rounded, color: green),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.clear_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${orderedBooks.length} dari ${_books.length} bab tersedia', style: const TextStyle(color: muted, fontSize: 12)),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final active = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: active,
                selectedColor: green,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: active ? Colors.white : ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                onSelected: (_) => setState(() => _selectedCategory = cat),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
            itemCount: orderedBooks.length,
            itemBuilder: (context, index) {
              final bab = orderedBooks[index];
              final sectionPrefix = bab.urutan == null
                  ? ''
                  : '${bab.jenis == 'fasal' ? 'Fasal' : 'Bab'} ${bab.urutan} • ';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: cardDecoration(),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: greenSoft, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.menu_book_rounded, color: green, size: 21),
                  ),
                  title: Text(
                    bab.namaKitab,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: ink, fontSize: 15),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '$sectionPrefix${bab.judulBab} • ${bab.isi.length} poin',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: muted),
                  onTap: () => _push(context, bab.namaKitab, KitabReaderPage(bab: bab, allBooks: _books)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

enum ReaderMode { arLtId, arId, arOnly }

class KitabReaderPage extends StatefulWidget {
  final KitabBab bab;
  final List<KitabBab> allBooks;
  const KitabReaderPage({super.key, required this.bab, required this.allBooks});

  @override
  State<KitabReaderPage> createState() => _KitabReaderPageState();
}

class _KitabReaderPageState extends State<KitabReaderPage> {
  double _arabicFontSize = 23.0;
  ReaderMode _mode = ReaderMode.arLtId;
  late KitabBab _currentBab;

  @override
  void initState() {
    super.initState();
    _currentBab = widget.bab;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(18, 8, 18, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: greenSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: green.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_stories_rounded, color: green, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_currentBab.namaKitab} — ${_currentBab.judulBab}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: greenDark, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
            itemCount: _currentBab.isi.length,
            itemBuilder: (context, index) {
              final item = _currentBab.isi[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: cardDecoration(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.nomor != 'Fasal')
                      Padding(
                        padding: const EdgeInsets.only(right: 10, top: 4),
                        child: Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: greenSoft, borderRadius: BorderRadius.circular(9)),
                          child: Text(
                            item.nomor,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: greenDark),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (item.judulBab.isNotEmpty)
                            Text(
                              item.judulBab,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: greenDark),
                            ),
                          if (item.arab.isNotEmpty) ...[
                            Text(
                              item.arab,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(fontSize: _arabicFontSize, height: 1.85, fontWeight: FontWeight.w600, color: ink),
                            ),
                          ],
                          if (item.ringkasan.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Ringkasan', style: TextStyle(fontWeight: FontWeight.w800, color: greenDark)),
                            const SizedBox(height: 4),
                            Text(item.ringkasan, style: const TextStyle(fontSize: 14, height: 1.5, color: ink)),
                          ],
                          if (item.poinPenting.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Text('Poin penting', style: TextStyle(fontWeight: FontWeight.w800, color: greenDark)),
                            const SizedBox(height: 3),
                            for (final point in item.poinPenting)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text('• $point', style: const TextStyle(fontSize: 13.5, height: 1.45, color: muted)),
                              ),
                          ],
                          if (_mode == ReaderMode.arLtId) ...[
                            if (item.latin.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              item.latin,
                              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13.5, color: greenDark, height: 1.45),
                            ),
                            ],
                          ],
                          if (_mode == ReaderMode.arLtId || _mode == ReaderMode.arId) ...[
                            if (item.terjemah.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              item.terjemah,
                              style: const TextStyle(fontSize: 13.5, height: 1.5, color: muted),
                            ),
                            ],
                          ],
                          if (item.catatan.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text('Catatan: ${item.catatan}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: muted)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE7EFEA))),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<KitabBab>(
                        isExpanded: true,
                        value: _currentBab,
                        items: widget.allBooks.map((bab) {
                          return DropdownMenuItem<KitabBab>(
                            value: bab,
                            child: Text(
                              '${bab.namaKitab} | ${bab.judulBab}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: ink),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _currentBab = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      if (_arabicFontSize > 16) _arabicFontSize -= 2;
                    }),
                    child: const Text('A-'),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      if (_arabicFontSize < 34) _arabicFontSize += 2;
                    }),
                    child: const Text('A+'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _modeChip('AR + LT + ID', ReaderMode.arLtId),
                  const SizedBox(width: 8),
                  _modeChip('AR + ID', ReaderMode.arId),
                  const SizedBox(width: 8),
                  _modeChip('AR Only', ReaderMode.arOnly),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeChip(String label, ReaderMode mode) {
    final selected = _mode == mode;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label, style: const TextStyle(fontSize: 11.5))),
        selected: selected,
        selectedColor: green,
        backgroundColor: greenSoft,
        labelStyle: TextStyle(
          color: selected ? Colors.white : greenDark,
          fontWeight: FontWeight.w700,
        ),
        onSelected: (_) => setState(() => _mode = mode),
      ),
    );
  }
}

class QuickTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color bgColor, iconColor;
  final VoidCallback onTap;
  const QuickTile(this.title, this.icon, this.bgColor, this.iconColor, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration: cardDecoration(),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () { HapticFeedback.selectionClick(); onTap(); },
            borderRadius: BorderRadius.circular(20),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: iconColor, size: 25)),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 12)),
            ]),
          ),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink));
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title, text;
  const InfoCard({super.key, required this.icon, required this.title, required this.text});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: greenSoft, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: green, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: ink, fontSize: 14)),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(color: muted, height: 1.5, fontSize: 12)),
          ])),
        ]),
      );
}

Widget _navTile(BuildContext context, String title, IconData icon, String pageTitle, Widget page) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: cardDecoration(),
      child: ListTile(
        leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: greenSoft, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: green, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: ink)),
        trailing: const Icon(Icons.chevron_right_rounded, color: muted),
        onTap: () => _push(context, pageTitle, page),
      ),
    );

void _push(BuildContext context, String title, Widget page) {
  final shell = context.findAncestorStateOfType<_MainShellState>();
  if (shell != null) {
    shell.openSubPage(title, page);
  } else {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Scaffold(appBar: AppBar(title: Text(title)), body: page),
        transitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
  }
}

Future<void> _pushAsync(BuildContext context, String title, Widget page) async {
  final shell = context.findAncestorStateOfType<_MainShellState>();
  if (shell != null) {
    shell.openSubPage(title, page);
  } else {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Scaffold(appBar: AppBar(title: Text(title)), body: page),
        transitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
  }
}

BoxDecoration cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE7EFEA)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 14, offset: const Offset(0, 5))],
    );

String _weekday(int n) => const ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'][n - 1];
String _month(int n) => const ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'][n - 1];
