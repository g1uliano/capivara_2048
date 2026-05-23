# Design: Cheat Menu — "Ir para Nível" Orgânico

**Data:** 2026-05-23
**Arquivo alvo:** `lib/presentation/controllers/game_notifier.dart`
**Método:** `debugJumpToLevel(int targetLevel)`

## Problema

O comportamento atual coloca um tile do próprio nível alvo no tabuleiro e seta `maxLevel: targetLevel`, fazendo o jogo considerar o milestone já atingido. Isso impede testar o fluxo de milestone de forma orgânica.

## Comportamento Desejado

Ao selecionar "Ir para Nível N", o tabuleiro é configurado com dois tiles adjacentes de nível `N-1`, permitindo que o jogador os junte para atingir N naturalmente e disparar o fluxo de milestone completo.

## Board Layout

```
[ _    _    N-1  N-1 ]   linha 0 — par de merge adjacente (swipe direita)
[ _    _    _    N-2 ]   linha 1
[ N-4  _    N-3  _   ]   linha 2
[ 1    _    1    _   ]   linha 3
```

- Todos os deltas clampados em `max(1, targetLevel - delta)`.
- Tiles distribuídos de forma realista mas sem aglomerar.

## Estado do Jogo

| Campo | Valor |
|---|---|
| `maxLevel` | `targetLevel - 1` |
| `_populateMilestonesFromMaxLevel` | chamado com `targetLevel - 1` |
| `_handleMilestoneReached` | **não chamado** para `targetLevel` |
| `hasWon` | `false` |
| `score` | soma dos valores de todos os tiles |

## Edge Case

`targetLevel = 1`: ambos os tiles ficam em nível `max(1, 0) = 1` (valor 2). `maxLevel: 1`. Semanticamente não faz sentido saltar para nível 1, mas é aceitável para debug — o board fica com dois 2s adjacentes.

## Escopo

Mudança cirúrgica no corpo de `debugJumpToLevel`. Nenhum novo arquivo, nenhuma nova abstração.
