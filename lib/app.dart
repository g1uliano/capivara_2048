import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/asset_precache.dart';
import 'domain/audio/audio_service.dart';
import 'presentation/screens/splash_screen.dart';

class CapivaraApp extends ConsumerStatefulWidget {
  const CapivaraApp({super.key, this.precacheFutureOverride});

  /// Override the precache future (tests only).
  /// When non-null, [SplashScreen] receives this instead of calling
  /// [precacheCriticalAssets]. Production code always passes null.
  @visibleForTesting
  final Future<void>? precacheFutureOverride;

  @override
  ConsumerState<CapivaraApp> createState() => _CapivaraAppState();
}

class _CapivaraAppState extends ConsumerState<CapivaraApp> {
  Future<void>? _precacheFuture;
  bool _audioInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inicia o precache uma única vez. Splashscreen é decodificada primeiro
    // (aguardada antes dos demais) para aparecer imediatamente; o resto
    // carrega em paralelo. A SplashScreen aguarda essa future antes de navegar.
    _precacheFuture ??= widget.precacheFutureOverride ?? precacheCriticalAssets(context);
    if (!_audioInitialized) {
      _audioInitialized = true;
      ref.read(audioServiceProvider).init();
    }
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
