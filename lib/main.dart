import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data.dart';
import 'home.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Palette.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const TayangApp());
}

class TayangApp extends StatelessWidget {
  const TayangApp({super.key});

  static final _catalog = Catalog.load();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tayang',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: FutureBuilder<Catalog>(
        future: _catalog,
        builder: (context, snap) {
          if (snap.hasError) {
            return Scaffold(
              body: Center(
                child: Text(
                  'Data gagal dimuat.\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: Txt.body(),
                ),
              ),
            );
          }
          if (!snap.hasData) return const Scaffold();
          return HomePage(catalog: snap.data!);
        },
      ),
    );
  }
}
