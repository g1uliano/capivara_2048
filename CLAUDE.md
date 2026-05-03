# CLAUDE.md — Capivara 2048 (codinome)

## Projeto

"Olha o Bixim!" é um Flutter puzzle game estilo 2048 com animais amazônicos. Spec completa em `CAPIVARA_2048_DESIGN.md` (design doc) - ele pode conter pequenos erros em relação a questões técnicas e de implementação, pois, ele é uma spec geral e um esboço do que tem que ser ou foi implementado, por isso, sempre confira o repositório a procura de arquivos, pastas e pra ter certeza cheque o código e outras specs).

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

Sempre confirmar em qual fase estamos antes de implementar. Fase atual: **Fase 2.11 em andamento (v1.0.x) — próximo: concluir 2.11 → Fase 3**. O áudio foi reposicionado para a **Fase 5** (antes do lançamento) — o jogo é desenvolvido sem áudio até lá.

| Fase | Foco |
|------|------|
| 1 | Setup, game engine puro, tela básica com placeholders |
| 2 | Identidade visual, paleta, tipografia, animações, vidas, inventário, recompensas, coleção, loja mock |
| 2.5 ✅ | Rebranding "Olha o Bichim!", GameTitleImage, ícone do app, launcher name |
| 2.6 ✅ | Tela Home + Coleção + Configurações + stubs |
| 2.11 🔄 | ShopOverlay sobre o jogo acessível pelos ícones desabilitados do inventário |
| 3 | Backend, ranking, monetização |
| 4 | Arte adicional e polimento visual (logo, ícone, splash final) |
| 5 | Áudio (sound design dos 11 animais, SFX, música) |
| 6 | Polimento, l10n, acessibilidade, lançamento |

## Release checklist

Sempre que lançar uma nova versão (merge + push):
1. Atualizar `CHANGELOG.md` com a versão e as mudanças
2. Atualizar `README.md` se necessário (roadmap, features, versão)
3. Atualizar `CLAUDE.md` se houver informações relevantes (convenções novas, decisões de arquitetura, bugs conhecidos, etc.)
4. Fazer merge em main e push

## Animais (referência rápida)

Níveis 1–11: Tanajura → Lobo-guará → Sapo-cururu → Tucano → **Sagui** → Preguiça → Mico-leão-dourado → Boto-cor-de-rosa → Onça-pintada → Sucuri → **Capivara Lendária (2048)**.

Diretrizes comportamentais para reduzir erros comuns de LLMs. Mesclar com as instruções específicas do projeto conforme necessário.

**Trade-off:** Estas diretrizes priorizam cautela em vez de velocidade. Para tarefas triviais, use o bom senso.

## 1. Pense Antes de Codar

**Não assuma. Não esconda confusão. Exponha trade-offs.**

Antes de implementar:
- Declare suas suposições explicitamente. Se incerto, pergunte.
- Se houver múltiplas interpretações, apresente-as — não escolha silenciosamente.
- Se existir uma abordagem mais simples, diga. Questione quando justificado.
- Se algo estiver obscuro, pare. Nomeie o que está confuso. Pergunte.

## 2. Simplicidade Primeiro

**Código mínimo que resolve o problema. Nada especulativo.**

- Nenhuma feature além do que foi pedido.
- Nenhuma abstração para código de uso único.
- Nenhuma "flexibilidade" ou "configurabilidade" não solicitada.
- Nenhum tratamento de erros para cenários impossíveis.
- Se você escrever 200 linhas e pudesse ser 50, reescreva.

Pergunte a si mesmo: "Um engenheiro sênior diria que isso está overcomplicated?" Se sim, simplifique.

## 3. Mudanças Cirúrgicas

**Toque apenas o necessário. Limpe apenas sua própria bagunça.**

Ao editar código existente:
- Não "melhore" código adjacente, comentários ou formatação.
- Não refatore coisas que não estão quebradas.
- Siga o estilo existente, mesmo que você faria diferente.
- Se notar código morto não relacionado, mencione — não delete.

Quando suas mudanças criarem órfãos:
- Remova imports/variáveis/funções que SUAS mudanças tornaram desnecessários.
- Não remova código morto pré-existente a menos que solicitado.

O teste: cada linha alterada deve rastrear diretamente ao pedido do usuário.

## 4. Execução Orientada a Objetivos

**Defina critérios de sucesso. Itere até verificar.**

Transforme tarefas em objetivos verificáveis:
- "Adicionar validação" → "Escrever testes para entradas inválidas, depois fazê-los passar"
- "Corrigir o bug" → "Escrever um teste que o reproduza, depois fazê-lo passar"
- "Refatorar X" → "Garantir que os testes passem antes e depois"

Para tarefas de múltiplos passos, declare um plano breve:
```
1. [Passo] → verificar: [checagem]
2. [Passo] → verificar: [checagem]
3. [Passo] → verificar: [checagem]
```

Critérios de sucesso fortes permitem iterar de forma independente. Critérios fracos ("fazer funcionar") exigem clarificações constantes.

---

**Estas diretrizes estão funcionando se:** menos mudanças desnecessárias nos diffs, menos reescritas por complicação excessiva, e perguntas de clarificação vêm antes da implementação, não depois dos erros.

