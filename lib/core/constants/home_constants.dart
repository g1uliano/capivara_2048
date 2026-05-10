/// Constantes de layout da HomeScreen.
/// Recebe um `scale` pré-calculado pelo widget:
///   scale = min(screenW / 390, screenH / 844).clamp(0.1, 1.0)
/// Equivalente ao `vmin` do CSS — escala pelo lado mais restrito.
class HomeConstants {
  HomeConstants._();

  // ─── Tamanho base ────────────────────────────────────────────────────────
  /// Widget size padrão dos botões da Home. Todos os 6 botões usam o mesmo
  /// tamanho para garantir alinhamento visual entre as duas colunas.
  /// (Os PNGs têm proporções internas diferentes — texto vs círculo —
  /// mas isso é uma característica dos próprios assets, não do layout.)
  static double buttonSize(double scale) => (110.0 * scale).clamp(70.0, 110.0);

  // ─── Tamanhos individuais por botão ─────────────────────────────────────
  static double sizeColecao(double scale) => buttonSize(scale);

  // Configuracao.png tem ~9.5% de espaço transparente no topo (79/829px) e
  // conteúdo visível de apenas 80.6% da altura do canvas — vs 99.4% do Colecao.
  // Factor 1.233 = 0.994 / 0.806 faz o círculo visual ter o mesmo tamanho.
  static double sizeConfiguracao(double scale) =>
      (buttonSize(scale) * 1.233).clamp(86.3, 135.6);

  static double sizeRanking(double scale) => buttonSize(scale);
  static double sizeRecompensas(double scale) => buttonSize(scale);
  static double sizeComoJogar(double scale) => buttonSize(scale);
  static double sizeIconeLoja(double scale) => buttonSize(scale);

  /// Padding das bordas esquerda/direita/topo para os Positioned.
  static double edgePad(double scale) => (12.0 * scale).clamp(6.0, 12.0);

  /// Top offset para Configuracao — compensa a área transparente no topo do PNG
  /// (79/829 ≈ 9.53%) para alinhar o círculo visível com o de Coleção.
  static double topConfiguracao(double scale) =>
      (edgePad(scale) - sizeConfiguracao(scale) * (79.0 / 829.0)).clamp(
        0.0,
        edgePad(scale),
      );

  /// bottom dos botões da fileira superior (Recompensas / Ranking).
  static double rowTopBottom(double scale) =>
      (148.0 * scale).clamp(80.0, 148.0);

  /// bottom dos botões da fileira base (Loja / ComoJogar).
  static double rowBaseBottom(double scale) => (24.0 * scale).clamp(12.0, 24.0);

  /// Altura do GameTitleImage na HomeScreen.
  static double titleHeight(double scale) =>
      (200.0 * scale).clamp(110.0, 200.0);

  /// Espaço vertical entre o GameTitleImage e os _ActionButtons.
  static double titleActionGap(double scale) =>
      (32.0 * scale).clamp(10.0, 32.0);

  /// Alinhamento vertical do grupo logo+botões (Align.y). Negativo = sobe.
  /// Fração relativa — escala naturalmente com a tela, valor fixo.
  static const double centerAlignY = -0.30;

  /// Largura dos botões de ação centrais ("Novo jogo" / "Continuar Jogo").
  static double actionButtonWidth(double scale) =>
      (260.0 * scale).clamp(200.0, 260.0);

  /// Altura dos botões de ação centrais.
  static double actionButtonHeight(double scale) =>
      (52.0 * scale).clamp(44.0, 52.0);

  /// Tamanho da fonte dos botões de ação centrais.
  static double actionButtonFontSize(double scale) =>
      (18.0 * scale).clamp(14.0, 18.0);
}
