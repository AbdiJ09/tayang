import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_movie.dart';
import 'data.dart';
import 'detail.dart';
import 'favorites.dart';
import 'poster.dart';
import 'theme.dart';

class HomePage extends StatefulWidget {
  final Catalog catalog;

  const HomePage({super.key, required this.catalog});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _search = TextEditingController();
  String _query = '';
  String? _regionId;
  String? _cinemaId;

  Catalog get c => widget.catalog;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();

  List<Movie> get _results {
    final q = _norm(_query);
    return c.movies.where((m) {
      if (q.isNotEmpty && !_norm(m.title).contains(q)) return false;
      if (_regionId == null) return true;
      return c
          .screeningsOf(m, regionId: _regionId, cinemaId: _cinemaId)
          .isNotEmpty;
    }).toList();
  }

  void _pickRegion(String? id) => setState(() {
    _regionId = id;
    _cinemaId = null;
  });

  void _openDetail(Movie movie) => Navigator.of(
    context,
  ).push(fadeRoute(DetailPage(catalog: c, movie: movie, regionId: _regionId)));

  void _openFavorites() =>
      Navigator.of(context).push(fadeRoute(FavoritesPage(catalog: c)));

  Future<void> _openAdd() async {
    final movie = await Navigator.of(context)
        .push<Movie>(fadeRoute(AddMoviePage(catalog: c)));
    if (movie == null) return;
    setState(() {
      _query = '';
      _search.clear();
      _regionId = null;
      _cinemaId = null;
    });
  }

  Future<void> _toggleBookmark(Movie movie) async {
    try {
      await c.toggleBookmark(movie);
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    }
  }

  Future<void> _refresh() async {
    try {
      await c.refresh();
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final results = _results;
    final pad = MediaQuery.sizeOf(context).width > 640 ? 48.0 : 24.0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: Palette.brass,
            backgroundColor: const Color(0xFF1C1915),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 40, pad, 0),
                  sliver: SliverList.list(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _HeaderAction(
                            onTap: _openFavorites,
                            child: Row(
                              children: [
                                BookmarkIcon(
                                  saved: c.bookmarkCount > 0,
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'FAVORIT · ${c.bookmarkCount}',
                                  style: Txt.label(color: Palette.ink),
                                ),
                              ],
                            ),
                          ),
                          if (c.isAdmin) ...[
                            const SizedBox(width: 24),
                            _HeaderAction(
                              onTap: _openAdd,
                              child: Text(
                                '+  TAMBAH',
                                style: Txt.label(color: Palette.brass),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text('JAKARTA & SEKITARNYA', style: Txt.label()),
                      const SizedBox(height: 14),
                      Text('Tayang', style: Txt.display(56)),
                      const SizedBox(height: 8),
                      Text(
                        'Film yang sedang diputar, bioskop demi bioskop.',
                        style: Txt.italic(19),
                      ),
                      const SizedBox(height: 36),
                      _SearchField(
                        controller: _search,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: _TextTabs(
                    padding: pad,
                    items: [
                      (null, 'Semua'),
                      for (final r in c.regions) (r.id, r.name),
                    ],
                    selected: _regionId,
                    onSelect: _pickRegion,
                  ),
                ),
                if (_regionId != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _TextTabs(
                        padding: pad,
                        small: true,
                        items: [
                          (null, 'Semua bioskop'),
                          for (final cin in c.cinemasIn(_regionId))
                            (cin.id, cin.name),
                        ],
                        selected: _cinemaId,
                        onSelect: (id) => setState(() => _cinemaId = id),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 28, pad, 12),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '${results.length} FILM  ·  '
                      '${_cinemaId != null ? 1 : c.cinemasIn(_regionId).length} BIOSKOP',
                      style: Txt.label(color: Palette.faint),
                    ),
                  ),
                ),
                if (results.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 32, pad, 0),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        _query.isNotEmpty
                            ? 'Tidak ada film berjudul “$_query” di sini.'
                            : 'Belum ada film yang diputar di sini.',
                        style: Txt.italic(20),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    sliver: SliverList.builder(
                      itemCount: results.length,
                      itemBuilder: (context, i) => MovieRow(
                        movie: results[i],
                        screenings: c.screeningsOf(
                          results[i],
                          regionId: _regionId,
                          cinemaId: _cinemaId,
                        ),
                        filtered: _regionId != null,
                        saved: c.isBookmarked(results[i]),
                        onTap: () => _openDetail(results[i]),
                        onToggleSave: () => _toggleBookmark(results[i]),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 48, pad, 48),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'JADWAL PER ${_dateLabel(c.updated)}',
                          style: Txt.label(color: Palette.faint, size: 10),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'MASUK SEBAGAI ${c.user.name.toUpperCase()}'
                                '${c.isAdmin ? ' · ADMIN' : ''}',
                                overflow: TextOverflow.ellipsis,
                                style: Txt.label(
                                  color: Palette.faint,
                                  size: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            GestureDetector(
                              onTap: () =>
                                  Supabase.instance.client.auth.signOut(),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(
                                  'KELUAR',
                                  style: Txt.label(
                                    color: Palette.brass,
                                    size: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _dateLabel(String iso) {
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MEI',
    'JUN',
    'JUL',
    'AGU',
    'SEP',
    'OKT',
    'NOV',
    'DES',
  ];
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: Txt.display(24),
      decoration: InputDecoration(
        hintText: 'Cari judul film',
        hintStyle: Txt.display(
          24,
          style: FontStyle.italic,
          color: Palette.faint,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.only(bottom: 12),
        prefixIconConstraints: const BoxConstraints(minWidth: 34),
        prefixIcon: const Align(
          widthFactor: 1,
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Icon(Icons.search, size: 20, color: Palette.muted),
          ),
        ),
        suffixIcon: ValueListenableBuilder(
          valueListenable: controller,
          builder: (_, v, _) => v.text.isEmpty
              ? const SizedBox.shrink()
              : GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Icon(Icons.close, size: 18, color: Palette.muted),
                  ),
                ),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Palette.hairline),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Palette.brass),
        ),
      ),
    );
  }
}

/// Deretan label teks yang bisa digeser; yang aktif digaris bawahi kuningan.
class _TextTabs extends StatelessWidget {
  final double padding;
  final List<(String?, String)> items;
  final String? selected;
  final ValueChanged<String?> onSelect;
  final bool small;

  const _TextTabs({
    required this.padding,
    required this.items,
    required this.selected,
    required this.onSelect,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Row(
        children: [
          for (final (id, name) in items)
            Padding(
              padding: EdgeInsets.only(right: small ? 20 : 26),
              child: GestureDetector(
                onTap: () => onSelect(id),
                behavior: HitTestBehavior.opaque,
                child: _Tab(
                  label: small ? name : name.toUpperCase(),
                  active: id == selected,
                  small: small,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final bool small;

  const _Tab({required this.label, required this.active, required this.small});

  @override
  Widget build(BuildContext context) {
    final style = small
        ? Txt.italic(17, color: active ? Palette.ink : Palette.faint)
        : Txt.label(color: active ? Palette.ink : Palette.muted, size: 11.5);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? Palette.brass : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: Text(label, style: style),
    );
  }
}

/// Satu baris film: poster, judul, info, jadwal ringkas, tombol favorit.
class MovieRow extends StatelessWidget {
  final Movie movie;
  final List<Cinema> screenings;
  final bool filtered;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

  const MovieRow({
    super.key,
    required this.movie,
    required this.screenings,
    required this.filtered,
    required this.saved,
    required this.onTap,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (movie.genres.isNotEmpty)
        movie.genres.join('\u00A0·\u00A0').toUpperCase(),
      ...movie.facts.skip(movie.year != null ? 1 : 0),
    ].join('  /  ');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Palette.hairline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 92, child: Poster(movie)),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie.title, style: Txt.display(26)),
                  const SizedBox(height: 10),
                  Text(meta, style: Txt.label(size: 10.5)),
                  const SizedBox(height: 14),
                  if (filtered)
                    for (final cin in screenings.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cin.name,
                              style: Txt.italic(17, color: Palette.ink),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              movie.showtimes[cin.id]!.join('   '),
                              style: Txt.label(color: Palette.brass),
                            ),
                          ],
                        ),
                      ),
                  if (filtered && screenings.length > 3)
                    Text(
                      '+${screenings.length - 3} bioskop lainnya',
                      style: Txt.italic(15),
                    ),
                  if (!filtered)
                    Text(
                      screenings.isEmpty
                          ? 'Belum ada jadwal'
                          : 'Diputar di ${screenings.length} bioskop',
                      style: Txt.italic(16),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onToggleSave,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 0, 12),
                child: BookmarkIcon(saved: saved),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ikon penanda favorit; berganti dengan fade halus.
class BookmarkIcon extends StatelessWidget {
  final bool saved;
  final double size;

  const BookmarkIcon({super.key, required this.saved, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Icon(
        saved ? Icons.bookmark : Icons.bookmark_border,
        key: ValueKey(saved),
        size: size,
        color: saved ? Palette.brass : Palette.faint,
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HeaderAction({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: child,
    ),
  );
}
