import 'dart:convert';
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

class AladhanPrayerTimesService {
  static Future<PrayerTimesResult> loadForCurrentLocation() async {
    final position = await _getPosition();
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-' '${now.year.toString().padLeft(4, '0')}';

    final lat = position.latitude;
    final lng = position.longitude;
    final cacheKey = 'aladhan_times_$dateStr';
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic>? data;
    var fromCache = false;

    try {
      final uri = Uri.parse(
        'https://api.aladhan.com/v1/timings/$dateStr'
        '?latitude=$lat&longitude=$lng&method=20',
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Server jadwal mengembalikan HTTP ${response.statusCode}.');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['data'] is! Map) {
        throw Exception('Format data jadwal tidak sesuai.');
      }
      data = Map<String, dynamic>.from(decoded['data'] as Map);
      await prefs.setString(cacheKey, jsonEncode(data));
    } catch (e) {
      final cached = prefs.getString(cacheKey);
      if (cached == null) throw Exception('Gagal memuat jadwal salat: $e');
      final decoded = jsonDecode(cached);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Data offline rusak. Sambungkan internet lalu coba lagi.');
      }
      data = decoded;
      fromCache = true;
    }

    final timings = data['timings'] as Map<String, dynamic>? ?? {};
    final meta = data['meta'] as Map<String, dynamic>? ?? {};
    final timezone = (meta['timezone'] ?? 'Asia/Jakarta').toString();
    final place = await _getCityAndProvince(lat, lng, prefs, timezone);

    String clean(String key) => (timings[key]?.toString() ?? '--:--').split(' ').first;
    final sunrise = clean('Sunrise');

    return PrayerTimesResult(
      regionName: place.$1,
      province: place.$2,
      fromCache: fromCache,
      times: {
        'Imsak': clean('Imsak'),
        'Subuh': clean('Fajr'),
        'Terbit': sunrise,
        'Duha': _addMinutes(sunrise, 20),
        'Zuhur': clean('Dhuhr'),
        'Asar': clean('Asr'),
        'Magrib': clean('Maghrib'),
        'Isya': clean('Isha'),
      },
    );
  }

  static Future<(String, String)> _getCityAndProvince(
    double lat,
    double lng,
    SharedPreferences prefs,
    String timezone,
  ) async {
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client'
        '?latitude=$lat&longitude=$lng&localityLanguage=id',
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final city = (decoded['city']?.toString().trim().isNotEmpty == true)
              ? decoded['city'].toString().trim()
              : (decoded['locality']?.toString().trim().isNotEmpty == true)
                  ? decoded['locality'].toString().trim()
                  : 'Lokasi GPS Terdeteksi';
          final province =
              (decoded['principalSubdivision']?.toString().trim().isNotEmpty == true)
                  ? decoded['principalSubdivision'].toString().trim()
                  : timezone;

          await prefs.setString('last_city', city);
          await prefs.setString('last_province', province);
          return (city, province);
        }
      }
    } catch (_) {}

    final savedCity = prefs.getString('last_city');
    final savedProvince = prefs.getString('last_province');
    if (savedCity != null && savedCity.isNotEmpty) {
      return (savedCity, savedProvince ?? timezone);
    }
    return ('Lokasi GPS Terdeteksi', '${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)} •$timezone');
  }

  static String _addMinutes(String hhmm, int minutesToAdd) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return '--:--';
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return '--:--';
    final total = (h * 60 + m + minutesToAdd) % (24 * 60);
    return '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
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

    final prefs = await SharedPreferences.getInstance();
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      await prefs.setDouble('last_lat', lastKnown.latitude);
      await prefs.setDouble('last_lng', lastKnown.longitude);
      return lastKnown;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 12),
        ),
      );
      await prefs.setDouble('last_lat', pos.latitude);
      await prefs.setDouble('last_lng', pos.longitude);
      return pos;
    } catch (_) {
      final savedLat = prefs.getDouble('last_lat');
      final savedLng = prefs.getDouble('last_lng');
      if (savedLat != null && savedLng != null) {
        return Position(
          latitude: savedLat,
          longitude: savedLng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
      throw Exception('Sinyal GPS sulit didapat. Buka Google Maps sebentar lalu tekan refresh.');
    }
  }
}
