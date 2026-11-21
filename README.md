# Muslimku 1.2.0 — proyek sumber Flutter

Proyek ini melanjutkan desain Muslimku putih-hijau yang dikirim pengguna. Proyek berisi kode sumber Flutter dan konfigurasi Android dasar.

## Fitur yang sudah diimplementasikan

- Jadwal salat harian dari API Aladhan berdasarkan koordinat perangkat (izin lokasi diperlukan; metode MWL dipakai sebagai nilai awal).
- Daftar 114 surah, detail ayat Arab, latin, terjemahan Indonesia, serta pemutar audio qari melalui API eQuran.id.
- Perhitungan arah kiblat dari koordinat perangkat dan tampilan kompas (memerlukan sensor kompas; akurasi bergantung perangkat/kalibrasi).
- Tasbih digital dengan pilihan zikir, target, reset, dan penyimpanan hitungan lokal.
- Doa harian ringkas dan hadis pilihan.
- Kalkulator estimasi zakat mal 2,5% (bukan penetapan hukum zakat).

## Notifikasi dan suara azan

Notifikasi azan terjadwal menggunakan waktu salat dari lokasi perangkat dan suara offline di `android/app/src/main/res/raw/`. Aplikasi meminta izin notifikasi serta exact alarm saat pertama dibuka, lalu mendaftarkan jadwal harian setelah jadwal salat berhasil dimuat. Pengaturan per waktu salat dan tombol uji suara tersedia di menu **Pengingat salat**.

Pada sebagian perangkat, optimasi baterai atau mode senyap dapat menunda atau mematikan alarm. Izinkan Muslimku berjalan tanpa pembatasan baterai dan pastikan volume alarm/notifikasi perangkat aktif. Jika lokasi berubah, buka halaman **Waktu Salat** dan lakukan refresh agar jadwal diperbarui.

Kalender Hijriah dan unduhan konten offline belum disertakan.

## Menjalankan proyek

1. Pasang Flutter SDK versi stabil dan Android Studio.
2. Buka folder proyek ini.
3. Jalankan `flutter doctor`.
4. Jalankan `flutter pub get`.
5. Jalankan `flutter run` pada perangkat Android.
6. Untuk APK: `flutter build apk --release`.

Jika proyek dibuka di komputer baru, Android Studio/Flutter akan membuat `android/local.properties` sesuai lokasi Flutter SDK. File ini tidak disertakan karena bersifat lokal.

## Izin Android

Aplikasi meminta izin lokasi saat pengguna membuka jadwal salat atau arah kiblat, serta izin notifikasi dan alarm saat pertama dibuka. Akses internet digunakan untuk mengambil jadwal, daftar surah, ayat, dan audio. Tasbih serta pengaturan azan disimpan di penyimpanan preferensi lokal.

## Sumber data daring

- Jadwal salat: Aladhan API (`api.aladhan.com`), metode MWL.
- Al-Qur'an dan audio: eQuran.id (`equran.id`).

Ketersediaan API dan kontennya bergantung koneksi serta layanan pihak ketiga. Cocokkan jadwal dengan otoritas agama setempat.

## Catatan build

Flutter SDK tidak tersedia di lingkungan penyusunan arsip ini, sehingga proyek belum dapat dikompilasi atau diuji di emulator/perangkat pada sesi ini. Periksa hasil `flutter analyze` dan `flutter build apk --release` sebelum distribusi.
