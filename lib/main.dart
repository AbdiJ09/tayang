import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_page.dart';
import 'config.dart';
import 'data.dart';
import 'home.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Palette.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  if (supabaseConfigured) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  }
  runApp(const TayangApp());
}

class TayangApp extends StatelessWidget {
  const TayangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tayang',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: supabaseConfigured
          ? const AuthGate()
          : const _Message(
              'Supabase belum diatur.\n'
              'Isi SUPABASE_URL & SUPABASE_KEY di lib/config.dart.',
            ),
    );
  }
}

/// Belum login → halaman masuk. Sudah login → muat data lalu beranda.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, _) {
        final user = auth.currentUser;
        if (user == null) return const AuthPage();
        return _CatalogLoader(key: ValueKey(user.id));
      },
    );
  }
}

class _CatalogLoader extends StatefulWidget {
  const _CatalogLoader({super.key});

  @override
  State<_CatalogLoader> createState() => _CatalogLoaderState();
}

class _CatalogLoaderState extends State<_CatalogLoader> {
  late Future<Catalog> _future = Catalog.load(Supabase.instance.client);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Catalog>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return _Message(
            'Data gagal dimuat.\n${friendlyError(snap.error!)}',
            action: (
              'Coba lagi',
              () => setState(
                () => _future = Catalog.load(Supabase.instance.client),
              ),
            ),
          );
        }
        if (!snap.hasData) return const _Message('Memuat…');
        return HomePage(catalog: snap.data!);
      },
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final (String, VoidCallback)? action;

  const _Message(this.text, {this.action});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, textAlign: TextAlign.center, style: Txt.italic(19)),
              if (action case (final label, final onTap)) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    label,
                    style: Txt.italic(18, color: Palette.ink).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: Palette.faint,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Supabase.instance.client.auth.signOut(),
                  child: Text('Keluar', style: Txt.label(size: 10)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
