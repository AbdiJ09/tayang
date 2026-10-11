import 'package:flutter/material.dart';

import 'data.dart';
import 'theme.dart';

/// Poster film rasio 2:3. Kalau gambar kosong / gagal dimuat, diganti
/// poster tipografi polos dengan judul film.
class Poster extends StatelessWidget {
  final Movie movie;
  final bool showTitle;

  const Poster(this.movie, {super.key, this.showTitle = true});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: ClipRect(child: PosterImage(movie, showTitle: showTitle)),
    );
  }
}

/// Gambar poster tanpa rasio tetap — dipakai juga sebagai latar halaman detail.
class PosterImage extends StatelessWidget {
  final Movie movie;
  final BoxFit fit;

  /// Tulis judul di poster pengganti (kalau gambar tidak ada).
  final bool showTitle;

  const PosterImage(
    this.movie, {
    super.key,
    this.fit = BoxFit.cover,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = _TypePoster(movie, showTitle: showTitle);
    final bytes = movie.posterBytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    final url = movie.poster;
    if (url != null && url.startsWith('http')) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: (_, _, _) => fallback,
        frameBuilder: (_, child, frame, sync) => sync
            ? child
            : Stack(
                fit: StackFit.passthrough,
                children: [
                  fallback,
                  AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: child,
                  ),
                ],
              ),
      );
    }
    return fallback;
  }
}

class _TypePoster extends StatelessWidget {
  final Movie movie;
  final bool showTitle;

  const _TypePoster(this.movie, {required this.showTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2520), Color(0xFF16130F)],
        ),
      ),
      padding: const EdgeInsets.all(10),
      alignment: Alignment.bottomLeft,
      child: !showTitle
          ? null
          : LayoutBuilder(
              builder: (_, box) => Text(
                movie.title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Txt.display(
                  (box.maxWidth / 6).clamp(11, 40).toDouble(),
                  color: Palette.ink.withValues(alpha: 0.8),
                ),
              ),
            ),
    );
  }
}
