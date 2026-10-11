# Tayang

Aplikasi Flutter buat lihat film yang lagi tayang di bioskop **Jakarta & sekitarnya**.

- **Cari judul film**
- **Filter lokasi**: pilih wilayah (Jaksel, Jakpus, Jakbar, Jakut, Jaktim, Bodetabek), terus kalau mau bisa pilih satu bioskop
- **Poster** di daftar film, plus header besar di halaman detail
- **Tambah film sendiri**: judul, poster (dari galeri atau link gambar), genre, rating, sinopsis, dan jadwal per bioskop. Filmnya tersimpan di perangkat masing-masing dan bisa dihapus lagi
- **Peta ↗**: buka lokasi bioskop di Google Maps

Bisa jalan di **Android** (APK) dan di **browser** (Chrome).

> **Mau jalanin di laptop lain?** Ikutin [TUTORIAL.md](TUTORIAL.md). Isinya langkah demi langkah dari nol sampai app-nya jalan.

## Jalanin cepat

Kalau Flutter udah terpasang:

```bash
git clone https://github.com/AbdiJ09/tayang.git
cd tayang
flutter pub get
flutter run -d chrome
```

## Struktur

```
assets/data/tayang.json   data wilayah, bioskop, film & jadwal bawaan
lib/main.dart             entry point
lib/data.dart             model + load JSON + simpan film buatan user
lib/home.dart             halaman utama: search, filter wilayah/bioskop, daftar film
lib/detail.dart           halaman detail: poster, sinopsis, jadwal per wilayah
lib/add_movie.dart        form tambah film
lib/poster.dart           widget poster (URL / galeri / poster teks pengganti)
lib/theme.dart            warna & tipografi
```

## Update jadwal bawaan

Semua data bawaan ada di [`assets/data/tayang.json`](assets/data/tayang.json):

- `updated`: tanggal jadwal (muncul di bagian bawah app)
- `cinemas`: daftar bioskop. `region` harus salah satu `id` di `regions`
- `movies[].poster`: link gambar poster (boleh dikosongkan)
- `movies[].showtimes`: `{ "<id bioskop>": ["jam", ...] }`

Data bawaan ini **contoh**. Cek ulang judul dan jam tayangnya sebelum dipakai beneran. Poster diambil dari
[TMDB](https://www.themoviedb.org/). Film yang ditambah lewat menu **+ Tambah film** nggak masuk ke file ini,
cuma tersimpan di perangkat yang nambahin.

## Build APK

```bash
flutter build apk --release
```

Hasilnya ada di `build/app/outputs/flutter-apk/app-release.apk`.
