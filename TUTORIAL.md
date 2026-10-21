# Tutorial: jalanin Tayang di laptop lain

Panduan ini buat laptop yang **belum ada apa-apa**. Ikutin berurutan. Bagian 1 sampai 5 udah cukup buat
app-nya jalan di browser. Bagian 6 sama 7 opsional, buat HP Android.

Waktu: sekitar 20–40 menit, kebanyakan nunggu download (Flutter ±2 GB).

---

## 1. Install Git

Git dipakai buat download (clone) kode dari GitHub.

**macOS**: buka Terminal, ketik:

```bash
git --version
```

Kalau belum ada, macOS bakal nawarin install *Command Line Tools*. Klik **Install**.

**Windows**: download dari https://git-scm.com/download/win, jalanin installer-nya, klik **Next** terus
sampai selesai (pengaturan default aman).

Cek berhasil (buka **Terminal** di macOS atau **PowerShell** di Windows):

```bash
git --version
```

Harus keluar nomor versi, misalnya `git version 2.4x.x`.

---

## 2. Install Google Chrome

Paling gampang app ini dijalanin di Chrome. Download di https://www.google.com/chrome/ kalau belum punya.

---

## 3. Install Flutter

Pakai **Flutter versi stable terbaru** (minimal 3.47).

### macOS (pakai Homebrew)

1. Kalau belum punya Homebrew, install dulu dari https://brew.sh. Copy perintah di halaman itu, paste ke Terminal.
2. Install Flutter:

   ```bash
   brew install --cask flutter
   ```

### Windows

1. Buka https://docs.flutter.dev/install/archive, pilih tab **Windows**, download file **Stable** paling atas (`.zip`).
2. Extract ke `C:\src\flutter`. Jangan taruh di `C:\Program Files` karena butuh izin admin.
3. Tambahin Flutter ke PATH:
   - Tekan tombol **Windows**, ketik **env**, pilih **Edit environment variables for your account**.
   - Di bagian *User variables*, pilih **Path**, klik **Edit**, klik **New**, isi `C:\src\flutter\bin`.
   - Klik **OK** di semua jendela.
4. **Tutup terus buka lagi** PowerShell biar PATH-nya kebaca.

### Linux

```bash
sudo snap install flutter --classic
```

### Cek Flutter

```bash
flutter --version
flutter doctor
```

Di hasil `flutter doctor`, yang **wajib centang (✓)** cuma **Flutter** dan **Chrome**. Tanda ✗ di Android,
Xcode, atau Visual Studio boleh dicuekin dulu.

---

## 4. Download kode Tayang

Pindah ke folder tempat kamu mau nyimpen project, misalnya Documents:

```bash
cd ~/Documents
git clone https://github.com/AbdiJ09/tayang.git
cd tayang
```

> Di Windows PowerShell, `cd ~/Documents` juga jalan.

Terus download library yang dipakai app:

```bash
flutter pub get
```

Harus diakhiri tulisan `Got dependencies!`.

---

## 5. Jalanin app-nya 🎬

```bash
flutter run -d chrome
```

Kompilasi pertama sekitar 1–2 menit. Setelah itu Chrome kebuka sendiri dan app **Tayang** langsung muncul.

Pertama kali buka, app nampilin halaman **Masuk**. Pilih **Daftar**, isi nama, email, dan password (minimal
6 karakter), terus **Buat akun**. Akun ini kesimpen di database online, jadi bisa dipakai buat login di HP
atau laptop lain. Butuh koneksi internet.

Biar tampilannya kayak di HP: di Chrome tekan **F12** (Mac: `Cmd + Option + I`), klik ikon HP/tablet di
pojok kiri atas panel, pilih misalnya *iPhone 12 Pro*.

Shortcut di Terminal selama app jalan:

| Tombol | Fungsi |
| --- | --- |
| `r` | reload cepat setelah edit kode |
| `R` | restart penuh |
| `q` | stop app |

**Selesai.** Kalau cuma mau lihat dan coba app-nya, sampai sini udah cukup.

---

## 6. (Opsional) Jalanin di HP Android

Butuh Android SDK. Cara paling gampang lewat Android Studio.

1. Install **Android Studio** dari https://developer.android.com/studio.
2. Buka sekali, ikutin *Setup Wizard* sampai selesai (ini yang download Android SDK).
3. Di Android Studio buka **Settings → Languages & Frameworks → Android SDK → tab SDK Tools**, centang
   **Android SDK Command-line Tools**, klik **Apply**.
4. Setujui lisensi Android:

   ```bash
   flutter doctor --android-licenses
   ```

   Ketik `y` terus Enter di setiap pertanyaan.
5. Di HP: buka **Setelan → Tentang ponsel**, ketuk **Nomor build** 7 kali sampai Mode Developer aktif.
   Terus masuk **Setelan → Opsi developer**, aktifin **USB debugging**.
6. Colok HP ke laptop pakai kabel USB, terus pilih **Izinkan** kalau muncul pertanyaan di HP.
7. Cek HP-nya kedeteksi:

   ```bash
   flutter devices
   ```

8. Jalanin:

   ```bash
   flutter run
   ```

   Kalau device-nya lebih dari satu, Flutter bakal nanya mau pakai yang mana. Pilih nomor HP kamu.

Run pertama ke Android lama (5–10 menit) karena Gradle download banyak file. Berikutnya jauh lebih cepat.

---

## 7. (Opsional) Bikin file APK buat dibagiin

Setelah langkah 6 beres (minimal 1 sampai 4):

```bash
flutter build apk --release
```

File-nya ada di:

```
build/app/outputs/flutter-apk/app-release.apk
```

Kirim lewat WhatsApp atau Google Drive. Di HP penerima, buka file-nya terus izinkan **Instal aplikasi tidak
dikenal** kalau diminta.

---

## Masalah yang sering muncul

| Masalah | Solusi |
| --- | --- |
| `flutter: command not found` / `'flutter' is not recognized` | PATH belum kebaca. Tutup terus buka lagi Terminal/PowerShell. Di Windows, cek lagi langkah 3 bagian PATH. |
| `No supported devices connected` waktu `flutter run -d chrome` | Chrome belum ke-install, atau ada di lokasi lain. Set environment variable `CHROME_EXECUTABLE` ke lokasi `chrome.exe` / Chrome.app. |
| `The current Dart SDK version is ...` / `version solving failed` | Flutter-nya kelamaan. Jalanin `flutter upgrade`, terus `flutter pub get` lagi. |
| Poster nggak muncul, cuma kotak gelap | Poster diambil dari internet. Cek koneksi. |
| Font kelihatan biasa (bukan serif) | Font juga diambil dari internet waktu pertama buka. Pastiin online, terus reload. |
| `Android license status unknown` | Jalanin `flutter doctor --android-licenses`, terus ketik `y` semua. |
| Build Android lama banget / stuck di `Running Gradle task` | Wajar buat build pertama (download Gradle & SDK). Tunggu aja, jangan di-cancel. |
| Muncul tulisan **Supabase belum diatur** | `lib/config.dart` masih kosong. Pastiin udah `git pull` versi terbaru, atau isi sendiri sesuai [supabase/SETUP.md](supabase/SETUP.md). |
| **Data gagal dimuat** / nggak bisa login padahal internet nyala | Project Supabase versi gratis otomatis *pause* kalau 7 hari nggak dipakai. Pemilik project buka dashboard Supabase, terus klik **Restore project**. |
| Habis daftar muncul "buka link konfirmasi di email" | Konfirmasi email masih nyala di Supabase. Buka email-nya terus klik link-nya, atau pemilik project matiin **Confirm email** (lihat [SETUP.md](supabase/SETUP.md) langkah 3). |
| Film baru nggak muncul di HP lain | Tarik layar daftar film ke bawah buat refresh. |

---

## Update ke versi terbaru

Kalau ada update di GitHub:

```bash
cd tayang
git pull
flutter pub get
flutter run -d chrome
```
