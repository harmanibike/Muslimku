class KitabFasal {
  final String nomor;
  final String arab;
  final String latin;
  final String terjemah;
  final String judulBab;
  final String ringkasan;
  final List<String> poinPenting;
  final String catatan;

  const KitabFasal({
    required this.nomor,
    required this.arab,
    required this.latin,
    required this.terjemah,
    this.judulBab = '',
    this.ringkasan = '',
    this.poinPenting = const [],
    this.catatan = '',
  });

  factory KitabFasal.fromJson(Map<String, dynamic> json) {
    final points = json['poinPenting'];
    return KitabFasal(
      nomor: json['nomor']?.toString() ?? '',
      arab: json['arab']?.toString() ?? '',
      latin: json['latin']?.toString() ?? '',
      terjemah: json['terjemah']?.toString() ?? '',
      judulBab: json['judulBab']?.toString() ?? '',
      ringkasan: json['ringkasan']?.toString() ?? '',
      poinPenting: points is List ? points.map((item) => item.toString()).toList(growable: false) : const [],
      catatan: json['catatan']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'nomor': nomor,
        'arab': arab,
        'latin': latin,
        'terjemah': terjemah,
        if (judulBab.isNotEmpty) 'judulBab': judulBab,
        if (ringkasan.isNotEmpty) 'ringkasan': ringkasan,
        if (poinPenting.isNotEmpty) 'poinPenting': poinPenting,
        if (catatan.isNotEmpty) 'catatan': catatan,
      };
}

class KitabBab {
  final String id;
  final String namaKitab;
  final String judulBab;
  final String kategori;
  final List<KitabFasal> isi;

  const KitabBab({
    required this.id,
    required this.namaKitab,
    required this.judulBab,
    required this.kategori,
    required this.isi,
  });

  factory KitabBab.fromJson(Map<String, dynamic> json) {
    final rawIsi = (json['isi'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => KitabFasal.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    final jsonTitle = json['judulBab']?.toString() ?? '';
    final title = jsonTitle.isNotEmpty
        ? jsonTitle
        : (rawIsi.isNotEmpty ? rawIsi.first.judulBab : '');
    return KitabBab(
      id: json['id']?.toString() ?? '${json['namaKitab'] ?? ''}-$title',
      namaKitab: json['namaKitab']?.toString() ?? '',
      judulBab: title,
      kategori: json['kategori']?.toString() ?? 'Lainnya',
      isi: rawIsi,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'namaKitab': namaKitab,
        'judulBab': judulBab,
        'kategori': kategori,
        'isi': isi.map((item) => item.toJson()).toList(),
      };
}
