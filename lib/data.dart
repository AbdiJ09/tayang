import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Region {
  final String id;
  final String name;

  const Region(this.id, this.name);

  factory Region.fromJson(Map<String, dynamic> j) =>
      Region(j['id'] as String, j['name'] as String);
}

class Cinema {
  final String id;
  final String name;
  final String chain;
  final String regionId;
  final String address;

  const Cinema({
    required this.id,
    required this.name,
    required this.chain,
    required this.regionId,
    required this.address,
  });

  factory Cinema.fromJson(Map<String, dynamic> j) => Cinema(
    id: j['id'] as String,
    name: j['name'] as String,
    chain: j['chain'] as String,
    regionId: j['region'] as String,
    address: j['address'] as String,
  );
}

/// Baris tabel `users`.
class AppUser {
  final String id;
  final String name;
  final String email;

  const AppUser({required this.id, required this.name, required this.email});

  factory AppUser.fromRow(Map<String, dynamic> r) => AppUser(
    id: r['id'] as String,
    name: r['name'] as String,
    email: r['email'] as String,
  );
}

/// Baris tabel `movies`.
class Movie {
  final String id;
  final String title;

  /// URL gambar (http/https). Di form tambah film bisa juga data URI base64
  /// dari galeri — diunggah ke Storage saat disimpan.
  final String? poster;
  final int? year;
  final List<String> genres;
  final int? duration;
  final String rating;
  final String synopsis;

  /// cinema id -> jam tayang ("HH:mm")
  final Map<String, List<String>> showtimes;

  /// id user pembuat; null untuk film bawaan.
  final String? createdBy;

  Movie({
    required this.id,
    required this.title,
    this.poster,
    this.year,
    this.genres = const [],
    this.duration,
    this.rating = 'SU',
    this.synopsis = '',
    this.showtimes = const {},
    this.createdBy,
  });

  factory Movie.fromRow(Map<String, dynamic> r) => Movie(
    id: r['id'] as String,
    title: r['title'] as String,
    poster: r['poster_url'] as String?,
    year: r['year'] as int?,
    genres: List<String>.from(r['genres'] as List? ?? const []),
    duration: r['duration'] as int?,
    rating: r['rating'] as String? ?? 'SU',
    synopsis: r['synopsis'] as String? ?? '',
    showtimes: (r['showtimes'] as Map<String, dynamic>? ?? const {}).map(
      (k, v) => MapEntry(k, List<String>.from(v as List)),
    ),
    createdBy: r['created_by'] as String?,
  );

  Map<String, dynamic> toRow() => {
    'title': title,
    'poster_url': poster,
    'year': year,
    'genres': genres,
    'duration': duration,
    'rating': rating,
    'synopsis': synopsis,
    'showtimes': showtimes,
    'created_by': createdBy,
  };

  /// Byte poster kalau masih berupa data URI (pratinjau di form tambah film).
  late final Uint8List? posterBytes = () {
    final p = poster;
    if (p == null || !p.startsWith('data:')) return null;
    final comma = p.indexOf(',');
    return comma < 0 ? null : base64Decode(p.substring(comma + 1));
  }();

  String? get durationLabel {
    final d = duration;
    if (d == null || d <= 0) return null;
    final h = d ~/ 60;
    final m = d % 60;
    return h > 0 ? '${h}j ${m}m' : '${m}m';
  }

  /// Tahun, durasi, rating — yang kosong dilewati.
  List<String> get facts => [
    if (year != null) '$year',
    if (durationLabel != null) durationLabel!.toUpperCase(),
    rating,
  ];
}

/// Semua data yang dipakai app: wilayah & bioskop dari JSON lokal, film &
/// favorit dari Supabase. Memberi tahu pendengar setiap ada perubahan.
class Catalog extends ChangeNotifier {
  final SupabaseClient db;
  final AppUser user;
  final String updated;
  final List<Region> regions;
  final List<Cinema> cinemas;

  List<Movie> _movies;
  final Set<String> _bookmarks;

  Catalog._(
    this.db,
    this.user,
    this.updated,
    this.regions,
    this.cinemas,
    this._movies,
    this._bookmarks,
  );

  List<Movie> get movies => List.unmodifiable(_movies);

  static Future<Catalog> load(SupabaseClient db) async {
    final authUser = db.auth.currentUser!;
    final raw = await rootBundle.loadString('assets/data/tayang.json');
    final j = jsonDecode(raw) as Map<String, dynamic>;

    final (profile, movies, bookmarks) = await (
      db.from('users').select().eq('id', authUser.id).maybeSingle(),
      _fetchMovies(db),
      db.from('bookmarks').select('movie_id').eq('user_id', authUser.id),
    ).wait;

    return Catalog._(
      db,
      profile != null
          ? AppUser.fromRow(profile)
          : AppUser(
              id: authUser.id,
              email: authUser.email ?? '',
              name: (authUser.email ?? 'kamu').split('@').first,
            ),
      j['updated'] as String,
      (j['regions'] as List)
          .map((e) => Region.fromJson(e as Map<String, dynamic>))
          .toList(),
      (j['cinemas'] as List)
          .map((e) => Cinema.fromJson(e as Map<String, dynamic>))
          .toList(),
      movies,
      {for (final b in bookmarks) b['movie_id'] as String},
    );
  }

  static Future<List<Movie>> _fetchMovies(SupabaseClient db) async {
    final rows = await db
        .from('movies')
        .select()
        .order('created_at', ascending: false)
        .order('title');
    return rows.map(Movie.fromRow).toList();
  }

  Future<void> refresh() async {
    final (movies, bookmarks) = await (
      _fetchMovies(db),
      db.from('bookmarks').select('movie_id').eq('user_id', user.id),
    ).wait;
    _movies = movies;
    _bookmarks
      ..clear()
      ..addAll(bookmarks.map((b) => b['movie_id'] as String));
    notifyListeners();
  }

  // ----- movies -----------------------------------------------------------

  bool canDelete(Movie movie) => movie.createdBy == user.id;

  /// Simpan film baru. Poster dari galeri (data URI) diunggah ke Storage dulu.
  Future<Movie> addMovie(Movie draft) async {
    var poster = draft.poster;
    final bytes = draft.posterBytes;
    if (bytes != null) {
      final mime = poster!.substring(5, poster.indexOf(';'));
      final ext = mime.split('/').last.replaceAll('jpeg', 'jpg');
      final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await db.storage
          .from('posters')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mime),
          );
      poster = db.storage.from('posters').getPublicUrl(path);
    }

    final row = await db
        .from('movies')
        .insert({...draft.toRow(), 'poster_url': poster, 'created_by': user.id})
        .select()
        .single();
    final movie = Movie.fromRow(row);
    _movies = [movie, ..._movies];
    notifyListeners();
    return movie;
  }

  Future<void> removeMovie(Movie movie) async {
    await db.from('movies').delete().eq('id', movie.id);
    _movies = _movies.where((m) => m.id != movie.id).toList();
    _bookmarks.remove(movie.id);
    notifyListeners();
  }

  // ----- bookmarks --------------------------------------------------------

  bool isBookmarked(Movie movie) => _bookmarks.contains(movie.id);

  int get bookmarkCount =>
      _movies.where((m) => _bookmarks.contains(m.id)).length;

  /// Tambah/hapus favorit. Tampilan langsung berubah; kalau gagal, dikembalikan.
  Future<void> toggleBookmark(Movie movie) async {
    final wasSaved = _bookmarks.contains(movie.id);
    wasSaved ? _bookmarks.remove(movie.id) : _bookmarks.add(movie.id);
    notifyListeners();
    try {
      if (wasSaved) {
        await db
            .from('bookmarks')
            .delete()
            .eq('user_id', user.id)
            .eq('movie_id', movie.id);
      } else {
        await db.from('bookmarks').insert({
          'user_id': user.id,
          'movie_id': movie.id,
        });
      }
    } catch (_) {
      wasSaved ? _bookmarks.add(movie.id) : _bookmarks.remove(movie.id);
      notifyListeners();
      rethrow;
    }
  }

  // ----- lokasi -----------------------------------------------------------

  Cinema? cinema(String id) {
    for (final c in cinemas) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<Cinema> cinemasIn(String? regionId) => regionId == null
      ? cinemas
      : cinemas.where((c) => c.regionId == regionId).toList();

  /// Bioskop (sesuai filter) yang memutar [movie], urut sesuai daftar bioskop.
  List<Cinema> screeningsOf(Movie movie, {String? regionId, String? cinemaId}) {
    return cinemas.where((c) {
      if (!movie.showtimes.containsKey(c.id)) return false;
      if (cinemaId != null) return c.id == cinemaId;
      if (regionId != null) return c.regionId == regionId;
      return true;
    }).toList();
  }
}

/// Pesan error Supabase dalam bahasa Indonesia.
String friendlyError(Object e) {
  final msg = switch (e) {
    AuthException(:final message) => message,
    PostgrestException(:final message) => message,
    StorageException(:final message) => message,
    _ => e.toString(),
  };
  final m = msg.toLowerCase();
  if (m.contains('invalid login credentials')) {
    return 'Email atau password salah.';
  }
  if (m.contains('already registered') || m.contains('already exists')) {
    return 'Email ini sudah terdaftar. Silakan masuk.';
  }
  if (m.contains('email not confirmed')) {
    return 'Email belum dikonfirmasi. Buka link di inbox kamu dulu.';
  }
  if (m.contains('password') && m.contains('at least')) {
    return 'Password minimal 6 karakter.';
  }
  if (m.contains('invalid') && m.contains('email')) {
    return 'Format email tidak valid.';
  }
  if (m.contains('rate limit') || m.contains('too many')) {
    return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
  }
  if (m.contains('failed host lookup') ||
      m.contains('socketexception') ||
      m.contains('clientexception') ||
      m.contains('failed to fetch')) {
    return 'Tidak ada koneksi internet.';
  }
  return msg;
}
