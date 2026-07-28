# 💰 KasKita — Aplikasi Manajemen Kas Kelas

Aplikasi mobile untuk mengelola kas kelas **04SISP007** secara transparan: pencatatan pembayaran siswa, pengeluaran, laporan keuangan, hingga pengingat otomatis via notifikasi dan WhatsApp — lengkap dengan sinkronisasi cloud.

Dibangun dengan **Flutter 3.x** + **Firebase** (Auth, Firestore).

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)

---

## 📱 Fitur Utama

### 🔐 Autentikasi & Keamanan
- **Login Email/Password** dan **Login Google (Google Sign-In)** via Firebase Authentication
- Auto sign-up: jika akun belum terdaftar saat login email, sistem otomatis membuatkan akun baru
- **Kunci PIN 4-digit** setelah login, dengan alur pendaftaran PIN + konfirmasi ulang
- PIN tersinkron ke Firestore per akun, sehingga tetap berlaku walau ganti perangkat
- Splash screen dengan animasi (scale + fade) yang mengarahkan ke Login atau Lock Screen sesuai status sesi

### 🏠 Dashboard
- Ringkasan saldo kas, total pemasukan, dan total pengeluaran real-time
- Kartu statistik jumlah siswa **sudah bayar** vs **belum bayar** bulan berjalan
- Pencarian cepat siswa dari halaman beranda
- Feed aktivitas transaksi terbaru (pemasukan & pengeluaran)
- Tombol **broadcast tagihan mingguan**: menampilkan daftar siswa yang belum bayar minggu ini, lengkap tombol kirim WhatsApp langsung per siswa
- Toggle **Dark Mode / Light Mode** dari app bar

### 👥 Manajemen Data Siswa
- CRUD lengkap: tambah, edit, hapus data siswa (Nama, NIS, Kelas, No. HP opsional)
- Pencarian siswa berdasarkan nama/NIS
- Indikator status bayar bulan ini per siswa

### 💵 Pembayaran (Kas Masuk)
- Catat pembayaran siswa per bulan, dengan nominal, tanggal, dan keterangan
- Filter riwayat berdasarkan bulan, dan pencarian berdasarkan nama siswa
- Sortir: tanggal terbaru/terlama, nama A-Z, atau nominal terbesar
- Menampilkan **QR Code QRIS/DANA** di form pembayaran untuk mempermudah transfer
- Kirim pengingat tagihan otomatis ke siswa via **WhatsApp** (format bulanan maupun mingguan)
- Edit & hapus transaksi pembayaran

### 🛒 Pengeluaran (Kas Keluar)
- Catat pengeluaran dengan kategori: Alat Tulis, Konsumsi, Dekorasi, Kegiatan, Lainnya
- **Scan struk otomatis (OCR)** — foto struk belanja lewat kamera, lalu aplikasi mendeteksi nominal total secara otomatis menggunakan Google ML Kit Text Recognition
- Edit & hapus data pengeluaran

### 📊 Laporan Keuangan
- Ringkasan total pemasukan, pengeluaran, dan saldo akhir
- Breakdown pembayaran per siswa (riwayat lengkap tiap siswa)
- Breakdown pengeluaran per kategori
- Riwayat transaksi bulan berjalan
- **Export laporan ke file Excel (.xlsx)** — 2 sheet otomatis: rekap kas per bulan & data kas bulan berjalan (lengkap dengan pewarnaan status bayar), langsung dibagikan lewat menu share bawaan HP

### 🔔 Notifikasi
- Notifikasi lokal setiap ada transaksi baru (pemasukan/pengeluaran)
- Pengingat otomatis terjadwal **setiap hari Selasa jam 08:00** untuk menagih kas mingguan

### ⚙️ Pengaturan
- Ganti bahasa antarmuka: **Indonesia / English**
- Aktif/nonaktifkan notifikasi aplikasi
- **Backup** data kas ke cloud & **Restore** dari cloud secara manual
- Tes suara notifikasi kustom
- Dialog "Tentang Aplikasi" (versi, kode kelas)
- Logout akun

### 💾 Penyimpanan Data
- Data utama disimpan **lokal** di perangkat via `SharedPreferences` agar tetap bisa dipakai offline
- Setiap perubahan data otomatis di-*push* ke **Cloud Firestore** (koleksi `users_data/{uid}`) sebagai backup & sinkronisasi lintas perangkat
- Data seed/demo otomatis terisi saat akun baru pertama kali dibuat

---

## 🧱 Tech Stack

| Kategori | Package |
|---|---|
| State Management | `provider` |
| Backend / Auth | `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in` |
| Penyimpanan Lokal | `shared_preferences` |
| Format Tanggal & Mata Uang | `intl` |
| ID Generator | `uuid` |
| Notifikasi | `flutter_local_notifications`, `timezone` |
| OCR Scan Struk | `image_picker`, `google_mlkit_text_recognition` |
| Export Laporan | `excel`, `path_provider`, `share_plus` |
| QR Code | `qr_flutter` |
| UI Tambahan | `curved_navigation_bar`, `font_awesome_flutter`, `flutter_spinkit` |
| Integrasi Eksternal | `url_launcher` (deep link WhatsApp) |

---

## 📁 Struktur Proyek

```
lib/
├── main.dart                     # Entry point, inisialisasi Firebase & navigasi utama
├── firebase_options.dart         # Konfigurasi Firebase (auto-generate via flutterfire configure)
├── models/
│   ├── siswa.dart                 # Model data siswa
│   ├── pembayaran.dart            # Model data pembayaran
│   └── pengeluaran.dart           # Model data pengeluaran + kategori
├── providers/
│   └── app_provider.dart          # State management, CRUD, sinkronisasi cloud, tema, PIN
├── screens/
│   ├── splash_screen.dart         # Splash + pengecekan sesi login
│   ├── login_screen.dart          # Login Email/Google
│   ├── lock_screen.dart           # Kunci PIN
│   ├── dashboard_screen.dart      # Beranda
│   ├── data_siswa_screen.dart     # Manajemen siswa
│   ├── pembayaran_screen.dart     # Pencatatan kas masuk
│   ├── pengeluaran_screen.dart    # Pencatatan kas keluar
│   ├── laporan_screen.dart        # Laporan & export
│   └── settings_screen.dart       # Pengaturan aplikasi
└── utils/
    ├── app_theme.dart             # Tema light/dark
    ├── formatter.dart              # Formatter Rupiah & tanggal
    ├── notification_helper.dart    # Notifikasi lokal & terjadwal
    ├── export_helper.dart          # Generator file Excel
    ├── ocr_helper.dart             # Scan struk (kamera + ML Kit)
    └── whatsapp_helper.dart        # Deep link pengingat WhatsApp
```

---

## 🚀 Cara Menjalankan

### Prasyarat
- Flutter SDK (channel stable, Dart `>=3.0.0 <4.0.0`)
- Akun Firebase + Firebase CLI (`npm install -g firebase-tools`) dan [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup)

### 1. Clone & install dependencies
```bash
git clone <url-repo-ini>
cd kaskita_flutter
flutter pub get
```

### 2. Setup Firebase (wajib)
Project ini butuh Firebase project sendiri untuk Authentication & Firestore. **Jangan gunakan `firebase_options.dart` bawaan repo** — generate ulang untuk project Firebase kamu sendiri:
```bash
firebase login
flutterfire configure
```
Lalu aktifkan di Firebase Console:
- **Authentication** → Sign-in method: Email/Password & Google
- **Firestore Database** → buat database, lalu atur Security Rules agar setiap user hanya bisa mengakses dokumennya sendiri, contoh:
  ```
  match /users_data/{userId} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }
  ```

### 3. Jalankan aplikasi
```bash
flutter run
```

### 4. Build APK
```bash
flutter build apk --release
```
APK tersimpan di `build/app/outputs/flutter-apk/app-release.apk`

---

## ⚠️ Catatan & Known Issues

Beberapa hal yang sebaiknya dibereskan sebelum repo ini benar-benar dipublikasikan:

- **Data siswa asli ter-hardcode di `app_provider.dart` (`_seedData()`)** — nama lengkap, NIS, dan nomor HP teman sekelas tertulis langsung di source code. Kalau repo ini publik, data pribadi orang lain ikut ter-ekspos. Sebaiknya ganti dengan data dummy/anonim, atau pindahkan seed data ke file terpisah yang di-`.gitignore`.
- **Link QRIS/DANA pribadi ter-hardcode** di `pembayaran_screen.dart` (`qrDataString`). Ini link *request uang* ke akun DANA milik pemegang aplikasi — sebaiknya dibuat configurable (misal disimpan di Firestore/Settings) alih-alih ditanam langsung di kode.
- **PIN disimpan dalam bentuk plain text** di SharedPreferences & Firestore, tanpa hashing. Idealnya PIN di-hash (misalnya pakai `crypto` package) sebelum disimpan, apalagi karena sudah tersinkron ke cloud.
- **Dependency yang di-declare tapi tidak dipakai di kode:** `fl_chart`, `pdf`, `printing`, `local_auth`, `google_fonts`, `flutter_slidable`, `gap`. Kemungkinan sisa fitur yang direncanakan (misal grafik statistik, export PDF, login biometrik) tapi belum diimplementasikan — sebaiknya dihapus dari `pubspec.yaml` kalau memang tidak dipakai, supaya ukuran build tidak membengkak percuma.
- **Icon tombol export di halaman Laporan pakai ikon PDF (`picture_as_pdf`)**, padahal fungsinya generate file **Excel (.xlsx)**. Cukup membingungkan dari sisi UX — ganti ikonnya atau baru implementasikan export PDF sungguhan (dependency `pdf` & `printing` sudah tersedia tapi belum dipakai).
- **`applicationId` masih default `com.example.kaskita`** di `android/app/build.gradle` — perlu diganti ke package name sendiri sebelum rilis ke Play Store.
- **iOS belum tersedia** — folder `ios/` belum di-generate dalam project ini, dan beberapa plugin (kamera/OCR, notifikasi terjadwal) butuh konfigurasi native tambahan kalau ingin mendukung iOS.
- **Belum ada automated test** — folder `test/` masih kosong.

---
