import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'data/animals_data.dart';
import 'presentation/screens/home_screen.dart';

class CapivaraApp extends StatefulWidget {
  const CapivaraApp({super.key});

  @override
  State<CapivaraApp> createState() => _CapivaraAppState();
}

class _CapivaraAppState extends State<CapivaraApp> {
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    for (final animal in animals) {
      precacheImage(
        ResizeImage(
          AssetImage(animal.tilePngPath),
          width: 144,
          height: 144,
        ),
        context,
      );
      precacheImage(
        ResizeImage(
          AssetImage(animal.hostPngPath),
          width: 304,
          height: 304,
        ),
        context,
      );
    }
    precacheImage(
      const AssetImage('assets/images/fundo.png'),
      context,
    );
    precacheImage(const AssetImage('assets/icons/inventory/bomb_2.png'), context);
    precacheImage(const AssetImage('assets/icons/inventory/bomb_3.png'), context);
    precacheImage(const AssetImage('assets/icons/inventory/undo_1.png'), context);
    precacheImage(const AssetImage('assets/icons/inventory/undo_3.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capivara 2048',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
