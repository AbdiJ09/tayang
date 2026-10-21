# Setup database Supabase

Cukup dilakukan **sekali** oleh pemilik project. Setelah `lib/config.dart` terisi dan di-push, semua orang
yang clone repo ini otomatis pakai database yang sama. Mereka nggak perlu bikin Supabase sendiri.

## 1. Bikin project

1. Buka https://supabase.com, klik **Start your project**, terus login (paling gampang pakai akun GitHub).
2. Klik **New project**:
   - **Name**: `tayang`
   - **Database Password**: klik *Generate a password*, terus simpan di tempat aman
   - **Region**: **Southeast Asia (Singapore)**, yang paling dekat dari Jakarta
3. Klik **Create new project**, tunggu ±1–2 menit sampai statusnya hijau.

## 2. Bikin tabel

1. Di menu kiri, buka **SQL Editor**, terus klik **New query**.
2. Buka file [`schema.sql`](schema.sql), copy **semua** isinya, terus paste ke editor.
3. Klik **Run**. Harusnya muncul `Success. No rows returned`.
4. Cek di **Table Editor**: ada tabel `users`, `movies` (isinya 7 film), dan `bookmarks`.

> Kalau muncul error `relation "users" already exists`, berarti SQL-nya udah pernah dijalanin. Nggak usah dijalanin lagi.

## 3. Matikan konfirmasi email (disarankan buat demo)

Defaultnya Supabase ngirim email konfirmasi setiap ada yang daftar, dan email gratisannya dibatasi
cuma beberapa per jam. Biar daftar akun langsung bisa dipakai:

**Authentication → Sign In / Providers → Email**, matikan **Confirm email**, terus **Save**.

Kalau tetap dinyalain juga nggak apa-apa. App bakal minta user buka link di email dulu sebelum bisa masuk.

## 4. Sambungkan ke aplikasi

1. Klik tombol **Connect** di bagian atas dashboard (atau buka **Project Settings → API Keys**).
2. Copy dua nilai ini:
   - **Project URL**, contohnya `https://abcdefghijkl.supabase.co`
   - **Publishable key** (`sb_publishable_...`), atau **anon key** di project lama
3. Pilih salah satu:
   - **Config pribadi** (disarankan kalau kamu bukan pemilik repo): copy `supabase.example.json` jadi
     `supabase.json`, isi dua nilai itu, terus jalanin app pakai
     `flutter run -d chrome --dart-define-from-file=supabase.json`. File ini nggak ikut ke git.
   - **Jadiin bawaan repo** (pemilik repo): isi di [`lib/config.dart`](../lib/config.dart) sebagai `defaultValue`:

     ```dart
     const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://abcdefghijkl.supabase.co');
     const supabaseKey = String.fromEnvironment('SUPABASE_KEY', defaultValue: 'sb_publishable_...');
     ```

> Publishable/anon key memang dibuat buat ditaruh di aplikasi, jadi aman masuk GitHub. Data tetap dijaga
> **Row Level Security** di `schema.sql`. **Jangan pernah** taruh *secret key* / `service_role` di aplikasi.

## 5. Jadikan akunmu admin

Semua akun yang daftar lewat app otomatis jadi **user**, yang cuma bisa lihat film dan nyimpen favorit.
Buat jadiin admin:

1. Daftar dulu lewat app.
2. Di **SQL Editor**, jalanin query ini (ganti emailnya):

   ```sql
   update public.users set role = 'admin' where email = 'email@kamu.com';
   ```

   Atau lewat **Table Editor → users**: klik dua kali sel `role`, ganti jadi `admin`, terus **Save**.
3. Di app, tarik layar daftar film ke bawah buat refresh, atau keluar terus masuk lagi. Tombol **+ Tambah**
   bakal muncul di beranda, dan **Edit film / Hapus film** muncul di halaman detail.

Role nggak bisa diubah dari dalam app, termasuk sama user-nya sendiri. Cuma bisa dari dashboard ini.

> **Project yang dibuat sebelum ada role?** Jalanin [`upgrade_roles.sql`](upgrade_roles.sql) sekali di
> SQL Editor. Ganti dulu email di baris paling bawahnya pakai email akunmu.

## Aturan akses (RLS)

| Tabel | Siapa boleh apa |
| --- | --- |
| `users` | Tiap user cuma bisa lihat profilnya sendiri dan ganti **nama**. Kolom `role` nggak bisa diubah dari app. Barisnya dibuat otomatis waktu daftar dengan role `user`. |
| `movies` | Semua orang boleh lihat. Tambah, ubah, dan hapus cuma bisa sama **admin** (termasuk film bawaan). |
| `bookmarks` | Tiap user cuma bisa lihat, nambah, dan hapus favoritnya sendiri. |
| Storage `posters` | Poster bisa dilihat publik. Upload dan hapus cuma bisa sama **admin**. |
