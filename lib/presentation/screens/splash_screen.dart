import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.precacheFuture});

  /// Future que completa quando todos os assets críticos foram precarregados.
  /// A navegação para a Home só acontece quando esta future completa
  /// (ou após [maxWait], o que vier primeiro), garantindo um mínimo de
  /// [minDuration] de tela visível para o usuário.
  final Future<void>? precacheFuture;

  /// Duração mínima da splash, mesmo que o precache termine antes.
  static const Duration minDuration = Duration(milliseconds: 1500);

  /// Tempo máximo aguardando o precache. Se estourar, navega mesmo assim
  /// (defesa contra travamento por asset corrompido).
  static const Duration maxWait = Duration(seconds: 4);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    final shownAt = DateTime.now();
    if (widget.precacheFuture != null) {
      try {
        await widget.precacheFuture!.timeout(SplashScreen.maxWait);
      } catch (_) {
        // Ignora — navega mesmo assim.
      }
    }
    if (!mounted) return;
    final elapsed = DateTime.now().difference(shownAt);
    final remaining = SplashScreen.minDuration - elapsed;
    if (remaining > Duration.zero) {
      _navTimer = Timer(remaining, _navigate);
    } else {
      _navigate();
    }
  }

  void _navigate() {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B3610),
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/splash/splashscreen.png',
          fit: BoxFit.cover,
        )
            .animate()
            .fadeIn(duration: 400.ms),
      ),
    );
  }
}
