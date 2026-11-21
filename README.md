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

## Signing APK dan update tanpa uninstall

APK release harus selalu memakai keystore yang sama. Workflow GitHub Actions sekarang membaca empat GitHub Secrets berikut: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, dan `ANDROID_KEY_PASSWORD`. Buat keystore satu kali, ubah ke Base64, lalu simpan nilainya di **Settings → Secrets and variables → Actions → New repository secret**. Jangan commit file `.jks` atau `android/key.properties`.

Contoh pembuatan keystore:

```bash
keytool -genkeypair -v -keystore muslimku-release.jks -alias muslimku \
  -keyalg RSA -keysize 2048 -validity 10000
base64 -w 0 muslimku-release.jks > muslimku-release.jks.base64
```

Setelah empat secret disimpan, jalankan workflow **Build Muslimku APK** kembali. APK yang sudah terpasang dari signing lama mungkin tetap perlu di-uninstall satu kali karena tanda tangan APK lama tidak dapat diganti; setelah APK release baru terpasang, semua update berikutnya dapat dipasang langsung tanpa uninstall.

## Izin Android

Aplikasi meminta izin lokasi saat pengguna membuka jadwal salat atau arah kiblat, serta izin notifikasi dan alarm saat pertama dibuka. Akses internet digunakan untuk mengambil jadwal, daftar surah, ayat, dan audio. Tasbih serta pengaturan azan disimpan di penyimpanan preferensi lokal.

## Sumber data daring

- Jadwal salat: Aladhan API (`api.aladhan.com`), metode MWL.
- Al-Qur'an dan audio: eQuran.id (`equran.id`).

Ketersediaan API dan kontennya bergantung koneksi serta layanan pihak ketiga. Cocokkan jadwal dengan otoritas agama setempat.

## Catatan build

Flutter SDK tidak tersedia di lingkungan penyusunan arsip ini, sehingga proyek belum dapat dikompilasi atau diuji di emulator/perangkat pada sesi ini. Periksa hasil `flutter analyze` dan `flutter build apk --release` sebelum distribusi.
