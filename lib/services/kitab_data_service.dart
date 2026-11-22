import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/kitab_data.dart';

class KitabDataService {
  static const _assetPath = 'assets/data/kitab/kitab.json';
  static const _importedFileName = 'kitab_imported.json';
  static List<KitabBab>? _cache;

  static Future<List<KitabBab>> load() async {
    if (_cache != null) return _cache!;
    final imported = await _importedFile();
    final raw = imported != null
        ? await imported.readAsString()
        : await rootBundle.loadString(_assetPath);
    _cache = _parseBooks(jsonDecode(raw));
    return _cache!;
  }

  static List<KitabBab> _parseBooks(dynamic decoded) {
    final root = Map<String, dynamic>.from(decoded as Map);
    final rawBooks = root['books'];
    if (rawBooks is! List) throw const FormatException('Field books tidak valid.');
    final books = rawBooks
        .whereType<Map>()
        .map((item) => KitabBab.fromJson(Map<String, dynamic>.from(item)))
        .where((book) => book.namaKitab.isNotEmpty && book.isi.isNotEmpty)
        .toList(growable: false);
    if (books.isEmpty) throw const FormatException('Data kitab kosong.');
    return books;
  }

  static Future<File?> _importedFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_importedFileName');
    return file.existsSync() ? file : null;
  }

  static Future<int> importJsonBytes(Uint8List bytes) async {
    final decoded = jsonDecode(utf8.decode(bytes));
    final books = _parseBooks(decoded is Map && decoded['kitab'] is Map
        ? decoded['kitab']
        : decoded);
    final root = decoded is Map && decoded['kitab'] is Map
        ? Map<String, dynamic>.from(decoded['kitab'] as Map)
        : Map<String, dynamic>.from(decoded as Map);
    final dir = await getApplicationDocumentsDirectory();
    final target = File('${dir.path}/$_importedFileName');
    final temp = File('${target.path}.tmp');
    await temp.writeAsString(jsonEncode({
      'format': 'muslimku-kitab',
      'version': root['version'] ?? 1,
      'updatedAt': DateTime.now().toIso8601String(),
      'books': books.map((book) => book.toJson()).toList(),
    }));
    await temp.rename(target.path);
    _cache = books;
    await restoreUserData(decoded);
    return books.length;
  }

  static Future<int> importFromPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return 0;
    final picked = result.files.single;
    final bytes = picked.bytes ??
        (picked.path == null ? null : await File(picked.path!).readAsBytes());
    if (bytes == null) throw const FormatException('File JSON tidak bisa dibaca.');
    return importJsonBytes(bytes);
  }

  static Future<String?> exportBackup({required List<KitabBab> books}) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = (prefs.getStringList('quran_bookmarks') ?? const [])
        .map((item) => jsonDecode(item))
        .toList();
    final backup = {
      'backupFormat': 'muslimku-backup',
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'kitab': {
        'format': 'muslimku-kitab',
        'version': 1,
        'books': books.map((book) => book.toJson()).toList(),
      },
      'quran': {
        'bookmarks': bookmarks,
        'lastRead': _decodeOrNull(prefs.getString('quran_last_read')),
      },
      'settings': {
        'azan_enabled': prefs.getBool('azan_enabled') ?? true,
        for (final name in const ['Subuh', 'Zuhur', 'Asar', 'Magrib', 'Isya'])
          'azan_$name': prefs.getBool('azan_$name') ?? true,
      },
    };
    final bytes = Uint8List.fromList(utf8.encode(JsonEncoder.withIndent('  ').convert(backup)));
    return FilePicker.platform.saveFile(
      dialogTitle: 'Simpan backup Muslimku',
      fileName: 'muslimku-backup-${DateTime.now().millisecondsSinceEpoch}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
  }

  static dynamic _decodeOrNull(String? raw) {
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> restoreUserData(dynamic decoded) async {
    if (decoded is! Map || decoded['backupFormat'] != 'muslimku-backup') return;
    final root = Map<String, dynamic>.from(decoded);
    final quran = root['quran'];
    final settings = root['settings'];
    final prefs = await SharedPreferences.getInstance();
    if (quran is Map) {
      final bookmarkList = (quran['bookmarks'] as List<dynamic>? ?? const [])
          .map((item) => jsonEncode(item))
          .toList();
      await prefs.setStringList('quran_bookmarks', bookmarkList);
      final lastRead = quran['lastRead'];
      if (lastRead is Map) await prefs.setString('quran_last_read', jsonEncode(lastRead));
    }
    if (settings is Map) {
      for (final key in ['azan_enabled', 'azan_Subuh', 'azan_Zuhur', 'azan_Asar', 'azan_Magrib', 'azan_Isya']) {
        if (settings[key] is bool) await prefs.setBool(key, settings[key] as bool);
      }
    }
  }
}
