# Fogos de Artifício nos Milestones

**Data:** 2026-05-19
**Status:** Aprovado
**Fase:** 5 — Arte adicional e polimento visual

## Objetivo

Adicionar animação de confetes coloridos ao `MilestoneRankingDialog` para celebrar quando o jogador atinge os milestones de 2048, 4096 e 8192. Os confetes aparecem toda vez que o dialog é exibido.

## Escopo

- **Arquivo alterado:** `lib/presentation/widgets/milestone_ranking_dialog.dart`
- **Arquivo de config:** `pubspec.yaml` (nova dependência)
- **Sem alterações em:** lógica de milestones, `game_notifier.dart`, `post_game_controller.dart`, conteúdo do dialog

## Dependência

```yaml
# pubspec.yaml
confetti: ^0.7.0
```

## Arquitetura

`MilestoneRankingDialog` é convertido de `StatelessWidget` para `StatefulWidget`. O método `build` retorna um `Stack` com:

1. O `Dialog` existente (conteúdo inalterado)
2. `ConfettiWidget` posicionado em `Alignment.topCenter`, disparando para baixo sobre o dialog

```
Stack(
  alignment: Alignment.topCenter,
  children: [
    Dialog(...),          // sem mudanças internas
    ConfettiWidget(...),  // novo — sobre o dialog
  ],
)
```

## Implementação

### State

```dart
class _MilestoneRankingDialogState extends State<MilestoneRankingDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
}
```

### ConfettiWidget

```dart
ConfettiWidget(
  confettiController: _confettiController,
  blastDirection: pi / 2,       // para baixo
  maxBlastForce: 20,
  minBlastForce: 8,
  emissionFrequency: 0.05,
  numberOfParticles: 20,
  gravity: 0.05,
  colors: _confettiColors(),
)
```

### Cores por milestone

| Milestone | Animal | Cores |
|---|---|---|
| 11 (2048) | Capivara Lendária | `AppColors.primary` (verde) + dourado `Color(0xFFFFD700)` |
| 12 (4096) | Peixe-boi | azul `Colors.blue` + ciano `Colors.cyan` |
| 13 (8192) | Jacaré | laranja `Colors.orange` + amarelo `Colors.yellow` |

```dart
List<Color> _confettiColors() => switch (widget.summary.milestone) {
  11 => [AppColors.primary, const Color(0xFFFFD700), Colors.white],
  12 => [Colors.blue, Colors.cyan, Colors.lightBlue],
  13 => [Colors.orange, Colors.yellow, Colors.amber],
  _  => [AppColors.primary, Colors.yellow, Colors.white],
};
```

## Comportamento

- Confetes disparam automaticamente ao abrir o dialog (`initState` → `play()`)
- Duração: 4 segundos, depois param sozinhos
- O jogador pode fechar o dialog antes dos 4s — `dispose()` limpa o controller
- Sem botão para parar/reiniciar confetes
- Disparam **toda vez** que o dialog abre (não só na primeira vez)

## Critérios de sucesso

- [ ] Confetes aparecem visualmente sobre o `MilestoneRankingDialog`
- [ ] Cores diferentes para cada milestone
- [ ] Param após ~4 segundos sem ação do usuário
- [ ] Fechar o dialog antes dos 4s não causa leak/erro
- [ ] Conteúdo do dialog (texto, botões) permanece legível e interativo
- [ ] Sem regressões no comportamento de dismiss/ranking
