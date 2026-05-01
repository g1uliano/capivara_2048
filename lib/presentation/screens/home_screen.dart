import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../domain/daily_rewards/daily_rewards_engine.dart';
import '../../domain/daily_rewards/daily_rewards_notifier.dart';
import '../../domain/lives/lives_notifier.dart';
import '../../data/models/game_state.dart';
import '../controllers/game_notifier.dart';
import '../widgets/game_background.dart';
import '../widgets/game_title_image.dart';
import '../widgets/lives_indicator.dart';
import 'collection_screen.dart';
import 'daily_rewards/daily_rewards_screen.dart';
import 'game/game_screen.dart';
import 'no_lives_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final String _titleAsset;

  @override
  void initState() {
    super.initState();
    _titleAsset = GameTitleImage.pickAsset();
  }

  bool _hasSavedGame(GameState s) => s.score > 0 && !s.isGameOver;

  void _onPlay(BuildContext context) {
    maybeHaptic(ref);
    if (!ref.read(livesProvider.notifier).canPlay) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NoLivesScreen(midGame: false)),
      );
      return;
    }
    final gameState = ref.read(gameProvider);
    if (_hasSavedGame(gameState)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
    } else {
      ref.read(gameProvider.notifier).restart();
      Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final dailyState = ref.watch(dailyRewardsProvider);
    final rewardAvailable = computeDailyRewardStatus(DateTime.now(), dailyState) ==
        DailyRewardStatus.available;

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                const LivesIndicator(),
                const SizedBox(height: 8),
                GameTitleImage(asset: _titleAsset, height: 200)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.85, 0.85)),
                const SizedBox(height: 16),
                _PlayButton(
                  label: _hasSavedGame(gameState) ? 'Continuar' : 'Novo Jogo',
                  onTap: () => _onPlay(context),
                ),
                const SizedBox(height: 12),
                GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: [
                      _HomeCard(
                        label: 'Loja',
                        icon: Icons.store_rounded,
                        onTap: () {
                          maybeHaptic(ref);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ShopScreen()),
                          );
                        },
                      ),
                      _HomeCard(
                        label: 'Ranking',
                        icon: Icons.leaderboard_rounded,
                        onTap: null,
                        comingSoon: true,
                      ),
                      _HomeCard(
                        label: 'Recompensa Diária',
                        icon: Icons.card_giftcard_rounded,
                        showBadge: rewardAvailable,
                        onTap: () {
                          maybeHaptic(ref);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DailyRewardsScreen()),
                          );
                        },
                      ),
                      _HomeCard(
                        label: 'Coleção',
                        icon: Icons.pets_rounded,
                        onTap: () {
                          maybeHaptic(ref);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CollectionScreen()),
                          );
                        },
                      ),
                      _HomeCard(
                        label: 'Configurações',
                        icon: Icons.settings_rounded,
                        onTap: () {
                          maybeHaptic(ref);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                      _HomeCard(
                        label: 'Como Jogar',
                        icon: Icons.help_outline_rounded,
                        onTap: () {
                          maybeHaptic(ref);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (_) => const _HowToPlaySheet(),
                          );
                        },
                      ),
                    ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
        ),
        child: Text(label, style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.label,
    required this.icon,
    required this.onTap,
    this.showBadge = false,
    this.comingSoon = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool showBadge;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: comingSoon ? Colors.grey : AppColors.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: comingSoon ? Colors.grey : const Color(0xFF3E2723),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (comingSoon)
                Text('Em breve', style: GoogleFonts.nunito(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );

    if (comingSoon) card = Opacity(opacity: 0.5, child: card);

    if (showBadge) {
      card = Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            ),
          ),
        ],
      );
    }

    return card;
  }
}

class _HowToPlaySheet extends StatelessWidget {
  const _HowToPlaySheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Como Jogar',
                style: GoogleFonts.fredoka(fontSize: 24, color: AppColors.primary)),
            const SizedBox(height: 12),
            Text(
              '• Deslize o dedo para mover todos os tiles.\n'
              '• Tiles com o mesmo animal se fundem ao se encontrar.\n'
              '• Funda animais até chegar na Capivara Lendária (2048)!\n'
              '• Cada partida consome uma vida. Vidas se regeneram com o tempo.\n'
              '• Use bombas e desfazer para sair de situações difíceis.',
              style: GoogleFonts.nunito(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
