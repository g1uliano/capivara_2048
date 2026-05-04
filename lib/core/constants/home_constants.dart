/// Constantes de layout da HomeScreen.
/// Breakpoint em 700dp de altura separa telas compactas (ex: 360×640)
/// das normais (ex: 390×844).
class HomeConstants {
  HomeConstants._();

  /// Tamanho (width e height) dos botões ilustrados PNG.
  static double buttonSize(double screenH) => screenH < 700 ? 90.0 : 110.0;

  /// Padding das bordas esquerda/direita/topo para os Positioned.
  static double edgePad(double screenH) => screenH < 700 ? 8.0 : 12.0;

  /// bottom dos botões da fileira superior (Recompensas / Ranking).
  static double rowTopBottom(double screenH) => screenH < 700 ? 118.0 : 148.0;

  /// bottom dos botões da fileira base (Loja / ComoJogar).
  static double rowBaseBottom(double screenH) => screenH < 700 ? 16.0 : 24.0;

  /// Altura do GameTitleImage na HomeScreen.
  static double titleHeight(double screenH) => screenH < 700 ? 130.0 : 200.0;

  /// Espaço vertical entre o GameTitleImage e os _ActionButtons.
  static double titleActionGap(double screenH) => screenH < 700 ? 16.0 : 32.0;

  /// Alinhamento vertical do grupo logo+botões (Align.y). Negativo = sobe.
  static double centerAlignY(double screenH) => screenH < 700 ? -0.5 : -0.3;

  /// Largura fixa dos botões de ação centrais ("Novo jogo" / "Continuar Jogo").
  static const double actionButtonWidth = 260.0;

  /// Altura fixa dos botões de ação centrais.
  static const double actionButtonHeight = 52.0;
}
