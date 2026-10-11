import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class Movie {
  final String id;
  final String title;

  /// URL gambar (http/https) atau data URI base64 dari galeri. Boleh kosong.
  final String? poster;
  final int? year;
  final List<String> genres;
  final int? duration;
  final String rating;
  final String synopsis;

  /// cinema id -> jam tayang ("HH:mm")
  final Map<String, List<String>> showtimes;

  /// true kalau film ini ditambahkan sendiri lewat app (bisa dihapus).
  final bool custom;

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
    this.custom = false,
  });

  factory Movie.fromJson(Map<String, dynamic> j, {bool custom = false}) =>
      Movie(
        id: j['id'] as String,
        title: j['title'] as String,
        poster: j['poster'] as String?,
        year: j['year'] as int?,
        genres: List<String>.from(j['genres'] as List? ?? const []),
        duration: j['duration'] as int?,
        rating: j['rating'] as String? ?? 'SU',
        synopsis: j['synopsis'] as String? ?? '',
        showtimes: (j['showtimes'] as Map<String, dynamic>? ?? const {}).map(
          (k, v) => MapEntry(k, List<String>.from(v as List)),
        ),
        custom: custom,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (poster != null) 'poster': poster,
    if (year != null) 'year': year,
    'genres': genres,
    if (duration != null) 'duration': duration,
    'rating': rating,
    'synopsis': synopsis,
    'showtimes': showtimes,
  };

  /// Byte poster kalau disimpan sebagai data URI (hasil pilih dari galeri).
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
    return h > 0 ? '${h}j\u00A0${m}m' : '${m}m';
  }

  /// Tahun, durasi, rating — yang kosong dilewati.
  List<String> get facts => [
    if (year != null) '$year',
    if (durationLabel != null) durationLabel!.toUpperCase(),
    rating,
  ];
}

class Catalog {
  static const _customKey = 'custom_movies';

  final String updated;
  final List<Region> regions;
  final List<Cinema> cinemas;
  final List<Movie> _builtIn;
  final List<Movie> _custom;

  Catalog._(
    this.updated,
    this.regions,
    this.cinemas,
    this._builtIn,
    this._custom,
  );

  /// Film tambahan sendiri tampil paling atas.
  List<Movie> get movies => [..._custom.reversed, ..._builtIn];

  static Future<Catalog> load() async {
    final raw = await rootBundle.loadString('assets/data/tayang.json');
    final j = jsonDecode(raw) as Map<String, dynamic>;

    var custom = <Movie>[];
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_customKey);
      if (saved != null) {
        custom = (jsonDecode(saved) as List)
            .map((e) => Movie.fromJson(e as Map<String, dynamic>, custom: true))
            .toList();
      }
    } catch (_) {
      // Penyimpanan rusak / tidak tersedia — mulai dari kosong.
    }

    return Catalog._(
      j['updated'] as String,
      (j['regions'] as List)
          .map((e) => Region.fromJson(e as Map<String, dynamic>))
          .toList(),
      (j['cinemas'] as List)
          .map((e) => Cinema.fromJson(e as Map<String, dynamic>))
          .toList(),
      (j['movies'] as List)
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList(),
      custom,
    );
  }

  Future<void> _saveCustom() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customKey,
      jsonEncode(_custom.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> addMovie(Movie movie) async {
    _custom.add(movie);
    await _saveCustom();
  }

  Future<void> removeMovie(Movie movie) async {
    _custom.removeWhere((m) => m.id == movie.id);
    await _saveCustom();
  }

  Cinema? cinema(String id) {
    for (final c in cinemas) {
      if (c.id == id) return c;
    }
    return null;
  }

  Region? region(String id) {
    for (final r in regions) {
      if (r.id == id) return r;
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
