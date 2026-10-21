# Tutorial: jalanin Tayang di laptop sendiri

Panduan ini buat laptop yang **belum ada apa-apa**, sampai app **Tayang** jalan di Chrome dan nyambung ke
database **Supabase milikmu sendiri**. Ikutin langkahnya berurutan.

| | Langkah | Waktu |
| --- | --- | --- |
| 1–4 | Install Git, Chrome, Flutter, terus download kode | 15–30 menit (download Flutter ±2 GB) |
| 5–6 | Bikin database Supabase pakai akunmu, terus sambungin ke app | ±10 menit |
| 7–9 | Jalanin app, daftar akun, jadiin akunmu admin, cek semua fitur | ±5 menit |
| 10–11 | *(Opsional)* Jalanin di HP Android & bikin APK | 15–30 menit |

**Yang dibutuhin:** laptop (macOS / Windows / Linux), koneksi internet, dan akun GitHub atau email buat
daftar Supabase (gratis).

> **Cuma mau nyoba pakai database yang udah ada (punya pemilik repo)?** Lewati langkah 5 & 6, terus di
> langkah 7 jalanin `flutter run -d chrome` aja, tanpa `--dart-define-from-file`.

---

## 1. Install Git

Git dipakai buat download (clone) kode dari GitHub.

**macOS**: buka **Terminal** (Cmd + Spasi, ketik "Terminal"), terus ketik:

```bash
git --version
```

Kalau belum ada, macOS bakal nawarin install *Command Line Tools*. Klik **Install** terus tunggu selesai.

**Windows**: download dari https://git-scm.com/download/win, jalanin installer-nya, klik **Next** terus
sampai selesai (pengaturan default aman).

Cek berhasil (buka **Terminal** di macOS atau **PowerShell** di Windows):

```bash
git --version
```

Harus keluar nomor versi, misalnya `git version 2.4x.x`.

---

## 2. Install Google Chrome

App ini paling gampang dijalanin di Chrome. Download di https://www.google.com/chrome/ kalau belum punya.

---

## 3. Install Flutter

Wajib **Flutter versi stable terbaru (minimal 3.47)**. Versi lama bakal error waktu `flutter pub get`.

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
```

Pastiin versinya **3.47 atau lebih baru**. Kalau udah pernah install Flutter dari dulu, update dulu:

```bash
flutter upgrade
```

Terus:

```bash
flutter doctor
```

Yang **wajib centang (✓)** cuma **Flutter** dan **Chrome**. Tanda ✗ di Android, Xcode, atau Visual Studio
boleh dicuekin dulu.

---

## 4. Download kode Tayang

Pindah ke folder tempat kamu mau nyimpen project, misalnya Documents:

```bash
cd ~/Documents
git clone https://github.com/AbdiJ09/tayang.git
cd tayang
```

Download library yang dipakai app:

```bash
flutter pub get
```

Harus diakhiri tulisan `Got dependencies!`.

> Mulai dari sini, **semua perintah dijalanin dari dalam folder `tayang`**.

---

## 5. Bikin database Supabase pakai akunmu

Supabase itu database online (PostgreSQL) plus fitur login. Di sinilah akun, film, dan favorit disimpan.

### 5.1 Bikin akun & project

1. Buka https://supabase.com, klik **Start your project**, terus daftar atau login (paling gampang pakai
   **Continue with GitHub**).
2. Kalau diminta bikin *organization*, isi nama bebas (misalnya nama kamu), pilih plan **Free**.
3. Klik **New project** terus isi:
   - **Project name**: `tayang`
   - **Database Password**: klik **Generate a password**, terus **simpan** di tempat aman (Notes / password
     manager). Password ini nggak dipakai di app, tapi kadang dibutuhin buat urusan database.
   - **Region**: **Southeast Asia (Singapore)**, yang paling dekat dari Jakarta
   - Kalau ada pilihan **Enable Data API**, biarin **nyala**
4. Klik **Create new project**, terus tunggu ±1–2 menit sampai dashboard-nya siap.

### 5.2 Bikin tabel

1. Di menu kiri, klik ikon **SQL Editor**, terus klik **+ New** / **New query**.
2. Di project `tayang` (yang di-clone di langkah 4), buka file **`supabase/schema.sql`** pakai editor apa pun
   (VS Code, Notepad, TextEdit). Pilih semua (**Cmd/Ctrl + A**), terus copy.
3. Paste ke SQL Editor Supabase, terus klik **Run** (atau **Cmd/Ctrl + Enter**).
   - Kalau muncul peringatan *"Potential issue detected… destructive operation"*, klik **Run this query**.
     Peringatan itu muncul karena ada perintah `revoke` (mengunci hak akses), bukan karena ada data yang dihapus.
4. Harusnya muncul **`Success. No rows returned`**.
5. Cek di menu **Table Editor**: harus ada tabel **`users`**, **`movies`** (isinya 7 film), dan **`bookmarks`**.

> ⚠️ Yang dijalanin cuma `schema.sql`. File `upgrade_roles.sql` **jangan** dijalanin, karena itu khusus
> buat project lama yang dibikin sebelum ada role.
>
> Kalau muncul error `relation "users" already exists`, berarti SQL-nya udah pernah dijalanin. Lanjut aja.

### 5.3 Atur login email

Defaultnya Supabase ngirim email konfirmasi setiap ada yang daftar, dan versi gratis cuma bisa ngirim
beberapa email per jam. Biar daftar akun langsung bisa dipakai:

1. Menu kiri, buka **Authentication → Sign In / Providers**.
2. Di kotak **User Signups** paling atas:
   - **Allow new users to sign up**: **nyala**
   - **Confirm email**: **mati**
3. Klik **Save changes**.
4. Masih di halaman itu, di bagian **Auth Providers**, pastiin **Email** statusnya **Enabled**. Kalau belum,
   klik **Email**, nyalain **Enable email provider**, terus **Save**.

### 5.4 Ambil URL & key

1. Klik tombol hijau **Connect** di bagian atas dashboard.
2. Di situ ada contoh kode. Pilihan **Framework** boleh dibiarin apa aja (misalnya Next.js), soalnya yang
   kita butuhin cuma **nilainya**, dan nilainya sama buat semua framework. Cari dua baris kayak gini:

   ```
   ..._SUPABASE_URL=https://abcdefghijklmnop.supabase.co
   ..._SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxxxxxxxxxx
   ```

   Arahin mouse ke kotak kodenya, terus klik ikon **copy** di pojok kanan atas.

   *Cara lain: **Project Settings → API Keys**. URL-nya ada di **Project Settings → Data API**.*

> 🔐 Yang dipakai **cuma publishable key** (`sb_publishable_...`, atau di project lama: *anon key*). Key ini
> emang dibuat buat ditaruh di app. **Jangan pernah** pakai *secret key* / `service_role`, dan jangan kirim
> itu ke siapa pun.

---

## 6. Sambungin app ke Supabase-mu

Kamu nggak perlu ngubah kode. Cukup bikin satu file config pribadi bernama **`supabase.json`**.

1. Copy file contohnya. Dari dalam folder `tayang`:

   macOS / Linux:

   ```bash
   cp supabase.example.json supabase.json
   ```

   Windows (PowerShell):

   ```powershell
   Copy-Item supabase.example.json supabase.json
   ```

2. Buka `supabase.json`, terus ganti isinya pakai nilai dari langkah 5.4:

   ```json
   {
     "SUPABASE_URL": "https://abcdefghijklmnop.supabase.co",
     "SUPABASE_KEY": "sb_publishable_xxxxxxxxxxxx"
   }
   ```

   - URL diawali `https://` dan diakhiri `.supabase.co`, **tanpa** garis miring di akhir.
   - Tanda kutip `"` dan koma `,` jangan sampai kehapus.

3. Simpan.

`supabase.json` udah masuk `.gitignore`, jadi nggak bakal ikut ke-push ke GitHub.

---

## 7. Jalanin app-nya 🎬

```bash
flutter run -d chrome --dart-define-from-file=supabase.json
```

Kompilasi pertama sekitar 1–2 menit. Setelah itu Chrome kebuka sendiri dan app **Tayang** muncul di
halaman **Masuk**.

> ⚠️ Bagian `--dart-define-from-file=supabase.json` **wajib ikut setiap kali run**. Kalau lupa, app bakal
> nyambung ke database pemilik repo, bukan punyamu.

Biar tampilannya kayak di HP: di Chrome tekan **F12** (Mac: **Cmd + Option + I**), klik ikon HP/tablet di
pojok kiri atas panel, terus pilih misalnya *iPhone 12 Pro*.

Shortcut di Terminal selama app jalan:

| Tombol | Fungsi |
| --- | --- |
| `r` | reload cepat setelah edit kode |
| `R` | restart penuh |
| `q` | stop app |

---

## 8. Daftar akun & jadiin akunmu admin

Ada dua role:

| Role | Bisa apa |
| --- | --- |
| **user** (default) | lihat film, cari, filter lokasi, simpan favorit |
| **admin** | semua yang di atas, plus **tambah, edit, hapus film** |

1. Di app, klik **DAFTAR**, isi **nama**, **email**, **password** (minimal 6 karakter), terus **BUAT AKUN**.
   Kamu langsung masuk ke daftar film sebagai **user**.
2. Balik ke dashboard Supabase, buka **SQL Editor → New query**, terus jalanin (ganti emailnya pakai email
   yang barusan kamu daftarin):

   ```sql
   update public.users set role = 'admin' where email = 'email-kamu@contoh.com';

   select name, email, role from public.users;
   ```

   Hasilnya harus nunjukin akunmu dengan role **`admin`**.

   *Cara lain: **Table Editor → users**, klik dua kali sel `role` di akunmu, ganti jadi `admin`, tekan
   Enter, terus **Save**.*
3. Balik ke app, **tarik daftar film ke bawah** buat refresh (atau klik **KELUAR** di bagian bawah, terus
   masuk lagi).

Role cuma bisa diubah dari dashboard Supabase. Dari dalam app nggak bisa, ini disengaja biar user biasa
nggak bisa jadiin dirinya admin.

---

## 9. Cek semua jalan ✅

| Cek | Hasil yang benar |
| --- | --- |
| Daftar film | Ada 7 film lengkap dengan poster |
| Search | Ketik "spider", cuma *Spider-Man: Brand New Day* yang muncul |
| Filter lokasi | Pilih **JAKARTA SELATAN**, muncul nama bioskop + jam tayang |
| Favorit | Klik ikon penanda di satu film, terus klik **FAVORIT · 1** di pojok kanan atas. Filmnya ada di situ |
| Akun admin | Bagian bawah beranda nulis **MASUK SEBAGAI … · ADMIN**, dan tombol **+ TAMBAH** muncul di pojok atas |
| Tambah film | **+ TAMBAH**, isi judul, pilih bioskop, isi jam, terus **SIMPAN FILM**. Film muncul paling atas |
| Edit / hapus | Buka film, scroll ke paling bawah, terus pakai **Edit film** / **Hapus film** |
| Database | Di Supabase **Table Editor → movies** / **bookmarks**, datanya ikut berubah |

Kalau semua cocok, **selesai**. App udah jalan di laptopmu pakai database sendiri. 🎉

Mau ngetes sebagai user biasa? Klik **KELUAR**, daftar pakai email lain. Akun itu nggak bakal punya tombol
tambah, edit, atau hapus.

---

## 10. (Opsional) Jalanin di HP Android

Butuh Android SDK. Cara paling gampang lewat Android Studio.

1. Install **Android Studio** dari https://developer.android.com/studio.
2. Buka sekali, ikutin *Setup Wizard* sampai selesai (ini yang download Android SDK).
3. Di Android Studio buka **Settings → Languages & Frameworks → Android SDK → tab SDK Tools**, centang
   **Android SDK Command-line Tools**, terus klik **Apply**.
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

8. Jalanin (ingat, pakai `supabase.json` juga):

   ```bash
   flutter run --dart-define-from-file=supabase.json
   ```

   Kalau device-nya lebih dari satu, Flutter bakal nanya mau pakai yang mana. Pilih nomor HP kamu.

Run pertama ke Android lama (5–10 menit) karena Gradle download banyak file. Berikutnya jauh lebih cepat.

---

## 11. (Opsional) Bikin file APK buat dibagiin

Setelah langkah 10 nomor 1–4 beres:

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=supabase.json
```

Pakai file ini (cocok buat hampir semua HP Android sekarang):

```
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

URL dan key Supabase-mu udah ketanam di dalam APK, jadi siapa pun yang install bakal nyambung ke database
kamu. Kirim lewat WhatsApp atau Google Drive. Di HP penerima, **download dulu** file-nya, terus buka dari
**File Manager** dan izinkan **Instal aplikasi tidak dikenal** kalau diminta.

---

## Masalah yang sering muncul

| Masalah | Solusi |
| --- | --- |
| `flutter: command not found` / `'flutter' is not recognized` | PATH belum kebaca. Tutup terus buka lagi Terminal/PowerShell. Di Windows, cek lagi langkah 3 bagian PATH. |
| `The current Dart SDK version is ...` / `version solving failed` / `Try using the Flutter SDK version: 3.47.x` | Flutter-nya kelamaan. Jalanin `flutter upgrade`, terus `flutter pub get` lagi. |
| `No supported devices connected` waktu `flutter run -d chrome` | Chrome belum ke-install, atau ada di lokasi lain. Set environment variable `CHROME_EXECUTABLE` ke lokasi `chrome.exe` / Chrome.app. |
| Error yang nyebut `supabase.json` waktu `flutter run` | File `supabase.json` nggak ada atau formatnya salah. Ulangi langkah 6, terus cek tanda kutip dan koma. Jalanin perintahnya dari dalam folder `tayang`. |
| App nyambung ke database yang salah (film/akunmu nggak ada) | Lupa `--dart-define-from-file=supabase.json` waktu run. Stop app (`q`), terus jalanin lagi perintah di langkah 7. |
| Waktu daftar muncul **"Email logins are disabled"** atau **"Signups not allowed"** | Ulangi langkah 5.3: Email provider **Enabled**, **Allow new users to sign up** nyala. |
| Habis daftar muncul **"buka link konfirmasi di email"** | **Confirm email** masih nyala (langkah 5.3). Matiin, terus daftar ulang pakai email lain, atau buka email-nya dan klik link konfirmasinya. |
| **Data gagal dimuat** + tulisan `Could not find the table 'public.users'` / `relation ... does not exist` | `schema.sql` belum dijalanin di project ini. Ulangi langkah 5.2. |
| **Data gagal dimuat** padahal sebelumnya jalan | Project Supabase gratis otomatis *pause* kalau 7 hari nggak dipakai. Buka dashboard Supabase, terus klik **Restore project**. |
| Tombol **+ TAMBAH** nggak muncul padahal udah diubah jadi admin | Tarik daftar film ke bawah buat refresh, atau **KELUAR** terus masuk lagi. Cek juga email di query langkah 8 udah persis sama. |
| **"Hanya admin yang boleh mengubah data film"** | Akun yang dipakai masih role `user`. Lihat langkah 8. |
| Poster nggak muncul, cuma kotak gelap | Poster diambil dari internet. Cek koneksi. |
| Font kelihatan biasa (bukan serif) | Font juga diambil dari internet waktu pertama buka. Pastiin online, terus reload. |
| `Android license status unknown` | Jalanin `flutter doctor --android-licenses`, terus ketik `y` semua. |
| Build Android lama banget / stuck di `Running Gradle task` | Wajar buat build pertama (download Gradle & SDK). Tunggu aja, jangan di-cancel. |

---

## Update ke versi terbaru

Kalau ada update di GitHub:

```bash
cd tayang
git pull
flutter pub get
flutter run -d chrome --dart-define-from-file=supabase.json
```

`supabase.json` milikmu nggak bakal ketimpa waktu `git pull`.
