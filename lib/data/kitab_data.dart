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
        latin: 'Ats-tsalitsu: ghaslul yadaini ma\'al mirfaqaini.',
        terjemah: 'Ketiga: Membasuh kedua tangan sampai ke siku.',
      ),
      KitabFasal(
        nomor: '4',
        arab: 'الرَّابِعُ: مَسْحُ شَيْءٍ مِنَ الرَّأْسِ',
        latin: 'Ar-rabi\'u: mashu syai-in minar ra\'si.',
        terjemah: 'Keempat: Mengusap sebagian kepala.',
      ),
      KitabFasal(
        nomor: '5',
        arab: 'الْخَامِسُ: غَسْلُ الرِّجْلَيْنِ مَعَ الْكَعْبَيْنِ',
        latin: 'Al-khamisu: ghaslur rijlaini ma\'al ka\'baini.',
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
    namaKitab: 'Ta\'limul Muta\'allim',
    judulBab: 'Adab Menuntut Ilmu & Memuliakan Guru',
    kategori: 'Adab & Akhlak',
    isi: [
      KitabFasal(
        nomor: '1',
        arab: 'أَلَا لَا تَنَالُ الْعِلْمَ إِلَّا بِسِتَّةٍ',
        latin: 'Ala la tanalul \'ilma illa bisittatin.',
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
