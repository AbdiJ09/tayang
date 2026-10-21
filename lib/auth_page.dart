import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data.dart';
import 'theme.dart';

/// Halaman masuk & daftar akun (tabel `users` via Supabase Auth).
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;
  String? _info;

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switchMode(bool signUp) => setState(() {
    _signUp = signUp;
    _error = null;
    _info = null;
  });

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    String? problem;
    if (_signUp && name.isEmpty) problem = 'Nama wajib diisi.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      problem ??= 'Format email tidak valid.';
    }
    if (password.length < 6) problem ??= 'Password minimal 6 karakter.';
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      if (_signUp) {
        final res = await _auth.signUp(
          email: email,
          password: password,
          data: {'name': name},
        );
        // Kalau konfirmasi email aktif, belum ada sesi sampai link diklik.
        if (res.session == null && mounted) {
          setState(() {
            _signUp = false;
            _info =
                'Akun dibuat. Buka link konfirmasi di email $email, lalu masuk.';
          });
        }
      } else {
        await _auth.signInWithPassword(email: email, password: password);
      }
      // Kalau berhasil, AuthGate di main.dart otomatis pindah ke beranda.
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.sizeOf(context).width > 640 ? 48.0 : 24.0;

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(pad, 40, pad, 40),
                children: [
                  Text('JAKARTA & SEKITARNYA', style: Txt.label()),
                  const SizedBox(height: 14),
                  Text('Tayang', style: Txt.display(56)),
                  const SizedBox(height: 8),
                  Text(
                    _signUp
                        ? 'Buat akun untuk menyimpan film favoritmu.'
                        : 'Masuk untuk melihat jadwal & favoritmu.',
                    style: Txt.italic(19),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      _ModeTab('MASUK', !_signUp, () => _switchMode(false)),
                      const SizedBox(width: 26),
                      _ModeTab('DAFTAR', _signUp, () => _switchMode(true)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: _signUp
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _Input(
                              label: 'NAMA',
                              controller: _name,
                              hint: 'Nama kamu',
                              capitalize: true,
                              action: TextInputAction.next,
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  _Input(
                    label: 'EMAIL',
                    controller: _email,
                    hint: 'nama@email.com',
                    keyboard: TextInputType.emailAddress,
                    action: TextInputAction.next,
                    autofill: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 24),
                  _Input(
                    label: 'PASSWORD',
                    controller: _password,
                    hint: 'Minimal 6 karakter',
                    obscure: _hidePassword,
                    action: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    autofill: [
                      _signUp
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    suffix: GestureDetector(
                      onTap: () =>
                          setState(() => _hidePassword = !_hidePassword),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 4),
                        child: Text(
                          _hidePassword ? 'LIHAT' : 'SEMBUNYI',
                          style: Txt.label(size: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_error != null) ...[
                    Text(_error!, style: Txt.italic(17, color: Palette.brass)),
                    const SizedBox(height: 14),
                  ],
                  if (_info != null) ...[
                    Text(_info!, style: Txt.italic(17, color: Palette.ink)),
                    const SizedBox(height: 14),
                  ],
                  GestureDetector(
                    onTap: _busy ? null : _submit,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _busy ? 0.5 : 1,
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        color: Palette.ink,
                        child: Text(
                          _busy
                              ? 'SEBENTAR…'
                              : (_signUp ? 'BUAT AKUN' : 'MASUK'),
                          style: Txt.label(color: Palette.bg, size: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? Palette.brass : Colors.transparent,
            ),
          ),
        ),
        child: Text(
          label,
          style: Txt.label(
            size: 12,
            color: active ? Palette.ink : Palette.muted,
          ),
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final bool capitalize;
  final TextInputType? keyboard;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofill;
  final Widget? suffix;

  const _Input({
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.capitalize = false,
    this.keyboard,
    this.action,
    this.onSubmitted,
    this.autofill,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Txt.label(size: 10)),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          textInputAction: action,
          onSubmitted: onSubmitted,
          autofillHints: autofill,
          autocorrect: false,
          enableSuggestions: !obscure,
          textCapitalization: capitalize
              ? TextCapitalization.words
              : TextCapitalization.none,
          style: Txt.body(color: Palette.ink, size: 17),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Txt.italic(18, color: Palette.faint),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Palette.hairline),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Palette.brass),
            ),
          ),
        ),
      ],
    );
  }
}
