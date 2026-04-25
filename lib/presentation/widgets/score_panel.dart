import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/game_notifier.dart';

class ScorePanel extends ConsumerWidget {
  const ScorePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pontuação: ${state.score}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Recorde: ${state.highScore}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
          ElevatedButton(
            onPressed: () => ref.read(gameProvider.notifier).restart(),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }
}
