# CLAUDE.md — Capivara 2048

## Projeto

Flutter puzzle game estilo 2048 com animais amazônicos. Spec completa em `CAPIVARA_2048_DESIGN.md`.

## Stack

- Flutter 3.x / Dart
- Riverpod (estado)
- Hive + SharedPreferences (persistência)
- audioplayers (áudio)
- flutter_animate (animações)

## Estrutura de pastas

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/     # cores, tamanhos, durações
│   ├── theme/         # tema cartoon fofo
│   └── utils/
├── data/
│   ├── models/        # Animal, Tile, GameState, DailyChallenge
│   ├── repositories/  # persistência local
│   └── animals_data.dart
├── domain/
│   ├── game_engine/   # lógica pura 2048 — testável sem Flutter
│   └── daily_challenge/
└── presentation/
    ├── screens/       # home, game, collection, daily, settings
    ├── widgets/       # board, tile, score_panel, animal_card
    └── controllers/   # Riverpod notifiers
```

## Regras de desenvolvimento

- **Game engine** (`domain/game_engine/`) deve ser puro Dart, zero dependência de Flutter — facilita testes unitários
- Testes unitários obrigatórios para toda lógica do game engine
- Usar `const` onde possível; minimizar rebuilds com Riverpod selectors
- Imagens pré-carregadas com `precacheImage` no startup
- Pool de AudioPlayers para sons (evitar latência)
- Acessibilidade: usar `Semantics`, contraste WCAG AA mínimo

## Convenções

- Nomes em inglês no código; strings exibidas ao usuário via `intl` (PT-BR e EN)
- Models imutáveis com `copyWith`
- IDs de tiles como UUID para controle de animações

## Fases do roadmap

Sempre confirmar em qual fase estamos antes de implementar. Fase atual: **Fase 2.3.12 concluída (v0.8.1) — próximo: Fase 2.4 (áudio)**.

| Fase | Foco |
|------|------|
| 1 | Setup, game engine puro, tela básica com placeholders |
| 2 | Identidade visual, paleta, tipografia, animações |
| 3 | Arte final dos 11 animais |
| 4 | Áudio e música |
| 5 | Coleção e Desafio Diário |
| 6 | Polimento, l10n, acessibilidade, lançamento |

## Release checklist

Sempre que lançar uma nova versão (merge + push):
1. Atualizar `CHANGELOG.md` com a versão e as mudanças
2. Atualizar `README.md` se necessário (roadmap, features, versão)
3. Atualizar `CLAUDE.md` se houver informações relevantes (convenções novas, decisões de arquitetura, bugs conhecidos, etc.)
4. Fazer merge em main e push

## Animais (referência rápida)

Níveis 1–11: Tanajura → Lobo-guará → Sapo-cururu → Tucano → **Sagui** → Preguiça → Mico-leão-dourado → Boto-cor-de-rosa → Onça-pintada → Sucuri → **Capivara Lendária (2048)**.
