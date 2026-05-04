/// Constantes de layout da HomeScreen.
/// Breakpoint em 700dp de altura separa telas compactas (ex: 360×640)
/// das normais (ex: 390×844).
class HomeConstants {
  HomeConstants._();

  /// Tamanho (width e height) dos botões ilustrados PNG.
  static double buttonSize(double screenH) => screenH < 700 ? 90.0 : 110.0;

  /// Padding das bordas esquerda/direita/topo para os Positioned.
  static double edgePad(double screenH) => screenH < 700 ? 6.0 : 8.0;

  /// bottom dos botões da fileira superior (Recompensas / Ranking).
  static double rowTopBottom(double screenH) => screenH < 700 ? 96.0 : 120.0;

  /// bottom dos botões da fileira base (Loja / ComoJogar).
  static double rowBaseBottom(double screenH) => screenH < 700 ? 4.0 : 8.0;

  /// Espaço vertical entre o GameTitleImage e os _ActionButtons.
  static double titleActionGap(double screenH) => screenH < 700 ? 20.0 : 32.0;

  /// Largura fixa dos botões de ação centrais ("Novo jogo" / "Continuar Jogo").
  static const double actionButtonWidth = 260.0;

  /// Altura fixa dos botões de ação centrais.
  static const double actionButtonHeight = 52.0;
}
