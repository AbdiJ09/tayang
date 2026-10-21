import 'package:flutter/material.dart';

import 'data.dart';
import 'detail.dart';
import 'home.dart' show MovieRow;
import 'theme.dart';

/// Daftar film yang ditandai user (tabel `bookmarks`).
class FavoritesPage extends StatelessWidget {
  final Catalog catalog;

  const FavoritesPage({super.key, required this.catalog});

  Future<void> _remove(BuildContext context, Movie movie) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await catalog.toggleBookmark(movie);
    } catch (e) {
      if (context.mounted) showError(context, friendlyError(e));
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1C1915),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(),
          content: Text(
            '“${movie.title}” dihapus dari favorit.',
            style: Txt.italic(16, color: Palette.ink),
          ),
          action: SnackBarAction(
            label: 'BATAL',
            textColor: Palette.brass,
            onPressed: () {
              if (!catalog.isBookmarked(movie)) {
                catalog.toggleBookmark(movie).ignore();
              }
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.sizeOf(context).width > 640 ? 48.0 : 24.0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: catalog,
          builder: (context, _) {
            final movies = catalog.bookmarkedMovies;
            return RefreshIndicator(
              onRefresh: catalog.refresh,
              color: Palette.brass,
              backgroundColor: const Color(0xFF1C1915),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(pad, 20, pad, 56),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('←  KEMBALI', style: Txt.label()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'DISIMPAN OLEH ${catalog.user.name.toUpperCase()}',
                    style: Txt.label(),
                  ),
                  const SizedBox(height: 14),
                  Text('Favorit', style: Txt.display(56)),
                  const SizedBox(height: 8),
                  Text(
                    movies.isEmpty
                        ? 'Belum ada film yang kamu simpan.'
                        : '${movies.length} film yang kamu tandai, '
                              'terbaru di atas.',
                    style: Txt.italic(19),
                  ),
                  const SizedBox(height: 36),
                  if (movies.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.only(top: 28),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Palette.hairline),
                        ),
                      ),
                      child: Text(
                        'Ketuk ikon penanda di samping judul film untuk '
                        'menyimpannya di sini.',
                        style: Txt.body(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'Lihat semua film',
                        style: Txt.italic(18, color: Palette.ink).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: Palette.faint,
                        ),
                      ),
                    ),
                  ],
                  for (final movie in movies)
                    MovieRow(
                      key: ValueKey(movie.id),
                      movie: movie,
                      screenings: catalog.screeningsOf(movie),
                      filtered: false,
                      saved: true,
                      onTap: () => Navigator.of(context).push(
                        fadeRoute(DetailPage(catalog: catalog, movie: movie)),
                      ),
                      onToggleSave: () => _remove(context, movie),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
