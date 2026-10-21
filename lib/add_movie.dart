import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'data.dart';
import 'poster.dart';
import 'theme.dart';

const _ratings = ['SU', '13+', '17+', '21+'];
final _timePattern = RegExp(r'^([01]?\d|2[0-3])[:.]([0-5]\d)$');

/// Form tambah film. Mengembalikan [Movie] baru lewat Navigator.pop.
class AddMoviePage extends StatefulWidget {
  final Catalog catalog;

  const AddMoviePage({super.key, required this.catalog});

  @override
  State<AddMoviePage> createState() => _AddMoviePageState();
}

class _ScheduleRow {
  String? cinemaId;
  final times = TextEditingController();
}

class _AddMoviePageState extends State<AddMoviePage> {
  final _title = TextEditingController();
  final _year = TextEditingController(text: '${DateTime.now().year}');
  final _duration = TextEditingController();
  final _genres = TextEditingController();
  final _synopsis = TextEditingController();
  String _rating = 'SU';
  String? _poster;
  final _schedules = <_ScheduleRow>[_ScheduleRow()];
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _year, _duration, _genres, _synopsis]) {
      c.dispose();
    }
    for (final r in _schedules) {
      r.times.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPoster() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1C1915),
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('POSTER', style: Txt.label()),
              const SizedBox(height: 8),
              _SheetOption(
                'Pilih dari galeri',
                () => Navigator.pop(ctx, 'gallery'),
              ),
              _SheetOption(
                'Pakai link gambar',
                () => Navigator.pop(ctx, 'url'),
              ),
              if (_poster != null)
                _SheetOption('Hapus poster', () => Navigator.pop(ctx, 'clear')),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;

    switch (choice) {
      case 'clear':
        setState(() => _poster = null);
      case 'url':
        final url = await _askUrl();
        if (url != null && mounted) setState(() => _poster = url);
      case 'gallery':
        final file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 600,
          imageQuality: 82,
        );
        if (file == null) return;
        final bytes = await file.readAsBytes();
        final mime = file.mimeType ?? 'image/jpeg';
        if (mounted) {
          setState(() => _poster = 'data:$mime;base64,${base64Encode(bytes)}');
        }
    }
  }

  Future<String?> _askUrl() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1915),
        shape: const RoundedRectangleBorder(),
        title: Text('Link gambar poster', style: Txt.display(24)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.url,
          style: Txt.body(),
          decoration: _lineDecoration('https://…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('BATAL', style: Txt.label()),
          ),
          TextButton(
            onPressed: () {
              final v = ctrl.text.trim();
              Navigator.pop(ctx, v.startsWith('http') ? v : null);
            },
            child: Text('PAKAI', style: Txt.label(color: Palette.brass)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Judul film wajib diisi.');
      return;
    }

    final showtimes = <String, List<String>>{};
    for (final row in _schedules) {
      final raw = row.times.text.trim();
      if (row.cinemaId == null && raw.isEmpty) continue;
      if (row.cinemaId == null) {
        setState(() => _error = 'Pilih bioskop untuk jam “$raw”.');
        return;
      }
      final times = <String>[];
      for (final t in raw.split(RegExp(r'[,\s]+')).where((t) => t.isNotEmpty)) {
        final m = _timePattern.firstMatch(t);
        if (m == null) {
          setState(() => _error = 'Jam “$t” tidak valid. Pakai format 13:30.');
          return;
        }
        times.add('${m[1]!.padLeft(2, '0')}:${m[2]}');
      }
      if (times.isEmpty) {
        final name = widget.catalog.cinema(row.cinemaId!)?.name ?? '';
        setState(() => _error = 'Isi jam tayang untuk $name.');
        return;
      }
      showtimes.update(
        row.cinemaId!,
        (old) => [...old, ...times],
        ifAbsent: () => times,
      );
    }
    final year = int.tryParse(_year.text.trim());
    if (year != null && (year < 1888 || year > 2100)) {
      setState(() => _error = 'Tahun tidak valid.');
      return;
    }
    final duration = int.tryParse(_duration.text.trim());

    final draft = Movie(
      id: '',
      title: title,
      poster: _poster,
      year: year,
      duration: duration == 0 ? null : duration,
      genres: _genres.text
          .split(',')
          .map((g) => g.trim())
          .where((g) => g.isNotEmpty)
          .toList(),
      rating: _rating,
      synopsis: _synopsis.text.trim(),
      showtimes: showtimes.map(
        (k, v) => MapEntry(k, v.toSet().toList()..sort()),
      ),
    );

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.catalog.addMovie(draft);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Gagal menyimpan: ${friendlyError(e)}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.sizeOf(context).width > 640 ? 48.0 : 24.0;
    final preview = Movie(
      id: 'preview',
      title: _title.text.isEmpty ? 'Judul film' : _title.text,
      poster: _poster,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: ListView(
            padding: EdgeInsets.fromLTRB(pad, 20, pad, 48),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('←  BATAL', style: Txt.label()),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text('Tambah film', style: Txt.display(46)),
              const SizedBox(height: 6),
              Text(
                'Akan terlihat oleh semua pengguna Tayang.',
                style: Txt.italic(18),
              ),
              const SizedBox(height: 36),

              // Poster + judul berdampingan.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickPoster,
                    child: SizedBox(
                      width: 116,
                      child: Stack(
                        children: [
                          Poster(preview, showTitle: false),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(color: Palette.hairline),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              color: const Color(0xCC12100E),
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              alignment: Alignment.center,
                              child: Text(
                                _poster == null ? '+ POSTER' : 'GANTI',
                                style: Txt.label(
                                  color: Palette.brass,
                                  size: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Field(
                          label: 'JUDUL',
                          controller: _title,
                          hint: 'Judul film',
                          large: true,
                          onChanged: (_) => setState(() => _error = null),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _Field(
                                label: 'TAHUN',
                                controller: _year,
                                number: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _Field(
                                label: 'MENIT',
                                controller: _duration,
                                hint: '120',
                                number: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _Field(
                label: 'GENRE',
                controller: _genres,
                hint: 'Drama, Komedi',
              ),
              const SizedBox(height: 28),
              Text('RATING', style: Txt.label(size: 10)),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final r in _ratings)
                    Padding(
                      padding: const EdgeInsets.only(right: 22),
                      child: GestureDetector(
                        onTap: () => setState(() => _rating = r),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: r == _rating
                                    ? Palette.brass
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          child: Text(
                            r,
                            style: Txt.label(
                              size: 13,
                              color: r == _rating ? Palette.ink : Palette.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              _Field(
                label: 'SINOPSIS',
                controller: _synopsis,
                hint: 'Ceritanya tentang…',
                maxLines: 4,
              ),
              const SizedBox(height: 44),
              Text('JADWAL', style: Txt.label(color: Palette.ink)),
              const SizedBox(height: 4),
              Text(
                'Jam dipisah koma, contoh 13:00, 15:30',
                style: Txt.italic(15),
              ),
              for (final (i, row) in _schedules.indexed)
                _ScheduleEditor(
                  key: ObjectKey(row),
                  catalog: widget.catalog,
                  row: row,
                  onChanged: () => setState(() => _error = null),
                  onRemove: _schedules.length == 1
                      ? null
                      : () => setState(() {
                          _schedules.removeAt(i).times.dispose();
                        }),
                ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _schedules.add(_ScheduleRow())),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '+  Tambah bioskop lain',
                    style: Txt.italic(17, color: Palette.ink).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: Palette.faint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (_error != null) ...[
                Text(_error!, style: Txt.italic(17, color: Palette.brass)),
                const SizedBox(height: 14),
              ],
              GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  color: _saving ? Palette.muted : Palette.ink,
                  child: Text(
                    _saving ? 'MENYIMPAN…' : 'SIMPAN FILM',
                    style: Txt.label(color: Palette.bg, size: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _lineDecoration(String? hint, {double size = 16}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: Txt.italic(size, color: Palette.faint),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Palette.hairline),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Palette.brass),
      ),
    );

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool number;
  final bool large;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.number = false,
    this.large = false,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Txt.label(size: 10)),
        TextField(
          controller: controller,
          onChanged: onChanged,
          minLines: 1,
          maxLines: maxLines,
          keyboardType: number ? TextInputType.number : null,
          inputFormatters: number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          textCapitalization: number
              ? TextCapitalization.none
              : TextCapitalization.sentences,
          style: large ? Txt.display(24) : Txt.body(color: Palette.ink),
          decoration: _lineDecoration(hint, size: large ? 24 : 16),
        ),
      ],
    );
  }
}

class _ScheduleEditor extends StatefulWidget {
  final Catalog catalog;
  final _ScheduleRow row;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _ScheduleEditor({
    super.key,
    required this.catalog,
    required this.row,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<_ScheduleEditor> {
  Future<void> _chooseCinema() async {
    final c = widget.catalog;
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1915),
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Text('PILIH BIOSKOP', style: Txt.label()),
            for (final r in c.regions) ...[
              const SizedBox(height: 22),
              Text(
                r.name.toUpperCase(),
                style: Txt.label(color: Palette.brass, size: 10),
              ),
              for (final cin in c.cinemasIn(r.id))
                _SheetOption(cin.name, () => Navigator.pop(ctx, cin.id)),
            ],
          ],
        ),
      ),
    );
    if (id != null) {
      setState(() => widget.row.cinemaId = id);
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cinema = widget.row.cinemaId == null
        ? null
        : widget.catalog.cinema(widget.row.cinemaId!);

    return Container(
      padding: const EdgeInsets.only(top: 18, bottom: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Palette.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _chooseCinema,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      cinema?.name ?? 'Pilih bioskop  ▾',
                      style: cinema == null
                          ? Txt.italic(20, color: Palette.muted)
                          : Txt.display(22),
                    ),
                  ),
                ),
              ),
              if (widget.onRemove != null)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close, size: 16, color: Palette.faint),
                  ),
                ),
            ],
          ),
          TextField(
            controller: widget.row.times,
            onChanged: (_) => widget.onChanged(),
            keyboardType: TextInputType.datetime,
            style: Txt.label(color: Palette.brass, size: 14),
            decoration: InputDecoration(
              hintText: '13:00, 15:30, 19:45',
              hintStyle: Txt.label(color: Palette.faint, size: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SheetOption(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Palette.hairline)),
        ),
        child: Text(label, style: Txt.display(21)),
      ),
    );
  }
}
