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
  final pages = const [HomePage(), PrayerPage(), QuranPage(), LibraryPage(), MorePage()];
  final titles = const ['Muslimku', 'Waktu Salat', 'Al-Qur’an', 'Perpustakaan', 'Lainnya'];
  final navItems = const [
    (Icons.home_outlined, Icons.home_rounded, 'Beranda'),
    (Icons.access_time_outlined, Icons.access_time_filled_rounded, 'Salat'),
    (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Qur’an'),
    (Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Kitab'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Lainnya'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 68,
          title: Row(children: [
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(titles[index], key: ValueKey(titles[index]),
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: ink)),
            ),
          ]),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
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
                  final sel = i == index;
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
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  String _greeting(int h) => h < 11 ? 'Selamat pagi' : h < 15 ? 'Selamat siang' : h < 18 ? 'Selamat sore' : 'Selamat malam';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
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
              ]),
            ),
          ]),
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
            QuickTile('Jadwal salat', Icons.access_time_filled_rounded, const Color(0xFFE6F4EC), green,
                () => _push(context, Scaffold(appBar: AppBar(title: const Text('Waktu Salat')), body: const PrayerPage()))),
            QuickTile('Al-Qur’an', Icons.menu_book_rounded, const Color(0xFFE6F2F8), const Color(0xFF1A6B96),
                () => _push(context, Scaffold(appBar: AppBar(title: const Text('Al-Qur’an')), body: const QuranPage()))),
            QuickTile('Murottal', Icons.headphones_rounded, const Color(0xFFF3ECFA), const Color(0xFF6B3FA0),
                () => _push(context, Scaffold(appBar: AppBar(title: const Text('Murottal')), body: const QuranPage()))),
            QuickTile('Arah kiblat', Icons.explore_rounded, const Color(0xFFFEF3E2), const Color(0xFFC2780A), () => _push(context, const QiblaPage())),
            QuickTile('Tasbih', Icons.fingerprint_rounded, const Color(0xFFE8F5F3), const Color(0xFF0F766E), () => _push(context, const TasbihPage())),
            QuickTile('Doa harian', Icons.volunteer_activism_rounded, const Color(0xFFFCEBF0), const Color(0xFFB83260), () => _push(context, const DuaPage())),
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

  @override
  void initState() {
    super.initState();
    _load();
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
            child: Row(children: [
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

  @override
  void initState() {
    super.initState();
    _fetch();
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
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
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
      if (loading)
        const Expanded(child: Center(child: CircularProgressIndicator(color: green)))
      else if (error != null)
        Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('$error\nPeriksa koneksi internet lalu buka ulang halaman.', textAlign: TextAlign.center))))
      else
        Expanded(
          child: RefreshIndicator(
            color: green,
            onRefresh: _fetch,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              itemCount: filtered.length,
              itemBuilder: (c, i) {
                final s = filtered[i] as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: cardDecoration(),
                  child: ListTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: greenSoft, borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: Text('${s['nomor']}', style: const TextStyle(color: greenDark, fontWeight: FontWeight.w800)),
                    ),
                    title: Text(s['namaLatin']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
                    subtitle: Text('${s['arti'] ?? ''} • ${s['jumlahAyat'] ?? ''} ayat', style: const TextStyle(color: muted, fontSize: 12)),
                    trailing: Text(s['nama']?.toString() ?? '', style: const TextStyle(fontSize: 20, color: greenDark)),
                    onTap: () => _push(context, SurahPage(number: s['nomor'] as int, name: s['namaLatin'].toString())),
                  ),
                );
              },
            ),
          ),
        ),
    ]);
  }
}

class SurahPage extends StatefulWidget {
  final int number;
  final String name;
  const SurahPage({super.key, required this.number, required this.name});
  @override
  State<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends State<SurahPage> {
  Map<String, dynamic>? data;
  String? error;
  bool loading = true;
  final player = AudioPlayer();
  String? playingQari;

  @override
  void initState() {
    super.initState();
    _get();
    player.onPlayerComplete.listen((_) { if (mounted) setState(() => playingQari = null); });
  }

  Future<void> _get() async {
    try {
      final r = await http.get(Uri.parse('https://equran.id/api/v2/surat/${widget.number}')).timeout(const Duration(seconds: 20));
      final j = jsonDecode(r.body);
      if (r.statusCode != 200 || j['data'] == null) throw Exception('Konten surah tidak tersedia.');
      if (mounted) setState(() { data = j['data']; loading = false; });
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.name)),
        body: loading
            ? const Center(child: CircularProgressIndicator(color: green))
            : error != null
                ? Center(child: Text(error!))
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    children: [
                      if (data!['audioFull'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: cardDecoration(),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              const Icon(Icons.headphones_rounded, color: green, size: 20),
                              const SizedBox(width: 8),
                              const Text('Audio Murottal', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
                              const Spacer(),
                              if (playingQari != null)
                                TextButton.icon(
                                  onPressed: () async { await player.stop(); if (mounted) setState(() => playingQari = null); },
                                  icon: const Icon(Icons.stop_rounded, size: 18, color: Colors.redAccent),
                                  label: const Text('Stop', style: TextStyle(color: Colors.redAccent)),
                                ),
                            ]),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (data!['audioFull'] as Map<String, dynamic>).entries.take(4).map((e) {
                                final isPlaying = playingQari == e.key;
                                return ChoiceChip(
                                  selected: isPlaying,
                                  selectedColor: green,
                                  backgroundColor: greenSoft,
                                  side: BorderSide.none,
                                  labelStyle: TextStyle(color: isPlaying ? Colors.white : greenDark, fontWeight: FontWeight.w700),
                                  avatar: Icon(isPlaying ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded, size: 18, color: isPlaying ? Colors.white : greenDark),
                                  label: Text('Qari ${e.key}'),
                                  onSelected: (_) async {
                                    try {
                                      await player.stop();
                                      if (isPlaying) {
                                        setState(() => playingQari = null);
                                      } else {
                                        setState(() => playingQari = e.key);
                                        await player.play(UrlSource(e.value.toString()));
                                      }
                                    } catch (_) {
                                      if (mounted) {
                                        setState(() => playingQari = null);
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio gagal diputar. Periksa koneksi.')));
                                      }
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 14),
                      ],
                      for (final a in data!['ayat'] as List<dynamic>)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(18),
                          decoration: cardDecoration(),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: greenSoft, borderRadius: BorderRadius.circular(10)),
                                child: Text('Ayat ${a['nomorAyat']}', style: const TextStyle(color: greenDark, fontWeight: FontWeight.w800, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(a['teksArab']?.toString() ?? '', textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 28, height: 2.0, color: ink)),
                            const SizedBox(height: 14),
                            Text(a['teksLatin']?.toString() ?? '', style: const TextStyle(color: greenDark, fontStyle: FontStyle.italic, height: 1.5)),
                            const SizedBox(height: 8),
                            Text(a['teksIndonesia']?.toString() ?? '', style: const TextStyle(color: muted, height: 1.55)),
                          ]),
                        ),
                    ],
                  ),
      );
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Arah Kiblat')),
        body: Center(
          child: Padding(
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
    return Scaffold(
      appBar: AppBar(title: const Text('Tasbih Digital')),
      body: Center(
        child: Padding(
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
          const InfoCard(icon: Icons.auto_stories_rounded, title: 'Perpustakaan Muslimku', text: 'Kumpulan doa dan hadis ringkas.'),
          const SizedBox(height: 14),
          _navTile(context, 'Doa harian', Icons.volunteer_activism_rounded, const DuaPage()),
          _navTile(context, 'Hadis pilihan', Icons.menu_book_rounded, const HadithPage()),
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
          _navTile(context, 'Arah kiblat', Icons.explore_rounded, const QiblaPage()),
          _navTile(context, 'Tasbih digital', Icons.fingerprint_rounded, const TasbihPage()),
          _navTile(context, 'Doa harian', Icons.volunteer_activism_rounded, const DuaPage()),
          _navTile(context, 'Hadis pilihan', Icons.auto_stories_rounded, const HadithPage()),
          _navTile(context, 'Kalkulator zakat', Icons.calculate_rounded, const ZakatPage()),
          _navTile(context, 'Pengingat salat', Icons.notifications_active_rounded, const ReminderPage()),
          const SizedBox(height: 14),
          const InfoCard(icon: Icons.info_outline_rounded, title: 'Tentang Muslimku', text: 'Versi 1.3.0 • Aplikasi pendamping ibadah.'),
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Doa Harian')),
        body: ListView(
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
        ),
      );
}

class HadithPage extends StatelessWidget {
  const HadithPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Hadis Pilihan')),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: const [
            InfoCard(icon: Icons.menu_book_rounded, title: 'Niat', text: '“Sesungguhnya amal itu tergantung niatnya.”\nHR. Bukhari dan Muslim.'),
            InfoCard(icon: Icons.menu_book_rounded, title: 'Berkata baik', text: '“Barang siapa beriman kepada Allah dan hari akhir, hendaklah berkata baik atau diam.”\nHR. Bukhari dan Muslim.'),
            InfoCard(icon: Icons.menu_book_rounded, title: 'Memudahkan', text: '“Mudahkanlah dan jangan mempersulit, berilah kabar gembira dan jangan membuat orang lari.”\nHR. Bukhari dan Muslim.'),
          ],
        ),
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Kalkulator Zakat Mal')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
          ]),
        ),
      );
}

class ReminderPage extends StatelessWidget {
  const ReminderPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pengingat Salat')),
        body: const Padding(
          padding: EdgeInsets.all(20),
          child: InfoCard(icon: Icons.notifications_active_rounded, title: 'Pengaturan notifikasi', text: 'Halaman jadwal salat sudah dapat mengambil waktu otomatis berdasarkan lokasi.'),
        ),
      );
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

Widget _navTile(BuildContext context, String title, IconData icon, Widget page) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: cardDecoration(),
      child: ListTile(
        leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: greenSoft, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: green, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: ink)),
        trailing: const Icon(Icons.chevron_right_rounded, color: muted),
        onTap: () => _push(context, page),
      ),
    );

void _push(BuildContext context, Widget page) => Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );

BoxDecoration cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE7EFEA)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 14, offset: const Offset(0, 5))],
    );

String _weekday(int n) => const ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'][n - 1];
String _month(int n) => const ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'][n - 1];
