import 'services/prayer_times_service.dart';
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
        title: 'Muslimku', debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: pageBg,
          colorScheme: ColorScheme.fromSeed(seedColor: green),
          appBarTheme: const AppBarTheme(backgroundColor: pageBg, foregroundColor: ink, elevation: 0)),
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
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(toolbarHeight: 66, title: Row(children: [Container(width: 40, height: 40,
      decoration: BoxDecoration(color: greenSoft, borderRadius: BorderRadius.circular(14)),
      child: const Icon(Icons.nightlight_round, color: green)), const SizedBox(width: 10),
      Text(titles[index], style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: ink))])),
    body: IndexedStack(index: index, children: pages),
    bottomNavigationBar: NavigationBar(height: 70, selectedIndex: index,
      onDestinationSelected: (v) => setState(() => index = v), backgroundColor: Colors.white,
      indicatorColor: greenSoft, destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: green), label: 'Beranda'),
        NavigationDestination(icon: Icon(Icons.access_time), selectedIcon: Icon(Icons.access_time_filled, color: green), label: 'Salat'),
        NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book, color: green), label: 'Qur’an'),
        NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories, color: green), label: 'Kitab'),
        NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view, color: green), label: 'Lainnya'),
      ]));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ListView(padding: const EdgeInsets.all(18), children: [
      Text('${_weekday(now.weekday)}, ${now.day} ${_month(now.month)} ${now.year}', style: const TextStyle(color: muted, fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFF218A59), greenDark])),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ASSALAMU’ALAIKUM', style: TextStyle(color: Color(0xFFD8F0E1), letterSpacing: 1.4, fontSize: 11)),
          SizedBox(height: 12), Text('Selamat datang\ndi Muslimku', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
          SizedBox(height: 8), Text('Teman ibadah Anda setiap hari.', style: TextStyle(color: Colors.white70))])),
      const SizedBox(height: 20),
      const SectionTitle('Mulai ibadah hari ini'), const SizedBox(height: 12),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 3,
        crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .95, children: [
          QuickTile('Jadwal salat', Icons.access_time, () => _push(context, const PrayerPage())),
          QuickTile('Al-Qur’an', Icons.menu_book, () => _push(context, const QuranPage())),
          QuickTile('Murottal', Icons.headphones, () => _push(context, const QuranPage())),
          QuickTile('Arah kiblat', Icons.explore, () => _push(context, const QiblaPage())),
          QuickTile('Tasbih', Icons.fingerprint, () => _push(context, const TasbihPage())),
          QuickTile('Doa harian', Icons.volunteer_activism, () => _push(context, const DuaPage())),
        ]),
      const SizedBox(height: 20), const SectionTitle('Pengingat'), const SizedBox(height: 9),
      const InfoCard(icon: Icons.notifications_active_outlined, title: 'Jaga waktu salat',
        text: 'Aktifkan izin notifikasi di perangkat untuk menerima pengingat ibadah. Jadwal salat dihitung dari lokasi perangkat.'),
    ]);
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
      final data =
          await SajadahPrayerTimesService.loadForCurrentLocation();

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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [green, greenDark],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lokasi perangkat',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      result?.regionName ??
                          'Mendeteksi lokasi perangkat...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (result != null)
                      Text(
                        result!.province,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: loading ? null : _load,
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: CircularProgressIndicator(color: green),
            ),
          ),

        if (error != null)
          InfoCard(
            icon: Icons.info_outline,
            title: 'Jadwal belum tersedia',
            text: error!,
          ),

        if (result != null) ...[
          Text(
            'Jadwal salat hari ini',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
          ),

          const SizedBox(height: 10),

          for (final entry in result!.times.entries)
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              decoration: cardDecoration(),
              child: ListTile(
                leading: const Icon(
                  Icons.access_time,
                  color: green,
                ),
                title: Text(
                  entry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 17,
                    color: greenDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

          Text(
            result!.fromCache
                ? 'Jadwal menggunakan data tersimpan (offline).'
                : 'Sumber jadwal: Sajadah Open Data.',
            style: const TextStyle(
              color: muted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}


class QuranPage extends StatefulWidget { const QuranPage({super.key}); @override State<QuranPage> createState() => _QuranPageState(); }
class _QuranPageState extends State<QuranPage> {
  List<dynamic> surahs = []; bool loading = true; String? error;
  @override void initState() { super.initState(); _fetch(); }
  Future<void> _fetch() async { try { final r = await http.get(Uri.parse('https://equran.id/api/v2/surat')).timeout(const Duration(seconds: 20)); if (r.statusCode != 200) throw Exception('Gagal mengambil daftar surah.'); final d = jsonDecode(r.body); if (!mounted) return; setState(() { surahs = d['data'] as List<dynamic>; loading = false; }); } catch (e) { if (mounted) setState(() { error = e.toString(); loading = false; }); } }
  @override Widget build(BuildContext context) => Column(children: [Padding(padding: const EdgeInsets.fromLTRB(18, 10, 18, 10), child: const InfoCard(icon: Icons.menu_book, title: 'Al-Qur’an digital', text: 'Daftar surah dan bacaan diambil dari layanan eQuran.id. Koneksi internet diperlukan.')),
    if (loading) const Expanded(child: Center(child: CircularProgressIndicator(color: green)))
    else if (error != null) Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('$error\nPeriksa koneksi internet lalu buka ulang halaman.', textAlign: TextAlign.center))))
    else Expanded(child: RefreshIndicator(onRefresh: _fetch, child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 18), itemCount: surahs.length, itemBuilder: (c, i) {
      final s = surahs[i] as Map<String, dynamic>; return Container(margin: const EdgeInsets.only(bottom: 8), decoration: cardDecoration(), child: ListTile(
        leading: CircleAvatar(backgroundColor: greenSoft, child: Text('${s['nomor']}', style: const TextStyle(color: green, fontWeight: FontWeight.bold))),
        title: Text(s['namaLatin']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${s['arti'] ?? ''} • ${s['jumlahAyat'] ?? ''} ayat'),
        trailing: Text(s['nama']?.toString() ?? '', style: const TextStyle(fontSize: 18, color: greenDark)), onTap: () => _push(context, SurahPage(number: s['nomor'] as int, name: s['namaLatin'].toString()))));
    }))) ]);
}

class SurahPage extends StatefulWidget { final int number; final String name; const SurahPage({super.key, required this.number, required this.name}); @override State<SurahPage> createState() => _SurahPageState(); }
class _SurahPageState extends State<SurahPage> {
  Map<String, dynamic>? data; String? error; bool loading = true; final player = AudioPlayer();
  @override void initState() { super.initState(); _get(); }
  Future<void> _get() async { try { final r = await http.get(Uri.parse('https://equran.id/api/v2/surat/${widget.number}')).timeout(const Duration(seconds: 20)); final j = jsonDecode(r.body); if (r.statusCode != 200 || j['data'] == null) throw Exception('Konten surah tidak tersedia.'); if (mounted) setState(() { data = j['data']; loading = false; }); } catch (e) { if (mounted) setState(() { error = e.toString(); loading = false; }); } }
  @override void dispose() { player.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.name)), body: loading ? const Center(child: CircularProgressIndicator(color: green)) : error != null ? Center(child: Text(error!)) : ListView(padding: const EdgeInsets.all(16), children: [
    if (data!['audioFull'] != null) ...[const Text('Audio murottal', style: TextStyle(fontWeight: FontWeight.bold, color: ink)), const SizedBox(height: 8), Wrap(spacing: 8, children: (data!['audioFull'] as Map<String, dynamic>).entries.take(4).map((e) => OutlinedButton.icon(onPressed: () async { try { await player.stop(); await player.play(UrlSource(e.value.toString())); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio gagal diputar. Periksa koneksi.'))); } }, icon: const Icon(Icons.play_arrow), label: Text('Qari ${e.key}'))).toList()), const SizedBox(height: 12)],
    for (final a in data!['ayat'] as List<dynamic>) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: cardDecoration(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('Ayat ${a['nomorAyat']}', style: const TextStyle(color: green, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text(a['teksArab']?.toString() ?? '', textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 27, height: 1.9, color: ink)), const SizedBox(height: 12), Text(a['teksLatin']?.toString() ?? '', style: const TextStyle(color: greenDark, fontStyle: FontStyle.italic)), const SizedBox(height: 7), Text(a['teksIndonesia']?.toString() ?? '', style: const TextStyle(color: muted, height: 1.5))]))
  ]));
}

class QiblaPage extends StatefulWidget { const QiblaPage({super.key}); @override State<QiblaPage> createState() => _QiblaPageState(); }
class _QiblaPageState extends State<QiblaPage> {
  double? bearing; double? heading; String? error;
  @override void initState() { super.initState(); _calc(); }
  Future<void> _calc() async { try { var p = await Geolocator.checkPermission(); if (p == LocationPermission.denied) p = await Geolocator.requestPermission(); if (p == LocationPermission.denied || p == LocationPermission.deniedForever) throw Exception('Izin lokasi dibutuhkan untuk menentukan arah kiblat.'); final pos = await Geolocator.getCurrentPosition(); const latK = 21.4225, lonK = 39.8262; final lat1 = pos.latitude * math.pi / 180, lat2 = latK * math.pi / 180, dLon = (lonK - pos.longitude) * math.pi / 180; final y = math.sin(dLon); final x = math.cos(lat1) * math.tan(lat2) - math.sin(lat1) * math.cos(dLon); if (mounted) setState(() => bearing = (math.atan2(y, x) * 180 / math.pi + 360) % 360); } catch (e) { if (mounted) setState(() => error = e.toString()); } }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Arah Kiblat')), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.explore, color: green, size: 52), const SizedBox(height: 12), const Text('Arah Ka’bah', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 10), if (error != null) Text(error!, textAlign: TextAlign.center), if (bearing != null) ...[Text('${bearing!.toStringAsFixed(1)}° dari utara sejati', style: const TextStyle(fontSize: 18, color: greenDark, fontWeight: FontWeight.bold)), const SizedBox(height: 18), StreamBuilder<CompassEvent>(stream: FlutterCompass.events, builder: (c, s) { heading = s.data?.heading; final angle = bearing! - (heading ?? 0); return Transform.rotate(angle: angle * math.pi / 180, child: Container(width: 210, height: 210, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: green, width: 2)), child: const Icon(Icons.navigation, size: 125, color: green))); }), const SizedBox(height: 12), const Text('Putar perangkat sampai penunjuk mengarah ke atas. Jauhkan ponsel dari benda bermagnet dan kalibrasikan kompas.', textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.5, fontSize: 12))], OutlinedButton.icon(onPressed: _calc, icon: const Icon(Icons.refresh), label: const Text('Perbarui lokasi'))]))));
}

class TasbihPage extends StatefulWidget { const TasbihPage({super.key}); @override State<TasbihPage> createState() => _TasbihPageState(); }
class _TasbihPageState extends State<TasbihPage> {
  int count = 0, target = 33; String phrase = 'Subhanallah';
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final p = await SharedPreferences.getInstance(); if (mounted) setState(() { count = p.getInt('tasbih_count') ?? 0; target = p.getInt('tasbih_target') ?? 33; phrase = p.getString('tasbih_phrase') ?? 'Subhanallah'; }); }
  Future<void> _save() async { final p = await SharedPreferences.getInstance(); await p.setInt('tasbih_count', count); await p.setInt('tasbih_target', target); await p.setString('tasbih_phrase', phrase); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Tasbih Digital')), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [DropdownButton<String>(value: phrase, items: const ['Subhanallah','Alhamdulillah','Allahu Akbar','Astaghfirullah','La ilaha illallah'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) setState(() => phrase = v); _save(); }), const SizedBox(height: 15), Text('$count', style: const TextStyle(fontSize: 76, fontWeight: FontWeight.w800, color: greenDark)), Text('Target $target', style: const TextStyle(color: muted)), const SizedBox(height: 20), GestureDetector(onTap: () { setState(() => count++); _save(); if (count == target) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alhamdulillah, target zikir tercapai!'))); }, child: Container(width: 190, height: 190, decoration: BoxDecoration(shape: BoxShape.circle, color: green, boxShadow: [BoxShadow(color: green.withOpacity(.25), blurRadius: 18, offset: const Offset(0, 8))]), child: const Center(child: Text('ZIKIR', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))))), const SizedBox(height: 18), Wrap(spacing: 10, children: [OutlinedButton(onPressed: () { setState(() => count = 0); _save(); }, child: const Text('Reset')), OutlinedButton(onPressed: () async { final v = await showDialog<int>(context: context, builder: (c) { int n = target; return AlertDialog(title: const Text('Atur target'), content: StatefulBuilder(builder: (c, setD) => DropdownButton<int>(value: n, items: [33, 99, 100, 1000].map((x) => DropdownMenuItem(value: x, child: Text('$x'))).toList(), onChanged: (x) { if (x != null) setD(() => n = x); })), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')), TextButton(onPressed: () => Navigator.pop(c, n), child: const Text('Simpan'))]); }); if (v != null) { setState(() => target = v); _save(); } }, child: const Text('Target'))])]))));
}

class LibraryPage extends StatelessWidget { const LibraryPage({super.key}); @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [const InfoCard(icon: Icons.auto_stories, title: 'Perpustakaan Muslimku', text: 'Kumpulan doa dan hadis ringkas. Untuk kajian hukum, rujuk kitab dan ulama yang tepercaya.'), const SizedBox(height: 12), _navTile(context, 'Doa harian', Icons.volunteer_activism, const DuaPage()), _navTile(context, 'Hadis pilihan', Icons.menu_book, const HadithPage())]); }
class MorePage extends StatelessWidget { const MorePage({super.key}); @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [_navTile(context, 'Arah kiblat', Icons.explore, const QiblaPage()), _navTile(context, 'Tasbih digital', Icons.fingerprint, const TasbihPage()), _navTile(context, 'Doa harian', Icons.volunteer_activism, const DuaPage()), _navTile(context, 'Hadis pilihan', Icons.auto_stories, const HadithPage()), _navTile(context, 'Kalkulator zakat', Icons.calculate, const ZakatPage()), _navTile(context, 'Pengingat salat', Icons.notifications_active, const ReminderPage()), const SizedBox(height: 12), const InfoCard(icon: Icons.info_outline, title: 'Tentang Muslimku', text: 'Versi 1.2.0 • Aplikasi pendamping ibadah. Periksa kembali waktu dan arah dengan otoritas setempat.')]); }

class DuaPage extends StatelessWidget { const DuaPage({super.key}); static const duas = [('Doa sebelum makan','بِسْمِ اللَّهِ','Bismillah.','Dengan nama Allah.'),('Doa sesudah makan','الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا','Alhamdulillahil ladzi ath’amana wa saqana.','Segala puji bagi Allah yang telah memberi kami makan dan minum.'),('Doa masuk rumah','بِسْمِ اللَّهِ وَلَجْنَا وَبِسْمِ اللَّهِ خَرَجْنَا','Bismillahi walajna wa bismillahi kharajna.','Dengan nama Allah kami masuk dan dengan nama Allah kami keluar.')]; @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Doa Harian')), body: ListView(padding: const EdgeInsets.all(16), children: [for (final d in duas) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(17), decoration: cardDecoration(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(d.$1, style: const TextStyle(fontWeight: FontWeight.bold, color: greenDark)), const SizedBox(height: 12), Text(d.$2, textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 24, height: 1.8)), const SizedBox(height: 8), Text(d.$3, style: const TextStyle(fontStyle: FontStyle.italic, color: green)), const SizedBox(height: 5), Text(d.$4, style: const TextStyle(color: muted))]))])); }
class HadithPage extends StatelessWidget { const HadithPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Hadis Pilihan')), body: ListView(padding: const EdgeInsets.all(16), children: const [InfoCard(icon: Icons.menu_book, title: 'Niat', text: '“Sesungguhnya amal itu tergantung niatnya.”\nHR. Bukhari dan Muslim.'), InfoCard(icon: Icons.menu_book, title: 'Berkata baik', text: '“Barang siapa beriman kepada Allah dan hari akhir, hendaklah berkata baik atau diam.”\nHR. Bukhari dan Muslim.'), InfoCard(icon: Icons.menu_book, title: 'Memudahkan', text: '“Mudahkanlah dan jangan mempersulit, berilah kabar gembira dan jangan membuat orang lari.”\nHR. Bukhari dan Muslim.'), Padding(padding: EdgeInsets.all(8), child: Text('Terjemahan ringkas. Nomor hadis dapat berbeda menurut edisi kitab.', style: TextStyle(color: muted, fontSize: 11))) ])); }
class ZakatPage extends StatefulWidget { const ZakatPage({super.key}); @override State<ZakatPage> createState() => _ZakatPageState(); }
class _ZakatPageState extends State<ZakatPage> { final c = TextEditingController(); double result = 0; @override void dispose() { c.dispose(); super.dispose(); } @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Kalkulator Zakat Mal')), body: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('Masukkan total harta yang memenuhi ketentuan zakat dan telah mencapai nisab serta haul.'), const SizedBox(height: 15), TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nilai harta (Rupiah)', border: OutlineInputBorder(), prefixText: 'Rp '), onChanged: (_) => setState(() => result = (double.tryParse(c.text.replaceAll('.', '').replaceAll(',', '')) ?? 0) * .025)), const SizedBox(height: 18), Text('Estimasi zakat 2,5%: Rp ${result.toStringAsFixed(0)}', style: const TextStyle(color: greenDark, fontSize: 19, fontWeight: FontWeight.bold)), const SizedBox(height: 10), const Text('Ini simulasi sederhana, bukan penetapan kewajiban. Konsultasikan nisab, haul, jenis harta, dan ketentuan kepada lembaga zakat.', style: TextStyle(color: muted, height: 1.5))]))); }
class ReminderPage extends StatelessWidget { const ReminderPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Pengingat Salat')), body: const Padding(padding: EdgeInsets.all(20), child: InfoCard(icon: Icons.notifications_active, title: 'Pengaturan notifikasi', text: 'Fitur pengingat terjadwal memerlukan konfigurasi izin notifikasi dan alarm pada Android. Untuk versi ini, halaman jadwal salat sudah dapat mengambil waktu berdasarkan lokasi. Aktifkan notifikasi aplikasi melalui Pengaturan Android setelah modul pengingat dikonfigurasi.'))); }

class QuickTile extends StatelessWidget { final String title; final IconData icon; final VoidCallback onTap; const QuickTile(this.title, this.icon, this.onTap, {super.key}); @override Widget build(BuildContext context) => Material(color: Colors.white, borderRadius: BorderRadius.circular(18), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8EDE9))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: green, size: 29), const SizedBox(height: 8), Text(title, textAlign: TextAlign.center, style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 11))])))); }
class SectionTitle extends StatelessWidget { final String title; const SectionTitle(this.title, {super.key}); @override Widget build(BuildContext context) => Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)); }
class InfoCard extends StatelessWidget { final IconData icon; final String title, text; const InfoCard({super.key, required this.icon, required this.title, required this.text}); @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: cardDecoration(), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: green), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 5), Text(text, style: const TextStyle(color: muted, height: 1.45, fontSize: 12))]))])); }
Widget _navTile(BuildContext context, String title, IconData icon, Widget page) => Container(margin: const EdgeInsets.only(bottom: 9), decoration: cardDecoration(), child: ListTile(leading: Icon(icon, color: green), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), trailing: const Icon(Icons.chevron_right), onTap: () => _push(context, page)));
void _push(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
BoxDecoration cardDecoration() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFE8EDE9)), boxShadow: const [BoxShadow(color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 3))]);
String _weekday(int n) => const ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'][n-1];
String _month(int n) => const ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'][n-1];
