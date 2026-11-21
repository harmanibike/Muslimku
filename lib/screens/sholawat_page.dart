import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _g = Color(0xFF157A4B);
const _gd = Color(0xFF0C4D2F);
const _muted = Color(0xFF6B7C73);

class _Sholawat {
  final String id, name, arab, latin, meaning;
  const _Sholawat(this.id, this.name, this.arab, this.latin, this.meaning);
}

const _sholawat = <_Sholawat>[
  _Sholawat('jibril', 'Sholawat Jibril', 'صَلَّى اللهُ عَلَى مُحَمَّد',
    'Shallallahu ‘ala Muhammad.',
    'Semoga Allah melimpahkan rahmat kepada Nabi Muhammad.'),
  _Sholawat('ibrahimiyah', 'Sholawat Ibrahimiyah',
    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ. اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
    'Allahumma shalli ‘ala Muhammad wa ‘ala ali Muhammad, kama shallaita ‘ala Ibrahim wa ‘ala ali Ibrahim, innaka hamidum majid. Allahumma barik ‘ala Muhammad wa ‘ala ali Muhammad, kama barakta ‘ala Ibrahim wa ‘ala ali Ibrahim, innaka hamidum majid.',
    'Ya Allah, limpahkan rahmat dan keberkahan kepada Nabi Muhammad dan keluarganya sebagaimana Engkau limpahkan kepada Nabi Ibrahim dan keluarganya.'),
  _Sholawat('nariyah', 'Sholawat Nariyah',
    'اللَّهُمَّ صَلِّ صَلَاةً كَامِلَةً وَسَلِّمْ سَلَامًا تَامًّا عَلَى سَيِّدِنَا مُحَمَّدٍ الَّذِي تَنْحَلُّ بِهِ الْعُقَدُ وَتَنْفَرِجُ بِهِ الْكُرَبُ وَتُقْضَى بِهِ الْحَوَائِجُ',
    'Allahumma shalli shalatan kamilatan wa sallim salaman tamman ‘ala Sayyidina Muhammadinilladzi tanhallu bihil ‘uqadu wa tanfariju bihil kurabu wa tuqdha bihil hawa-ij.',
    'Ya Allah, limpahkan shalawat dan salam kepada junjungan kami Nabi Muhammad.'),
  _Sholawat('munjiyat', 'Sholawat Munjiyat',
    'اللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ صَلَاةً تُنْجِينَا بِهَا مِنْ جَمِيعِ الْأَهْوَالِ وَالْآفَاتِ',
    'Allahumma shalli ‘ala Sayyidina Muhammadin shalatan tunjina biha min jami‘il ahwali wal afat.',
    'Ya Allah, limpahkan shalawat kepada Nabi Muhammad, shalawat yang dengannya Engkau menyelamatkan kami dari segala ketakutan dan bencana.'),
  _Sholawat('badar', 'Sholawat Badar', 'صَلَاةُ اللهِ سَلَامُ اللهِ عَلَى طٰهَ رَسُوْلِ اللهِ',
    'Shalatullah salamullah ‘ala Thaha Rasulillah.',
    'Semoga rahmat dan keselamatan Allah tercurah kepada Thaha, utusan Allah.'),
  _Sholawat('tibbil', 'Sholawat Tibbil Qulub',
    'اللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ طِبِّ الْقُلُوبِ وَدَوَائِهَا وَعَافِيَةِ الْأَبْدَانِ وَشِفَائِهَا',
    'Allahumma shalli ‘ala Sayyidina Muhammadin thibbil qulub wa dawa-iha wa ‘afiyatil abdani wa syifa-iha.',
    'Ya Allah, limpahkan shalawat kepada Nabi Muhammad, penawar hati serta kesehatan dan kesembuhan badan.'),
  _Sholawat('busyro', 'Sholawat Busyro',
    'يَا رَبِّ صَلِّ عَلَى مُحَمَّدٍ يَا رَبِّ صَلِّ عَلَيْهِ وَسَلِّمْ',
    'Ya Rabbi shalli ‘ala Muhammad, ya Rabbi shalli ‘alaihi wa sallim.',
    'Wahai Tuhanku, limpahkan shalawat dan salam kepada Nabi Muhammad.'),
];

class SholawatPage extends StatelessWidget {
  const SholawatPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [_g, _gd]),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
          SizedBox(height: 10),
          Text('Perbanyak Sholawat', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text('Bacaan Arab, latin, arti, dan penghitung yang tersimpan offline.',
            style: TextStyle(color: Colors.white, height: 1.5)),
        ]),
      ),
      const SizedBox(height: 18),
      const Text('Koleksi Sholawat', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _gd)),
      const SizedBox(height: 10),
      for (final item in _sholawat)
        Card(
          color: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE7EFEA))),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFE7F5EE),
              child: Icon(Icons.spa_rounded, color: _g)),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, color: _gd)),
            subtitle: const Text('Arab • Latin • Arti • Penghitung', style: TextStyle(fontSize: 11, color: _muted)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => _SholawatDetail(item: item))),
          ),
        ),
    ],
  );
}

class _SholawatDetail extends StatefulWidget {
  final _Sholawat item;
  const _SholawatDetail({required this.item});
  @override
  State<_SholawatDetail> createState() => _SholawatDetailState();
}

class _SholawatDetailState extends State<_SholawatDetail> {
  int count = 0, target = 33;
  bool favorite = false, loaded = false;
  String get countKey => 'sholawat_count_${widget.item.id}';
  String get favKey => 'sholawat_fav_${widget.item.id}';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      count = p.getInt(countKey) ?? 0;
      target = p.getInt('sholawat_target_${widget.item.id}') ?? 33;
      favorite = p.getBool(favKey) ?? false;
      loaded = true;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(countKey, count);
    await p.setInt('sholawat_target_${widget.item.id}', target);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7F5),
    appBar: AppBar(title: Text(widget.item.name), actions: [
      IconButton(
        onPressed: () async {
          final p = await SharedPreferences.getInstance();
          setState(() => favorite = !favorite);
          await p.setBool(favKey, favorite);
        },
        icon: Icon(favorite ? Icons.favorite : Icons.favorite_border,
          color: favorite ? Colors.red : _gd),
      ),
    ]),
    body: !loaded ? const Center(child: CircularProgressIndicator()) :
      ListView(padding: const EdgeInsets.all(18), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('BACAAN ARAB', style: TextStyle(color: _g, fontWeight: FontWeight.w800, fontSize: 11)),
            const SizedBox(height: 12),
            Text(widget.item.arab, textAlign: TextAlign.center, textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 26, height: 2, color: _gd)),
            const Divider(height: 28),
            const Text('LATIN', style: TextStyle(color: _g, fontWeight: FontWeight.w800, fontSize: 11)),
            const SizedBox(height: 6),
            Text(widget.item.latin, style: const TextStyle(height: 1.6, fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            const Text('ARTI', style: TextStyle(color: _g, fontWeight: FontWeight.w800, fontSize: 11)),
            const SizedBox(height: 6),
            Text(widget.item.meaning, style: const TextStyle(height: 1.6, color: _muted)),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            const Text('PENGHITUNG BACAAN', style: TextStyle(color: _muted, fontWeight: FontWeight.w800, fontSize: 11)),
            const SizedBox(height: 8),
            Text('$count', style: const TextStyle(fontSize: 58, fontWeight: FontWeight.w800, color: _gd)),
            DropdownButton<int>(
              value: target,
              items: const [33, 100, 1000].map((v) => DropdownMenuItem(value: v, child: Text('Target $v kali'))).toList(),
              onChanged: (v) { if (v != null) setState(() => target = v); _save(); },
            ),
            LinearProgressIndicator(value: (count / target).clamp(0.0, 1.0), color: _g),
            const SizedBox(height: 18),
            SizedBox(width: 145, height: 145, child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _g, shape: const CircleBorder()),
              onPressed: () { setState(() => count++); _save(); },
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.touch_app_rounded, size: 30), SizedBox(height: 5),
                Text('TAP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text('Tambah 1'),
              ]),
            )),
            TextButton.icon(
              onPressed: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
                title: const Text('Reset penghitung?'),
                content: const Text('Jumlah bacaan akan kembali ke nol.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                  FilledButton(onPressed: () { setState(() => count = 0); _save(); Navigator.pop(ctx); },
                    child: const Text('Reset')),
                ],
              )),
              icon: const Icon(Icons.refresh), label: const Text('Reset penghitung'),
            ),
          ]),
        ),
      ]),
  );
}