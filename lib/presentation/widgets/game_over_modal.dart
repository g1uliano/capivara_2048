import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/text_styles.dart';
import '../../domain/lives/lives_notifier.dart';
import '../controllers/game_notifier.dart';
import '../screens/no_lives_screen.dart';

class GameOverModal extends ConsumerWidget {
  final String message;
  const GameOverModal({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPlay = ref.watch(livesProvider.select((s) => s.lives > 0));
    final notifier = ref.read(gameProvider.notifier);

    return Container(
      color: const Color(0xCC000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: outlinedWhiteTextStyle(
                const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: canPlay
                  ? () => notifier.restart()
                  : () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const NoLivesScreen(midGame: false),
                        ),
                      ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Jogar de novo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
