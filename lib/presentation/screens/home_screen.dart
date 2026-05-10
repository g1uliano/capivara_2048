import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/home_constants.dart';
import '../../core/utils/haptic_utils.dart';
import '../../presentation/controllers/settings_notifier.dart';
import '../../domain/daily_rewards/daily_rewards_engine.dart';
import '../../domain/daily_rewards/daily_rewards_notifier.dart';
import '../../data/models/game_state.dart';
import '../controllers/game_notifier.dart';
import '../widgets/game_background.dart';
import '../widgets/outlined_text.dart';
import '../widgets/game_title_image.dart';
import 'collection_screen.dart';
import 'daily_rewards/daily_rewards_screen.dart';
import 'game/game_screen.dart';
import 'ranking_screen.dart';
import 'settings_screen.dart';
import 'tutorial/tutorial_screen.dart';
import 'shop_screen.dart';
import 'profile_screen.dart';
import 'onboarding_auth_screen.dart';
import '../controllers/auth_controller.dart';
import '../widgets/avatar_widget.dart';

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
    maybeHaptic(() => ref.read(settingsProvider).hapticEnabled);
    ref.read(gameProvider.notifier).restart();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  void _continueGame() {
    maybeHaptic(() => ref.read(settingsProvider).hapticEnabled);
    // Garante que ao voltar pra Home (inclusive via back do Android, que não
    // dispara resume()) e clicar Continuar, o jogo de fato continue — senão
    // o jogador caia novamente no PauseOverlay e teria que clicar Continuar 2x.
    ref.read(gameProvider.notifier).resume();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  void _nav(Widget screen) {
    maybeHaptic(() => ref.read(settingsProvider).hapticEnabled);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _navGuarded(Widget screen) {
    maybeHaptic(() => ref.read(settingsProvider).hapticEnabled);
    final isLoggedIn = ref.read(authControllerProvider) != null;
    if (!isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingAuthScreen(showSkip: false),
        ),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final dailyState = ref.watch(dailyRewardsProvider);
    final playerProfile = ref.watch(authControllerProvider);
    final rewardAvailable =
        computeDailyRewardStatus(DateTime.now(), dailyState) ==
        DailyRewardStatus.available;
    final size = MediaQuery.of(context).size;
    final scale = min(size.width / 390.0, size.height / 844.0).clamp(0.1, 1.0);

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // Canto superior esquerdo — Coleção
              Positioned(
                top: HomeConstants.edgePad(scale),
                left: HomeConstants.edgePad(scale),
                child: _HomeButton(
                  key: const Key('home_btn_colecao'),
                  path: 'assets/images/home/Colecao.png',
                  size: HomeConstants.sizeColecao(scale),
                  onTap: () => _nav(const CollectionScreen()),
                  semanticLabel: 'Coleção',
                ),
              ),

              // Topo centro — Perfil
              Positioned(
                top: HomeConstants.edgePad(scale),
                left: 0,
                right: 0,
                child: Center(
                  child: Tooltip(
                    message: 'Perfil',
                    child: GestureDetector(
                      key: const Key('home_btn_perfil'),
                      onTap: () => _nav(const ProfileScreen()),
                      child: AvatarWidget(radius: 20, profile: playerProfile),
                    ),
                  ),
                ),
              ),

              // Canto superior direito — Configurações
              Positioned(
                top: HomeConstants.edgePad(scale),
                right: HomeConstants.edgePad(scale),
                child: _HomeButton(
                  key: const Key('home_btn_configuracao'),
                  path: 'assets/images/home/Configuracao.png',
                  size: HomeConstants.sizeConfiguracao(scale),
                  onTap: () => _nav(const SettingsScreen()),
                  semanticLabel: 'Configurações',
                ),
              ),

              // Centro — título + botões de ação (alinhado levemente acima do centro)
              Align(
                alignment: Alignment(0, HomeConstants.centerAlignY),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GameTitleImage(
                          asset: _titleAsset,
                          height: HomeConstants.titleHeight(scale),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.85, 0.85)),
                    SizedBox(height: HomeConstants.titleActionGap(scale)),
                    if (_hasSavedGame(gameState))
                      _ActionButton(
                        label: 'Continuar Jogo',
                        onTap: _continueGame,
                        scale: scale,
                      ),
                    if (_hasSavedGame(gameState)) const SizedBox(height: 12),
                    _ActionButton(
                      label: 'Novo jogo',
                      onTap: _startNewGame,
                      scale: scale,
                    ),
                  ],
                ),
              ),

              // Fileira inferior superior esquerda — Recompensas
              Positioned(
                bottom: HomeConstants.rowTopBottom(scale),
                left: HomeConstants.edgePad(scale),
                child: _HomeButtonWithBadge(
                  key: const Key('home_btn_recompensas'),
                  path: 'assets/images/home/Recompensas.png',
                  size: HomeConstants.sizeRecompensas(scale),
                  showBadge: rewardAvailable,
                  onTap: () => _navGuarded(const DailyRewardsScreen()),
                  semanticLabel: 'Recompensas Diárias',
                ),
              ),

              // Fileira inferior superior direita — Ranking
              Positioned(
                bottom: HomeConstants.rowTopBottom(scale),
                right: HomeConstants.edgePad(scale),
                child: _HomeButton(
                  key: const Key('home_btn_ranking'),
                  path: 'assets/images/home/Ranking.png',
                  size: HomeConstants.sizeRanking(scale),
                  onTap: () => _nav(const RankingScreen()),
                  semanticLabel: 'Ranking',
                ),
              ),

              // Fileira base esquerda — Loja
              Positioned(
                bottom: HomeConstants.rowBaseBottom(scale),
                left: HomeConstants.edgePad(scale),
                child: _HomeButton(
                  key: const Key('home_btn_loja'),
                  path: 'assets/images/home/IconeLoja.png',
                  size: HomeConstants.sizeIconeLoja(scale),
                  onTap: () => _navGuarded(const ShopScreen()),
                  semanticLabel: 'Loja',
                ),
              ),

              // Fileira base direita — Como Jogar
              Positioned(
                bottom: HomeConstants.rowBaseBottom(scale),
                right: HomeConstants.edgePad(scale),
                child: _HomeButton(
                  key: const Key('home_btn_comojogar'),
                  path: 'assets/images/home/ComoJogar.png',
                  size: HomeConstants.sizeComoJogar(scale),
                  semanticLabel: 'Tutorial',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TutorialScreen()),
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
    this.semanticLabel,
  });

  final String path;
  final double size;
  final VoidCallback onTap;
  final String? semanticLabel;

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
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: GestureDetector(
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
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    widget.path,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Imagem real
              Image.asset(
                widget.path,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
              ),
            ],
          ),
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
    this.semanticLabel,
  });

  final String path;
  final double size;
  final VoidCallback onTap;
  final bool showBadge;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _HomeButton(
          path: path,
          size: size,
          onTap: onTap,
          semanticLabel: semanticLabel,
        ),
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
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.scale,
  });

  final String label;
  final VoidCallback onTap;
  final double scale;

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
          width: HomeConstants.actionButtonWidth(widget.scale),
          height: HomeConstants.actionButtonHeight(widget.scale),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8C42),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: OutlinedText(
            text: widget.label,
            style: GoogleFonts.fredoka(
              fontSize: HomeConstants.actionButtonFontSize(widget.scale),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
