/// Constantes de layout da HomeScreen.
/// Recebe um `scale` pré-calculado pelo widget:
///   scale = min(screenW / 390, screenH / 844).clamp(0.1, 1.0)
/// Equivalente ao `vmin` do CSS — escala pelo lado mais restrito.
class HomeConstants {
  HomeConstants._();

  /// Tamanho (width e height) dos botões ilustrados PNG.
  static double buttonSize(double scale) => (110.0 * scale).clamp(70.0, 110.0);

  /// Padding das bordas esquerda/direita/topo para os Positioned.
  static double edgePad(double scale) => (12.0 * scale).clamp(6.0, 12.0);

  /// bottom dos botões da fileira superior (Recompensas / Ranking).
  static double rowTopBottom(double scale) => (148.0 * scale).clamp(80.0, 148.0);

  /// bottom dos botões da fileira base (Loja / ComoJogar).
  static double rowBaseBottom(double scale) => (24.0 * scale).clamp(12.0, 24.0);

  /// Altura do GameTitleImage na HomeScreen.
  static double titleHeight(double scale) => (200.0 * scale).clamp(110.0, 200.0);

  /// Espaço vertical entre o GameTitleImage e os _ActionButtons.
  static double titleActionGap(double scale) => (32.0 * scale).clamp(10.0, 32.0);

  /// Alinhamento vertical do grupo logo+botões (Align.y). Negativo = sobe.
  /// Fração relativa — escala naturalmente com a tela, valor fixo.
  static const double centerAlignY = -0.30;

  /// Largura dos botões de ação centrais ("Novo jogo" / "Continuar Jogo").
  static double actionButtonWidth(double scale) => (260.0 * scale).clamp(200.0, 260.0);

  /// Altura dos botões de ação centrais.
  static double actionButtonHeight(double scale) => (52.0 * scale).clamp(44.0, 52.0);

  /// Tamanho da fonte dos botões de ação centrais.
  static double actionButtonFontSize(double scale) => (18.0 * scale).clamp(14.0, 18.0);
}
