/// Constantes de layout da HomeScreen.
/// Recebe um `scale` pré-calculado pelo widget:
///   scale = min(screenW / 390, screenH / 844).clamp(0.1, 1.0)
/// Equivalente ao `vmin` do CSS — escala pelo lado mais restrito.
class HomeConstants {
  HomeConstants._();

  // ─── Fill ratios dos assets PNG da Home ─────────────────────────────────
  // Fração do quadrado da imagem que contém pixels visíveis (conteúdo real).
  // Medido via análise de canal alpha. Coleção é a referência visual (1.0×).
  // Cada botão é redimensionado para que o conteúdo aparente seja igual.
  static const double _fillColecao = 0.846; // referência
  static const double _fillConfiguracao = 0.805;
  static const double _fillRanking = 0.752;
  static const double _fillRecompensas = 0.929;
  static const double _fillComoJogar = 0.770;
  static const double _fillIconeLoja = 0.730;

  // ─── Tamanho base (referência = Coleção) ────────────────────────────────
  /// Widget size para o botão de Coleção — referência visual da Home.
  /// Todos os outros botões derivam deste valor × seu fator de normalização.
  static double buttonSize(double scale) => (110.0 * scale).clamp(70.0, 110.0);

  /// Normaliza o tamanho de um botão pelo fill do seu asset em relação à
  /// Coleção, garantindo que todos os ícones aparentem o mesmo tamanho visual
  /// na tela, independente das margens internas de cada PNG.
  static double buttonSizeFor(double scale, double assetFill) =>
      buttonSize(scale) * (_fillColecao / assetFill);

  // ─── Tamanhos individuais por botão ─────────────────────────────────────
  static double sizeColecao(double scale) => buttonSize(scale); // referência
  static double sizeConfiguracao(double scale) =>
      buttonSizeFor(scale, _fillConfiguracao);
  static double sizeRanking(double scale) => buttonSizeFor(scale, _fillRanking);
  static double sizeRecompensas(double scale) =>
      buttonSizeFor(scale, _fillRecompensas);
  static double sizeComoJogar(double scale) =>
      buttonSizeFor(scale, _fillComoJogar);
  static double sizeIconeLoja(double scale) =>
      buttonSizeFor(scale, _fillIconeLoja);

  /// Padding das bordas esquerda/direita/topo para os Positioned.
  static double edgePad(double scale) => (12.0 * scale).clamp(6.0, 12.0);

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
