import 'package:flutter/material.dart';
import '../data/kitab_data.dart';

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
                    '${widget.bab.namaKitab} — ${widget.bab.judulBab}',
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
              itemCount: widget.bab.isi.length,
              itemBuilder: (context, index) {
                final item = widget.bab.isi[index];
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
                            // Teks Arab
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

                            // Bacaan Latin Indonesia
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

                            // Terjemahan Bahasa Indonesia
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

          // Panel Kontrol Bawah (Font Size & Mode Bacaan)
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
                      child: Text(
                        widget.bab.namaKitab,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        if (_arabicFontSize > 16) _arabicFontSize -= 2;
                      }),
                      child: const Text('A-'),
                    ),
                    const SizedBox(width: 8),
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
        label: Center(child: Text(label, style: const TextStyle(fontSize: 12))),
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
