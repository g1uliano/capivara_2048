import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/daily_rewards/daily_rewards_engine.dart';
import '../../domain/daily_rewards/daily_rewards_notifier.dart';
import '../../domain/lives/lives_notifier.dart';
import '../controllers/game_notifier.dart';
import '../widgets/daily_reward_entry_tile.dart';
import '../widgets/game_background.dart';
import '../widgets/lives_indicator.dart';
import 'game/game_screen.dart';
import 'no_lives_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _toastShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowToast());
  }

  void _maybeShowToast() {
    if (_toastShown) return;
    final dailyState = ref.read(dailyRewardsProvider);
    final status = computeDailyRewardStatus(DateTime.now(), dailyState);
    if (status == DailyRewardStatus.available || status == DailyRewardStatus.cycleCompleted) {
      _toastShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sua recompensa diária está disponível!',
            style: GoogleFonts.nunito(),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final hasSave = gameState.score > 0;

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    LivesIndicator(),
                    DailyRewardEntryTile(),
                  ],
                ),
                const Spacer(),
                const SizedBox(height: 220),
                const SizedBox(height: 32),
                _HomeButton(
                  label: 'Novo Jogo',
                  onPressed: () => _startNew(context),
                ),
                const SizedBox(height: 12),
                _HomeButton(
                  label: 'Continuar',
                  onPressed: hasSave ? () => _continue(context) : null,
                ),
                const SizedBox(height: 12),
                const _RankingButton(),
                const SizedBox(height: 12),
                _HomeButton(
                  label: 'Sair',
                  onPressed: () => SystemNavigator.pop(),
                  secondary: true,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startNew(BuildContext context) {
    if (!ref.read(livesProvider.notifier).canPlay) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NoLivesScreen(midGame: false)),
      );
      return;
    }
    ref.read(gameProvider.notifier).restart();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  void _continue(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
  }
}

class _HomeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;

  const _HomeButton({
    required this.label,
    this.onPressed,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary ? Colors.white24 : Colors.white,
          foregroundColor: secondary ? Colors.white : AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _RankingButton extends StatelessWidget {
  const _RankingButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white38,
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Ranking',
                style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Positioned(
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Em breve',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
