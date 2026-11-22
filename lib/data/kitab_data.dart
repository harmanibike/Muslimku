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

  factory KitabFasal.fromJson(Map<String, dynamic> json) => KitabFasal(
        nomor: json['nomor']?.toString() ?? '',
        arab: json['arab']?.toString() ?? '',
        latin: json['latin']?.toString() ?? '',
        terjemah: json['terjemah']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'nomor': nomor,
        'arab': arab,
        'latin': latin,
        'terjemah': terjemah,
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

  factory KitabBab.fromJson(Map<String, dynamic> json) => KitabBab(
        id: json['id']?.toString() ??
            '${json['namaKitab'] ?? ''}-${json['judulBab'] ?? ''}',
        namaKitab: json['namaKitab']?.toString() ?? '',
        judulBab: json['judulBab']?.toString() ?? '',
        kategori: json['kategori']?.toString() ?? 'Lainnya',
        isi: (json['isi'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => KitabFasal.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'namaKitab': namaKitab,
        'judulBab': judulBab,
        'kategori': kategori,
        'isi': isi.map((item) => item.toJson()).toList(),
      };
}
