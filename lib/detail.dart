import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'add_movie.dart';
import 'data.dart';
import 'home.dart' show BookmarkIcon;
import 'poster.dart';
import 'theme.dart';

class DetailPage extends StatelessWidget {
  final Catalog catalog;
  final Movie movie;

  /// Wilayah yang sedang dipilih di beranda — ditampilkan paling atas.
  final String? regionId;

  const DetailPage({
    super.key,
    required this.catalog,
    required this.movie,
    this.regionId,
  });

  Future<void> _openMaps(Cinema cin) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${cin.name}, ${cin.address}',
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: catalog,
    builder: (context, _) => _build(context),
  );

  Future<void> _toggleBookmark(BuildContext context) async {
    try {
      await catalog.toggleBookmark(movie);
    } catch (e) {
      if (context.mounted) showError(context, friendlyError(e));
    }
  }

  Widget _build(BuildContext context) {
    final pad = MediaQuery.sizeOf(context).width > 640 ? 48.0 : 24.0;
    // Versi terbaru dari katalog (berubah setelah admin mengedit).
    final movie = catalog.movieById(this.movie.id) ?? this.movie;
    final saved = catalog.isBookmarked(movie);

    // Kelompokkan bioskop per wilayah; wilayah terpilih paling atas.
    final regions = [...catalog.regions]
      ..sort((a, b) => (a.id == regionId ? 0 : 1) - (b.id == regionId ? 0 : 1));
    final groups = [
      for (final r in regions) (r, catalog.screeningsOf(movie, regionId: r.id)),
    ].where((g) => g.$2.isNotEmpty).toList();

    final width = MediaQuery.sizeOf(context).width;
    final topInset = MediaQuery.paddingOf(context).top;
    final heroHeight = (width * 1.2).clamp(360.0, 560.0);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PosterImage(movie, showTitle: false),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.22, 0.55, 1],
                      colors: [
                        Color(0xAA12100E),
                        Color(0x0012100E),
                        Color(0x6612100E),
                        Palette.bg,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: topInset + 8,
                  left: pad,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '←  KEMBALI',
                        style: Txt.label(color: Palette.ink),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: pad,
                  right: pad,
                  bottom: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.facts.join('   —   '),
                        style: Txt.label(color: Palette.ink),
                      ),
                      const SizedBox(height: 12),
                      Text(movie.title, style: Txt.display(46)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 10, pad, 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        movie.genres.join(', '),
                        style: Txt.italic(20),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _toggleBookmark(context),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            BookmarkIcon(saved: saved, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              saved ? 'FAVORIT' : 'SIMPAN',
                              style: Txt.label(
                                color: saved ? Palette.brass : Palette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (movie.synopsis.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Text(movie.synopsis, style: Txt.body()),
                  ),
                ],
                const SizedBox(height: 52),
                Text('JADWAL HARI INI', style: Txt.label(color: Palette.ink)),
                if (groups.isEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada jadwal untuk film ini.',
                    style: Txt.italic(18),
                  ),
                ],
                for (final (region, cinemas) in groups) ...[
                  const SizedBox(height: 32),
                  Text(
                    region.name.toUpperCase(),
                    style: Txt.label(color: Palette.brass, size: 10.5),
                  ),
                  const SizedBox(height: 6),
                  for (final cin in cinemas)
                    _CinemaBlock(
                      cinema: cin,
                      times: movie.showtimes[cin.id]!,
                      onMaps: () => _openMaps(cin),
                    ),
                ],
                if (catalog.isAdmin) ...[
                  const SizedBox(height: 56),
                  Text('ADMIN', style: Txt.label(size: 10)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _AdminAction(
                        'Edit film',
                        color: Palette.ink,
                        onTap: () => Navigator.of(context).push(
                          fadeRoute(
                            AddMoviePage(catalog: catalog, initial: movie),
                          ),
                        ),
                      ),
                      const SizedBox(width: 28),
                      _AdminAction(
                        'Hapus film',
                        color: Palette.muted,
                        onTap: () => _confirmDelete(context),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1915),
        shape: const RoundedRectangleBorder(),
        title: Text('Hapus “${movie.title}”?', style: Txt.display(26)),
        content: Text(
          'Film ini akan hilang untuk semua pengguna, termasuk dari '
          'daftar favorit mereka.',
          style: Txt.body(size: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('BATAL', style: Txt.label()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('HAPUS', style: Txt.label(color: Palette.brass)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await catalog.removeMovie(movie);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) showError(context, friendlyError(e));
    }
  }
}

class _CinemaBlock extends StatelessWidget {
  final Cinema cinema;
  final List<String> times;
  final VoidCallback onMaps;

  const _CinemaBlock({
    required this.cinema,
    required this.times,
    required this.onMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Palette.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(cinema.name, style: Txt.display(24))),
              GestureDetector(
                onTap: onMaps,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 2),
                  child: Text(
                    'Peta ↗',
                    style: Txt.italic(16, color: Palette.ink).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: Palette.faint,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(cinema.address, style: Txt.italic(15)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in times)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Palette.hairline),
                  ),
                  child: Text(
                    t,
                    style: Txt.label(color: Palette.ink, size: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AdminAction(this.label, {required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        label,
        style: Txt.italic(18, color: color).copyWith(
          decoration: TextDecoration.underline,
          decorationColor: Palette.faint,
        ),
      ),
    ),
  );
}
