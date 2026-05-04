import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/home_constants.dart';
import '../../core/utils/haptic_utils.dart';
import '../../domain/daily_rewards/daily_rewards_engine.dart';
import '../../domain/daily_rewards/daily_rewards_notifier.dart';
import '../../data/models/game_state.dart';
import '../controllers/game_notifier.dart';
import '../widgets/game_background.dart';
import '../widgets/game_title_image.dart';
import 'collection_screen.dart';
import 'daily_rewards/daily_rewards_screen.dart';
import 'game/game_screen.dart';
import 'ranking_screen.dart';
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

  void _startNewGame() {
    maybeHaptic(ref);
    ref.read(gameProvider.notifier).restart();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  void _continueGame() {
    maybeHaptic(ref);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  void _nav(Widget screen) {
    maybeHaptic(ref);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final dailyState = ref.watch(dailyRewardsProvider);
    final rewardAvailable =
        computeDailyRewardStatus(DateTime.now(), dailyState) == DailyRewardStatus.available;
    final h = MediaQuery.of(context).size.height;

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // Canto superior esquerdo — Coleção
              Positioned(
                top: HomeConstants.edgePad(h),
                left: HomeConstants.edgePad(h),
                child: _HomeButton(
                  key: const Key('home_btn_colecao'),
                  path: 'assets/images/home/Colecao.png',
                  size: HomeConstants.buttonSize(h),
                  onTap: () => _nav(const CollectionScreen()),
                ),
              ),

              // Canto superior direito — Configurações
              Positioned(
                top: HomeConstants.edgePad(h),
                right: HomeConstants.edgePad(h),
                child: _HomeButton(
                  key: const Key('home_btn_configuracao'),
                  path: 'assets/images/home/Configuracao.png',
                  size: HomeConstants.buttonSize(h),
                  onTap: () => _nav(const SettingsScreen()),
                ),
              ),

              // Centro — título + botões de ação
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GameTitleImage(asset: _titleAsset, height: 200)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.85, 0.85)),
                    SizedBox(height: HomeConstants.titleActionGap(h)),
                    if (_hasSavedGame(gameState))
                      _ActionButton(
                        label: 'Continuar Jogo',
                        onTap: _continueGame,
                      ),
                    if (_hasSavedGame(gameState)) const SizedBox(height: 12),
                    _ActionButton(
                      label: 'Novo jogo',
                      onTap: _startNewGame,
                    ),
                  ],
                ),
              ),

              // Fileira inferior superior esquerda — Recompensas
              Positioned(
                bottom: HomeConstants.rowTopBottom(h),
                left: HomeConstants.edgePad(h),
                child: _HomeButtonWithBadge(
                  key: const Key('home_btn_recompensas'),
                  path: 'assets/images/home/Recompensas.png',
                  size: HomeConstants.buttonSize(h),
                  showBadge: rewardAvailable,
                  onTap: () => _nav(const DailyRewardsScreen()),
                ),
              ),

              // Fileira inferior superior direita — Ranking
              Positioned(
                bottom: HomeConstants.rowTopBottom(h),
                right: HomeConstants.edgePad(h),
                child: _HomeButton(
                  key: const Key('home_btn_ranking'),
                  path: 'assets/images/home/Ranking.png',
                  size: HomeConstants.buttonSize(h),
                  onTap: () => _nav(const RankingScreen()),
                ),
              ),

              // Fileira base esquerda — Loja
              Positioned(
                bottom: HomeConstants.rowBaseBottom(h),
                left: HomeConstants.edgePad(h),
                child: _HomeButton(
                  key: const Key('home_btn_loja'),
                  path: 'assets/images/home/IconeLoja.png',
                  size: HomeConstants.buttonSize(h),
                  onTap: () => _nav(const ShopScreen()),
                ),
              ),

              // Fileira base direita — Como Jogar
              Positioned(
                bottom: HomeConstants.rowBaseBottom(h),
                right: HomeConstants.edgePad(h),
                child: _HomeButton(
                  key: const Key('home_btn_comojogar'),
                  path: 'assets/images/home/ComoJogar.png',
                  size: HomeConstants.buttonSize(h),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => const _HowToPlaySheet(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HomeButton
// ---------------------------------------------------------------------------

class _HomeButton extends StatefulWidget {
  const _HomeButton({
    super.key,
    required this.path,
    required this.size,
    required this.onTap,
  });

  final String path;
  final double size;
  final VoidCallback onTap;

  @override
  State<_HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<_HomeButton> {
  double _scale = 1.0;

  void _onTapDown(_) => setState(() => _scale = 0.92);
  void _onTapUp(_) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          children: [
            // Camada branca (contorno seguindo a silhueta)
            Transform.scale(
              scale: 1.06,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                child: Image.asset(widget.path, width: widget.size, height: widget.size, fit: BoxFit.contain),
              ),
            ),
            // Imagem real
            Image.asset(widget.path, width: widget.size, height: widget.size, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HomeButtonWithBadge
// ---------------------------------------------------------------------------

class _HomeButtonWithBadge extends StatelessWidget {
  const _HomeButtonWithBadge({
    super.key,
    required this.path,
    required this.size,
    required this.onTap,
    required this.showBadge,
  });

  final String path;
  final double size;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _HomeButton(path: path, size: size, onTap: onTap),
        if (showBadge)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFEF5350),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _ActionButton
// ---------------------------------------------------------------------------

class _ActionButton extends StatefulWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  double _scale = 1.0;

  void _onTapDown(_) => setState(() => _scale = 0.95);
  void _onTapUp(_) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: HomeConstants.actionButtonWidth,
          height: HomeConstants.actionButtonHeight,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3E2723),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HowToPlaySheet — sem alterações
// ---------------------------------------------------------------------------

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
