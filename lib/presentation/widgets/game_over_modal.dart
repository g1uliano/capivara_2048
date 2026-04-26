import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/lives/lives_notifier.dart';
import '../controllers/game_notifier.dart';
import '../screens/no_lives_screen.dart';

class GameOverModal extends ConsumerWidget {
  final String message;
  const GameOverModal({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    return Container(
      color: const Color(0xCC000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                if (!ref.read(livesProvider.notifier).canPlay) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => const NoLivesScreen(midGame: false)),
                  );
                  return;
                }
                notifier.restart();
              },
              child: const Text('Jogar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}
