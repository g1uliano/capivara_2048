import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/asset_precache.dart';
import 'presentation/screens/splash_screen.dart';

class CapivaraApp extends StatefulWidget {
  const CapivaraApp({super.key});

  @override
  State<CapivaraApp> createState() => _CapivaraAppState();
}

class _CapivaraAppState extends State<CapivaraApp> {
  Future<void>? _precacheFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inicia o precache uma única vez. Splashscreen é decodificada primeiro
    // (aguardada antes dos demais) para aparecer imediatamente; o resto
    // carrega em paralelo. A SplashScreen aguarda essa future antes de navegar.
    _precacheFuture ??= precacheCriticalAssets(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Olha o Bichim!',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: SplashScreen(precacheFuture: _precacheFuture),
    );
  }
}
