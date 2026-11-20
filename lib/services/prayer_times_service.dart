import 'dart:convert';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PrayerTimesResult {
  final String regionName;
  final String province;
  final Map<String, String> times;
  final bool fromCache;

  const PrayerTimesResult({
    required this.regionName,
    required this.province,
    required this.times,
    required this.fromCache,
  });
}

class SajadahPrayerTimesService {
  static const String _base = 'https://sajadah.org/api/v1';
  static const String _regionsCacheKey = 'sajadah_regions_cache_v1';

  static Future<PrayerTimesResult> loadForCurrentLocation() async {
    final position = await _getPosition();
    final now = DateTime.now();
    final date = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final regions = await _loadRegions();
    final region = _nearestIndonesianRegion(
      regions,
      position.latitude,
      position.longitude,
      now.year,
    );

    final regionId = region['id'].toString();
    final cacheKey = 'sajadah_times_${regionId}_${now.year}';
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic>? timetable;
    var fromCache = false;
    try {
      final response = await http
          .get(Uri.parse('$_base/times/id/$regionId/${now.year}.json'))
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        throw Exception('Server jadwal mengembalikan ${response.statusCode}.');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> ||
          decoded['days'] is! List ||
          decoded['fields'] is! List) {
        throw Exception('Format data jadwal tidak sesuai.');
      }
      timetable = decoded;
      await prefs.setString(cacheKey, response.body);
    } catch (_) {
      final cached = prefs.getString(cacheKey);
      if (cached == null) {
        rethrow;
      }
      final decoded = jsonDecode(cached);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Data offline rusak. Sambungkan internet lalu coba lagi.');
      }
      timetable = decoded;
      fromCache = true;
    }

    final fields = (timetable['fields'] as List)
        .map((value) => value.toString())
        .toList();
    final dateIndex = fields.indexOf('date');
    if (dateIndex < 0) throw Exception('Kolom tanggal tidak ditemukan.');

    final rows = timetable['days'] as List;
    List<dynamic>? todayRow;
    for (final item in rows) {
      if (item is List &&
          dateIndex < item.length &&
          item[dateIndex].toString() == date) {
        todayRow = item;
        break;
      }
    }
    if (todayRow == null) {
      throw Exception('Jadwal untuk tanggal $date belum tersedia.');
    }

    String fieldValue(String key) {
      final index = fields.indexOf(key);
      if (index < 0 || index >= todayRow!.length) return '--:--';
      return todayRow[index].toString();
    }

    return PrayerTimesResult(
      regionName: (timetable['region']?['name'] ?? region['name'] ?? 'Wilayah terdekat').toString(),
      province: (timetable['region']?['province'] ?? region['province'] ?? '').toString(),
      fromCache: fromCache,
      times: {
        'Imsak': fieldValue('imsak'),
        'Subuh': fieldValue('fajr'),
        'Terbit': fieldValue('sunrise'),
        'Duha': fieldValue('dhuha'),
        'Zuhur': fieldValue('dhuhr'),
        'Asar': fieldValue('asr'),
        'Magrib': fieldValue('maghrib'),
        'Isya': fieldValue('isha'),
      },
    );
  }

  static Future<Position> _getPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('GPS belum aktif. Aktifkan lokasi perangkat lalu coba lagi.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi belum diberikan. Izinkan Muslimku mengakses lokasi.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  static Future<List<dynamic>> _loadRegions() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await http
          .get(Uri.parse('$_base/regions.json'))
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        throw Exception('Daftar wilayah tidak dapat diunduh.');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['regions'] is! List) {
        throw Exception('Format daftar wilayah tidak sesuai.');
      }
      await prefs.setString(_regionsCacheKey, response.body);
      return decoded['regions'] as List<dynamic>;
    } catch (_) {
      final cached = prefs.getString(_regionsCacheKey);
      if (cached == null) {
        throw Exception('Daftar wilayah belum tersimpan. Hubungkan internet untuk penggunaan pertama.');
      }
      final decoded = jsonDecode(cached);
      if (decoded is! Map<String, dynamic> || decoded['regions'] is! List) {
        throw Exception('Cache daftar wilayah rusak. Hubungkan internet lalu coba lagi.');
      }
      return decoded['regions'] as List<dynamic>;
    }
  }

  static Map<String, dynamic> _nearestIndonesianRegion(
    List<dynamic> regions,
    double latitude,
    double longitude,
    int year,
  ) {
    Map<String, dynamic>? nearest;
    var bestDistance = double.infinity;

    for (final item in regions) {
      if (item is! Map) continue;
      if (item['country']?.toString().toUpperCase() != 'ID') continue;
      final years = item['years'];
      if (years is List && !years.any((value) => value.toString() == '$year')) {
        continue;
      }

      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lng = double.tryParse(item['lng']?.toString() ?? '');
      if (lat == null || lng == null) continue;

      final distance = _distanceKm(latitude, longitude, lat, lng);
      if (distance < bestDistance) {
        bestDistance = distance;
        nearest = Map<String, dynamic>.from(item);
      }
    }

    if (nearest == null) {
      throw Exception('Wilayah terdekat tidak ditemukan dalam data jadwal.');
    }
    return nearest;
  }

  static double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = _radians(lat2 - lat1);
    final dLon = _radians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(lat1)) *
            math.cos(_radians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
