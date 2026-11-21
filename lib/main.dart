import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MuslimkuApp());
}

class MuslimkuApp extends StatelessWidget {
  const MuslimkuApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF157A4B);
    return MaterialApp(
      title: 'Muslimku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          surface: const Color(0xFFF6F7F2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    PrayerPage(),
    QuranPage(),
    LibraryPage(),
    MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF157A4B);
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        indicatorColor: primaryGreen.withOpacity(0.15),
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: primaryGreen),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time_filled, color: primaryGreen),
            label: 'Salat',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: primaryGreen),
            label: 'Qur’an',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories, color: primaryGreen),
            label: 'Kitab',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded, color: primaryGreen),
            label: 'Lainnya',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BERANDA (HOME PAGE)
// ============================================================================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF157A4B);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Muslimku', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF157A4B), Color(0xFF0E5A36)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assalamu’alaikum',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'Pendamping Ibadah & Kajian Harian',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Akses Jadwal Salat, Al-Qur’an, Doa, Hadis, hingga Kitab Kuning Pesantren dalam satu aplikasi ringan.',
                  style: TextStyle(color: Colors.white, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Akses Cepat',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: [
              _quickCard(
                context,
                icon: Icons.auto_stories_rounded,
                title: 'Kitab Kuning',
                subtitle: 'Arab, Latin & Arti',
                color: primaryGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KitabListPage()),
                ),
              ),
              _quickCard(
                context,
                icon: Icons.volunteer_activism_rounded,
                title: 'Doa Harian',
                subtitle: 'Kumpulan Doa Pilihan',
                color: primaryGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DuaPage()),
                ),
              ),
              _quickCard(
                context,
                icon: Icons.format_quote_rounded,
                title: 'Hadis Pilihan',
                subtitle: 'Arba’in & Akhlak',
                color: primaryGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HadithPage()),
                ),
              ),
              _quickCard(
                context,
                icon: Icons.fingerprint_rounded,
                title: 'Tasbih Digital',
                subtitle: 'Hitung Dzikir Harian',
                color: primaryGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TasbihPage()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E7DF)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// JADWAL SALAT (PRAYER PAGE)
// ============================================================================
class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  String _city = 'Blitar';
  bool _loading = false;
  Map<String, String> _times = {
    'Subuh': '04:05',
    'Dzuhur': '11:32',
    'Ashar': '14:52',
    'Maghrib': '17:41',
    'Isya': '18:53',
  };

  Future<void> _fetchPrayerTimes(String city) async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
        'https://api.aladhan.com/v1/timingsByCity?city=${Uri.encodeComponent(city)}&country=Indonesia&method=20',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final t = data['data']['timings'] as Map<String, dynamic>;
        setState(() {
          _city = city;
          _times = {
            'Subuh': (t['Fajr'] ?? '04:05').toString().split(' ').first,
            'Dzuhur': (t['Dhuhr'] ?? '11:32').toString().split(' ').first,
            'Ashar': (t['Asr'] ?? '14:52').toString().split(' ').first,
            'Maghrib': (t['Maghrib'] ?? '17:41').toString().split(' ').first,
            'Isya': (t['Isha'] ?? '18:53').toString().split(' ').first,
          };
        });
      }
    } catch (_) {
      // Tetap tampilkan jadwal default jika offline
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPrayerTimes(_city);
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF157A4B);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Salat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchPrayerTimes(_city),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE3E7DF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Wilayah: $_city, Indonesia',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (_loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._times.entries.map(
            (e) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE3E7DF)),
              ),
              child: ListTile(
                leading: const Icon(Icons.access_time, color: primaryGreen),
                title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Text(
                  e.value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// AL-QUR'AN (QURAN PAGE & SURAH READER)
// ============================================================================
class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  List<dynamic> _surahs = [];
  bool _loading = true;

  Future<void> _loadSurahs() async {
    try {
      final res = await http
          .get(Uri.parse('https://equran.id/api/v2/surat'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _surahs = body['data'] as List<dynamic>;
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF157A4B);
    return Scaffold(
      appBar: AppBar(title: const Text('Al-Qur’an Digital')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _surahs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Gagal memuat daftar surah. Periksa koneksi internet.'),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _loadSurahs, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _surahs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final s = _surahs[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE3E7DF)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryGreen.withOpacity(0.12),
                          child: Text(
                            '${s['nomor']}',
                            style: const TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          '${s['namaLatin']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${s['arti']} • ${s['jumlahAyat']} Ayat'),
                        trailing: Text(
                          '${s['nama']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SurahPage(
                              nomor: s['nomor'],
                              namaLatin: s['namaLatin'],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class SurahPage extends StatefulWidget {
  final int nomor;
  final String namaLatin;
  const SurahPage({super.key, required this.nomor, required this.namaLatin});

  @override
  State<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends State<SurahPage> {
  List<dynamic> _ayat = [];
  bool _loading = true;

  Future<void> _loadAyat() async {
    try {
      final res = await http
          .get(Uri.parse('https://equran.id/api/v2/surat/${widget.nomor}'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _ayat = body['data']['ayat'] as List<dynamic>;
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _loadAyat();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF157A4B);
    return Scaffold(
      appBar: AppBar(title: Text(widget.namaLatin)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _ayat.length,
              itemBuilder: (context, index) {
                final a = _ayat[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE3E7DF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${a['teksArab']}',
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontSize: 22, height: 1.8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${a['teksLatin']}',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: primaryGreen,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${a['nomorAyat']}. ${a['teksIndonesia']}',
                        style: const TextStyle(fontSize: 13.5, height: 1.4),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// TAB KITAB (LIBRARY PAGE) — TERINTEGRASI KITAB KUNING PESANTREN
// ============================================================================
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF157A4B);
    return Scaffold(
      appBar: AppBar(title: const Text('Kitab & Pustaka Islam')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _navTile(
            context,
            icon: Icons.auto_stories_rounded,
            title: 'Kitab Kuning Pesantren',
            subtitle: 'Safinatun Najah, Ta’limul Muta’allim (Arab, Latin Indonesia & Terjemah)',
            badge: 'BARU',
            color: primaryGreen,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KitabListPage()),
            ),
          ),
          _navTile(
            context,
            icon: Icons.volunteer_activism_rounded,
            title: 'Kumpulan Doa Harian',
            subtitle: 'Doa sehari-hari lengkap dengan teks Arab, Latin & artinya',
            color: primaryGreen,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DuaPage()),
            ),
          ),
          _navTile(
            context,
            icon: Icons.format_quote_rounded,
            title: 'Hadis Pilihan & Arba’in',
            subtitle: 'Matan hadis ringkas, bacaan Latin & terjemahan',
            color: primaryGreen,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HadithPage()),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _navTile(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
  String? badge,
}) {
  return Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Color(0xFFE3E7DF)),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.12),
        child: Icon(icon, color: color),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle, style: const TextStyle(fontSize: 12.5)),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

// ============================================================================
// DOA HARIAN (DUA PAGE)
// ============================================================================
class DuaPage extends StatelessWidget {
  const DuaPage({super.key});

  static const List<Map<String, String>> _duas = [
    {
      'judul': 'Doa Sebelum Tidur',
      'arab': 'بِسْمِكَ اللّٰهُمَّ أَحْيَا وَأَمُوْتُ',
      'latin': 'Bismikallahumma ahya wa amutu.',
      'arti': 'Dengan nama-Mu ya Allah aku hidup dan aku mati.',
    },
    {
      'judul': 'Doa Bangun Tidur',
      'arab': 'اَلْحَمْدُ لِلّٰهِ الَّذِيْ أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُوْرُ',
      'latin': 'Alhamdulillahil-ladzi ahyana ba'da ma amatana wa ilaihin-nusyuru.',
      'arti': 'Segala puji bagi Allah yang telah menghidupkan kami setelah mematikan kami, dan kepada-Nya kami kembali.',
    },
    {
      'judul': 'Doa Kebaikan Dunia & Akhirat',
      'arab': 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      'latin': 'Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adzaban-nar.',
      'arti': 'Ya Tuhan kami, berilah kami kebaikan di dunia dan kebaikan di akhirat, serta lindungilah kami dari siksa neraka.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF157A4B);
    return Scaffold(
      appBar: AppBar(title: const Text('Kumpulan Doa Harian')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _duas.length,
        itemBuilder: (context, index) {
          final d = _duas[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE3E7DF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  d['judul']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Text(
                  d['arab']!,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 22, height: 1.7),
                ),
                const SizedBox(height: 6),
                Text(
                  d['latin']!,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: primaryGreen,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(d['arti']!, style: const TextStyle(fontSize: 13.5)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// HADIS PILIHAN (HADITH PAGE)
// ============================================================================
class HadithPage extends StatelessWidget {
  const HadithPage({super.key});

  static const List<Map<String, String>> _hadiths = [
    {
      'judul': 'Hadis Niat (Arba’in Nawawi #1)',
      'arab': 'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
      'latin': 'Innamal a'malu bin-niyyati, wa innama likullimri-in ma nawa.',
      'arti': 'Sesungguhnya setiap amal tergantung pada niatnya, dan setiap orang akan mendapatkan sesuai dengan apa yang ia niatkan. (HR. Bukhari & Muslim)',
    },
    {
      'judul': 'Meninggalkan yang Tidak Bermanfaat (Arba’in #12)',
      'arab': 'مِنْ حُسْنِ إِسْلَامِ الْمَرْءِ تَرْكُهُ مَا لَا يَعْنِيهِ',
      'latin': 'Min husni islamil mar-i tarkuhu ma la ya'nihi.',
      'arti': 'Di antara tanda kebaikan keislaman seseorang adalah meninggalkan hal-hal yang tidak bermanfaat baginya. (HR. Tirmidzi)',
    },
  ];

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF157A4B);
    return Scaffold(
      appBar: AppBar(title: const Text('Hadis Pilihan')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _hadiths.length,
        itemBuilder: (context, index) {
          final h = _hadiths[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE3E7DF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  h['judul']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Text(
                  h['arab']!,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 22, height: 1.7),
                ),
                const SizedBox(height: 6),
                Text(
                  h['latin']!,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: primaryGreen,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(h['arti']!, style: const TextStyle(fontSize: 13.5)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// TAB LAINNYA (MORE PAGE)
// ============================================================================
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF157A4B);
    return Scaffold(
      appBar: AppBar(title: const Text('Fitur Lainnya')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _navTile(
            context,
            icon: Icons.auto_stories_rounded,
            title: 'Kitab Kuning Reader',
            subtitle: 'Baca Safinatun Najah & Ta’limul Muta’allim (Arab, Latin & Terjemah)',
            badge: 'PESANTREN',
            color: primaryGreen,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KitabListPage()),
            ),
          ),
          _navTile(
            context,
            icon: Icons.fingerprint_rounded,
            title: 'Tasbih Digital',
            subtitle: 'Penghitung dzikir harian dengan target 33 / 100',
            color: primaryGreen,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TasbihPage()),
            ),
          ),
          _navTile(
            context,
            icon: Icons.explore_rounded,
            title: 'Arah Kiblat',
            subtitle: 'Panduan sudut arah kiblat dari lokasi Anda',
            color: primaryGreen,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QiblaPage()),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TASBIH DIGITAL & ARAH KIBLAT
// ============================================================================
class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key});

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF157A4B);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasbih Digital'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _count = 0),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_count',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(42),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _count++);
              },
              child: const Text('DZIKIR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF157A4B);
    return Scaffold(
      appBar: AppBar(title: const Text('Arah Kiblat')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: -math.pi / 4,
                child: const Icon(Icons.navigation_rounded, size: 96, color: primaryGreen),
              ),
              const SizedBox(height: 16),
              const Text(
                'Arah Kiblat (Indonesia / Jawa)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '± 294° Barat Laut menuju Ka’bah, Makkah Al-Mukarramah.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DATA & PEMBACA KITAB KUNING PESANTREN (ARAB + LATIN INDONESIA + TERJEMAHAN)
// ============================================================================
class KitabFasal {
  final String nomor;
  final String arab;
  final String latin;
  final String terjemah;

  const KitabFasal({
    required this.nomor,
    required this.arab,
    required this.latin,
    required this.terjemah,
  });
}

class KitabBab {
  final String namaKitab;
  final String judulBab;
  final String kategori;
  final List<KitabFasal> isi;

  const KitabBab({
    required this.namaKitab,
    required this.judulBab,
    required this.kategori,
    required this.isi,
  });
}

const List<KitabBab> daftarKitabPesantren = [
  KitabBab(
    namaKitab: 'Safinatun Najah',
    judulBab: 'Bab Taharah — Fardu Wudu',
    kategori: 'Fiqih',
    isi: [
      KitabFasal(
        nomor: 'Fasal',
        arab: 'فَصْلٌ: فُرُوْضُ الْوُضُوْءِ سِتَّةٌ',
        latin: 'Fashlun: furudhul wudhu-i sittatun.',
        terjemah: 'Fasal: Fardu (rukun) wudu ada enam.',
      ),
      KitabFasal(
        nomor: '1',
        arab: 'اَلْأَوَّلُ: النِّيَّةُ',
        latin: 'Al-awwalu: an-niyyatu.',
        terjemah: 'Pertama: Niat.',
      ),
      KitabFasal(
        nomor: '2',
        arab: 'الثَّانِي: غَسْلُ الْوَجْهِ',
        latin: 'Ats-tsani: ghaslul wajhi.',
        terjemah: 'Kedua: Membasuh wajah.',
      ),
      KitabFasal(
        nomor: '3',
        arab: 'الثَّالِثُ: غَسْلُ الْيَدَيْنِ مَعَ الْمِرْفَقَيْنِ',
        latin: 'Ats-tsalitsu: ghaslul yadaini ma'al mirfaqaini.',
        terjemah: 'Ketiga: Membasuh kedua tangan sampai ke siku.',
      ),
      KitabFasal(
        nomor: '4',
        arab: 'الرَّابِعُ: مَسْحُ شَيْءٍ مِنَ الرَّأْسِ',
        latin: 'Ar-rabi'u: mashu syai-in minar ra'si.',
        terjemah: 'Keempat: Mengusap sebagian kepala.',
      ),
      KitabFasal(
        nomor: '5',
        arab: 'الْخَامِسُ: غَسْلُ الرِّجْلَيْنِ مَعَ الْكَعْبَيْنِ',
        latin: 'Al-khamisu: ghaslur rijlaini ma'al ka'baini.',
        terjemah: 'Kelima: Membasuh kedua kaki sampai kedua mata kaki.',
      ),
      KitabFasal(
        nomor: '6',
        arab: 'السَّادِسُ: التَّرْتِيْبُ',
        latin: 'As-sadisu: at-tartibu.',
        terjemah: 'Keenam: Tertib (berurutan).',
      ),
    ],
  ),
  KitabBab(
    namaKitab: 'Safinatun Najah',
    judulBab: 'Rukun Islam & Rukun Iman',
    kategori: 'Tauhid & Fiqih',
    isi: [
      KitabFasal(
        nomor: 'Fasal',
        arab: 'فَصْلٌ: أَرْكَانُ الْإِسْلَامِ خَمْسَةٌ',
        latin: 'Fashlun: arkanul islami khamsatun.',
        terjemah: 'Fasal: Rukun Islam ada lima.',
      ),
      KitabFasal(
        nomor: '1',
        arab: 'شَهَادَةُ أَنْ لَا إِلٰهَ إِلَّا اللّٰهُ وَأَنَّ مُحَمَّدًا رَسُوْلُ اللّٰهِ',
        latin: 'Syahadatu an la ilaha illallahu wa anna Muhammadan rasulullahi.',
        terjemah: 'Bersaksi bahwa tiada tuhan selain Allah dan Nabi Muhammad adalah utusan Allah.',
      ),
      KitabFasal(
        nomor: '2',
        arab: 'وَإِقَامُ الصَّلَاةِ',
        latin: 'Wa iqamush-shalati.',
        terjemah: 'Mendirikan salat.',
      ),
      KitabFasal(
        nomor: '3',
        arab: 'وَإِيْتَاءُ الزَّكَاةِ',
        latin: 'Wa ita-uz-zakati.',
        terjemah: 'Menunaikan zakat.',
      ),
      KitabFasal(
        nomor: '4',
        arab: 'وَصَوْمُ رَمَضَانَ',
        latin: 'Wa shaumu Ramadhana.',
        terjemah: 'Berpuasa di bulan Ramadan.',
      ),
      KitabFasal(
        nomor: '5',
        arab: 'وَحِجُّ الْبَيْتِ مَنِ اسْتَطَاعَ إِلَيْهِ سَبِيْلًا',
        latin: 'Wa hijjul baiti manistatha'a ilaihi sabila.',
        terjemah: 'Menunaikan ibadah haji ke Baitullah bagi yang mampu menempuh perjalanannya.',
      ),
    ],
  ),
  KitabBab(
    namaKitab: 'Ta'limul Muta'allim',
    judulBab: 'Syarat & Adab Menuntut Ilmu',
    kategori: 'Adab & Akhlak',
    isi: [
      KitabFasal(
        nomor: '1',
        arab: 'أَلَا لَا تَنَالُ الْعِلْمَ إِلَّا بِسِتَّةٍ',
        latin: 'Ala la tanalul 'ilma illa bisittatin.',
        terjemah: 'Ingatlah, engkau tidak akan meraih ilmu kecuali dengan enam syarat.',
      ),
      KitabFasal(
        nomor: '2',
        arab: 'ذَكَاءٍ وَحِرْصٍ وَاصْطِبَارٍ وَبُلْغَةٍ وَإِرْشَادِ أُسْتَاذٍ وَطُوْلِ زَمَانٍ',
        latin: 'Dzaka-in wa hirshin washthibarin wa bulghatin, wa irsyadi ustadzin wa thuli zamanin.',
        terjemah: 'Kecerdasan, semangat tinggi, kesabaran, bekal yang cukup, petunjuk guru, dan waktu yang panjang.',
      ),
    ],
  ),
];

class KitabListPage extends StatefulWidget {
  const KitabListPage({super.key});

  @override
  State<KitabListPage> createState() => _KitabListPageState();
}

class _KitabListPageState extends State<KitabListPage> {
  String _selectedCategory = 'Semua';

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF157A4B);
    final categories = ['Semua', 'Fiqih', 'Tauhid & Fiqih', 'Adab & Akhlak'];
    final filtered = _selectedCategory == 'Semua'
        ? daftarKitabPesantren
        : daftarKitabPesantren
            .where((k) => k.kategori == _selectedCategory)
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Kitab Kuning Pesantren')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final active = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: active,
                  selectedColor: primaryGreen,
                  labelStyle: TextStyle(
                    color: active ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final bab = filtered[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE3E7DF)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: primaryGreen.withOpacity(0.12),
                      child: const Icon(Icons.menu_book_rounded, color: primaryGreen),
                    ),
                    title: Text(
                      bab.namaKitab,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${bab.judulBab} • ${bab.isi.length} poin'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => KitabReaderPage(bab: bab)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum ReaderMode { arLtId, arId, arOnly }

class KitabReaderPage extends StatefulWidget {
  final KitabBab bab;
  const KitabReaderPage({super.key, required this.bab});

  @override
  State<KitabReaderPage> createState() => _KitabReaderPageState();
}

class _KitabReaderPageState extends State<KitabReaderPage> {
  double _arabicFontSize = 22.0;
  ReaderMode _mode = ReaderMode.arLtId;
  late KitabBab _currentBab;

  @override
  void initState() {
    super.initState();
    _currentBab = widget.bab;
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF157A4B);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F2),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: const Text('Kitab Kuning Reader'),
      ),
      body: Column(
        children: [
          // Header Badge Kitab & Bab
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFECE1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD5CEB8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: primaryGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_currentBab.namaKitab} — ${_currentBab.judulBab}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF233029),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Daftar Fasal / Poin Kitab
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: _currentBab.isi.length,
              itemBuilder: (context, index) {
                final item = _currentBab.isi[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCECE3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.nomor != 'Fasal')
                        Padding(
                          padding: const EdgeInsets.only(right: 10, top: 4),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: primaryGreen.withOpacity(0.15),
                            child: Text(
                              item.nomor,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              item.arab,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: _arabicFontSize,
                                height: 1.7,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF13221A),
                              ),
                            ),
                            if (_mode == ReaderMode.arLtId) ...[
                              const SizedBox(height: 6),
                              Text(
                                item.latin,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13.5,
                                  color: Color(0xFF157A4B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if (_mode == ReaderMode.arLtId ||
                                _mode == ReaderMode.arId) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.terjemah,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  height: 1.4,
                                  color: Color(0xFF222B26),
                                ),
                              ),
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

          // Panel Kontrol Bawah (Dropdown Bab, Font Size & Mode Bacaan)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0E4DC))),
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
                          items: daftarKitabPesantren.map((bab) {
                            return DropdownMenuItem<KitabBab>(
                              value: bab,
                              child: Text(
                                '${bab.namaKitab} | ${bab.judulBab}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _currentBab = val);
                            }
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
                    _modeChip('AR + LT + ID', ReaderMode.arLtId, primaryGreen),
                    const SizedBox(width: 8),
                    _modeChip('AR + ID', ReaderMode.arId, primaryGreen),
                    const SizedBox(width: 8),
                    _modeChip('AR Only', ReaderMode.arOnly, primaryGreen),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, ReaderMode mode, Color primaryColor) {
    final selected = _mode == mode;
    return Expanded(
      child: ChoiceChip(
        label: Center(
          child: Text(label, style: const TextStyle(fontSize: 11.5)),
        ),
        selected: selected,
        selectedColor: primaryColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => setState(() => _mode = mode),
      ),
    );
  }
}
