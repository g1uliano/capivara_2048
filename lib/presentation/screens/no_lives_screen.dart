import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/lives/lives_notifier.dart';

class NoLivesScreen extends ConsumerStatefulWidget {
  /// If true, dismissing returns to game (mid-game context).
  /// If false, dismissing pops to HomeScreen.
  final bool midGame;

  const NoLivesScreen({super.key, this.midGame = false});

  @override
  ConsumerState<NoLivesScreen> createState() => _NoLivesScreenState();
}

class _NoLivesScreenState extends ConsumerState<NoLivesScreen> {
  late final StreamController<int> _countdownController;
  late final Stream<int> _countdownStream;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownController = StreamController<int>();
    _countdownStream = _countdownController.stream;
    _tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _countdownController.isClosed) return;
    final state = ref.read(livesProvider);
    final next = state.lastRegenAt.add(const Duration(minutes: 30));
    final remaining = next.difference(DateTime.now()).inSeconds;
    _countdownController.add(remaining < 0 ? 0 : remaining);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownController.close();
    super.dispose();
  }

  Future<void> _watchAd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anúncio simulado'),
        content: const Text('(Em produção, um anúncio real apareceria aqui.)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(livesProvider.notifier).rewardFromAd();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(livesProvider);
    final canWatch = DateTime.now().isAfter(state.adCounterResetAt) || state.adWatchedToday < 40;

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_border, color: Colors.redAccent, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Sem vidas!',
                  style: GoogleFonts.fredoka(fontSize: 32, color: Colors.white),
                ),
                const SizedBox(height: 8),
                StreamBuilder<int>(
                  stream: _countdownStream,
                  builder: (_, snap) {
                    final secs = snap.data ?? 0;
                    final mm = (secs ~/ 60).toString().padLeft(2, '0');
                    final ss = (secs % 60).toString().padLeft(2, '0');
                    return Text(
                      'Próxima vida em $mm:$ss',
                      style: GoogleFonts.nunito(fontSize: 18, color: Colors.white70),
                    );
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: canWatch ? _watchAd : null,
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text(
                    canWatch ? 'Assistir anúncio (+1 vida)' : 'Limite diário atingido',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    widget.midGame ? 'Voltar ao jogo' : 'Voltar ao menu',
                    style: GoogleFonts.nunito(color: Colors.white70),
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
