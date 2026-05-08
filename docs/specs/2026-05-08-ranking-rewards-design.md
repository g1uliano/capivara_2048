# Design — Ranking Global, Recompensas e Auditoria de Flavors

**Data:** 2026-05-08  
**Status:** Aprovado — aguardando implementação  
**Fase:** 4.3

---

## 1. Escopo

Este documento especifica as seguintes features:

| # | Feature | Situação |
|---|---------|----------|
| 1 | Editar nome na tela de Perfil | **Já implementado** (ficou oculto pelo bug de cold start — corrigido em f4a3900) |
| 2 | Aba Global no Ranking (3 tabs: Pessoal · Global · Lendas) | Novo |
| 3 | Dialogs pós-milestone (2048 → posição global; 4096 → tempo; 8192 → contagem) | Novo |
| 4 | Recompensa por recorde pessoal (novo melhor tempo em 2048 ou novo tile máximo) | Novo |
| 5 | Recompensa por convite (convidador recebe 1 combo quando convidado joga 1ª partida) | Atualização |
| 6 | Tabela de prêmios do ranking semanal — valores revisados | Atualização |
| 7 | Auditoria de flavors — Fake* exclusivo para `tst` | Correção transversal |

---

## 2. Mudanças de dados e domínio

### 2.1 `PersonalRecords` — novo campo

```dart
final int bestTimeMs2048; // 0 = nunca atingiu 2048
```

Necessário para detectar "novo recorde de tempo" (critério A das recompensas pessoais). Os demais campos existentes (`highestLevelEver`, `rewardCollected4096`, `rewardCollected8192`) cobrem o "novo tile máximo" (critério B).

O `PersonalRecordsHiveAdapter` recebe um novo índice para `bestTimeMs2048`. Compatível com dados existentes: retorna `0` se o campo ainda não existia.

### 2.2 `WeeklyRewardResult.forPosition()` — nova tabela

| Posição | Vidas | Desfazer | Bomba3 |
|---------|-------|----------|--------|
| 1º      | 10    | 10       | 10     |
| 2º      | 5     | 5        | 5      |
| 3º      | 3     | 3        | 3      |
| 4º–6º   | 3     | —        | 3      |
| 7º–9º   | 3     | 3        | —      |
| 10º     | 3     | —        | —      |
| 11º+    | sem recompensa | | |

Obs: `bomb2` deixa de ser utilizado nestas recompensas. O modelo `WeeklyRewardResult` mantém o campo (pode ser usado em outros contextos futuros), mas `forPosition()` não o atribui.

### 2.3 Invite reward — convidador

O método `completeInviteReward` (chamado quando o convidado joga sua 1ª partida) deve entregar ao **convidador** 1 combo: `InventoryRepository.add(bomb3: 1, undo1: 1)` + `LivesRepository.add(lives: 1)`. Verificar se o `FirestoreInviteRepository` já faz essa entrega; se não faz, adicionar. A entrega para o **convidado** (já existente) permanece inalterada.

### 2.4 Ranking Global — critério único

- **Critério principal:** menor tempo para formar o tile 2048 (ms), ascendente
- **Desempate:** maior tile atingido na mesma partida, descendente
- **Elegibilidade:** apenas partidas em que o jogador atingiu 2048
- **Período:** semanal, reinício todo sábado às 18h BRT (21h UTC) — `WeekId` já implementado
- A infraestrutura Firestore (`rankings/{weekId}/globalTime`) e a submissão de score (`game_notifier.dart`) já existem. A mudança é adicionar `maxTile` como campo secundário no documento submetido e usá-lo na query de ordenação.

---

## 3. `PostGameController`

**Localização:** `lib/presentation/controllers/post_game_controller.dart`

### 3.1 Tipo de estado emitido

```dart
class PostGameSummary {
  final int milestone;         // 11 = 2048, 12 = 4096, 13 = 8192
  final int? rankingPosition;  // só milestone 11, null se não logado ou erro
  final int timeMs;            // tempo até o milestone (para 2048 e 4096)
  final int timesReached8192;  // só milestone 13
  final bool earnedCombo;      // true se recompensa de recorde pessoal foi concedida
}
```

### 3.2 Fluxo ao detectar milestone

O `PostGameController` observa `gameNotifierProvider`. Ao detectar `pendingMilestone != null` (transição de null → valor):

1. **Lê** `PersonalRecords` atual e o estado do jogo (tempo, tile máximo)
2. **Detecta recorde pessoal:**
   - Critério A: `timeMs < records.bestTimeMs2048` (ou `bestTimeMs2048 == 0`) — novo melhor tempo
   - Critério B: `state.maxLevel > records.highestLevelEver` — novo tile máximo
3. **Se houver recorde:** concede combo via repositórios existentes e atualiza `PersonalRecords.bestTimeMs2048` se aplicável
4. **Para milestone 11 (2048) + usuário logado:** consulta Firestore para posição atual no ranking semanal (async, com timeout de 5s)
5. **Emite `PostGameSummary`** para a UI

### 3.3 Concessão do combo

```
InventoryRepository.add(bomb3: 1, undo1: 1)
LivesRepository.add(lives: 1)
```

Esses repositórios já existem. A chamada é fire-and-forget com catch silencioso (nunca bloqueia o jogo).

### 3.4 Ciclo de vida

- `build()` → `null`
- `GameScreen` observa via `ref.listen`; quando não-null exibe o dialog
- Após dismiss do dialog: `controller.dismiss()` → volta a `null`
- Em `signOut` ou nova partida: estado resetado automaticamente pelo Riverpod (notifier reconstruído)

### 3.5 Edge cases

| Situação | Comportamento |
|----------|--------------|
| Firestore timeout / sem conexão | `rankingPosition = null`; dialog exibe "posição indisponível" |
| Jogador não logado | `rankingPosition = null`; dialog não mostra posição |
| Múltiplos milestones rápidos | `_reachedMilestones` do `game_notifier` já garante um milestone por vez; controller só reage a transições de null → valor |
| Recompensa falha silenciosamente | Estado local do `earnedCombo` permanece `true`; UI mostra a notificação; a concessão é retentada via `pendingEvents` se disponível |

---

## 4. UI

### 4.1 `RankingScreen` — 3 tabs

```
AppBar: "Ranking"
TabBar: [ Pessoal ]  [ Global ]  [ Lendas ]
```

- **Pessoal:** sem alteração
- **Global (novo):** lista dos top-50 da semana atual ordenados por tempo (MM:SS). Linha do jogador logado destacada com fundo levemente colorido. Se o jogador não atingiu 2048 na semana: mensagem "Forme o 2048 para entrar no ranking desta semana" abaixo da lista. Contador de tempo restante para reinício (já existe na tela — manter padrão).
- **Lendas:** sem alteração

### 4.2 `MilestoneRankingDialog` — novo widget

Reutiliza o estilo do `WeeklyRewardModal` (Dialog branco, borda arredondada, botão "Continuar").

**Variação 2048:**
```
🏆 Ranking Global
Você está em 3º lugar!
Tempo: 04:37
─────────────────
🎁 +1 vida  +1 bomba  +1 desfazer   ← só se earnedCombo
[ Ver Ranking ]    [ Continuar ]
```

"Ver Ranking" fecha o dialog e navega para `RankingScreen` abrindo diretamente na aba Global.

**Variação 4096:**
```
🌊 Peixe-boi atingido!
Seu tempo: 12:14
─────────────────
🎁 +1 vida  +1 bomba  +1 desfazer   ← só se earnedCombo
[ Continuar ]
```

**Variação 8192:**
```
🐊 Jacaré atingido!
Você chegou aqui 3 vezes!
─────────────────
🎁 +1 vida  +1 bomba  +1 desfazer   ← só se earnedCombo
[ Continuar ]
```

Quando `rankingPosition == null` (offline/não logado), a linha de posição é omitida na variação 2048.

### 4.3 Gatilho na `GameScreen`

```dart
ref.listen(postGameControllerProvider, (_, summary) {
  if (summary != null) {
    MilestoneRankingDialog.show(context, summary).then((_) {
      ref.read(postGameControllerProvider.notifier).dismiss();
    });
  }
});
```

---

## 5. Auditoria de flavors

### Regra unificada

```dart
// ANTES (padrão inconsistente — mocks em dev e tst juntos)
if (flavor == 'prd') return RealService();
return FakeService();

// DEPOIS (correto)
if (flavor == 'tst') return FakeService();
return RealService(); // prd e dev usam serviços reais
```

### Providers a auditar

| Provider | Ação |
|----------|------|
| `authServiceProvider` | verificar; garantir real em dev |
| `syncEngineProvider` | já correto (dev usa `FirebaseSyncEngine`) ✅ |
| `rankingRepositoryProvider` | verificar; garantir real em dev |
| `inviteServiceProvider` | verificar; garantir real em dev |
| `iapServiceProvider` | dev → implementação real com conta sandbox Play Store; `tst` → Fake |
| `iapStartupServiceProvider` | idem IAP |
| `adsServiceProvider` | dev → implementação real com test ad unit IDs; `tst` → Fake |

### Impacto no `README.md`

A tabela de builds deve ser atualizada para refletir que `dev` usa serviços reais (Firebase/Firestore/Ads com IDs de teste):

| Comando | Flavor | Serviços | Uso |
|---------|--------|----------|-----|
| `flutter run --dart-define=FLAVOR=dev` | dev | Reais (sandbox) | Desenvolvimento local com Firebase dev |
| `flutter build apk --dart-define=FLAVOR=tst` | tst | Fake | QA — testes sem Firebase |
| `flutter build apk --dart-define=FLAVOR=prd` | prd | Reais (produção) | Release |

---

## 6. Tratamento de erros

| Cenário | Comportamento |
|---------|--------------|
| Firestore indisponível ao submeter score | já tratado em `game_notifier` (fire-and-forget + catch) |
| Firestore indisponível ao consultar posição | `rankingPosition = null`, dialog omite linha de posição |
| Concessão de combo falha | log silencioso; `earnedCombo` continua `true` para UI; item não é entregue (não há retry automático — aceitável dado o valor baixo) |
| Invite reward falha | já tratado com catch silencioso no `completeInviteReward` |
| Hive indisponível ao salvar `bestTimeMs2048` | catch silencioso; recorde não é salvo; jogador não recebe recompensa nessa partida |

---

## 7. Testes

### Unitários obrigatórios

- `PostGameController`: detecta recorde A (tempo), detecta recorde B (tile), não detecta falso recorde, concede combo, emite `PostGameSummary` correto para cada milestone
- `PersonalRecords`: serialização/deserialização com novo campo `bestTimeMs2048`; compatibilidade retroativa (campo ausente → 0)
- `WeeklyRewardResult.forPosition()`: cada posição 1–10 retorna valores corretos; posição 11+ retorna sem recompensa

### Widget tests obrigatórios

- `MilestoneRankingDialog`: renderiza corretamente para milestone 11 com e sem posição, milestone 12, milestone 13, com e sem `earnedCombo`
- `RankingScreen`: exibe 3 tabs; aba Global renderiza lista e estado "sem dados"

### Testes a atualizar

- `auth_controller_test.dart`: nenhuma mudança esperada
- Testes de `ranking_screen` existentes: adicionar cobertura da aba Global

---

## 8. README — atualizações necessárias

1. **Tabela de builds:** corrigir coluna "Serviços" para refletir que `dev` usa Firebase real (ver Seção 5)
2. **Roadmap:** adicionar Fase 4.3 com as features deste documento após Fase 4.2 ✅
3. **Features:** adicionar "Ranking Global semanal" e "Recompensas por recorde pessoal e convite" na lista de features

---

## 9. Fora do escopo deste documento

- Áudio (Fase 6)
- Arte adicional / polimento visual (Fase 5)
- Apple Sign-In (não implementado, mantido como stub)
- Modo escuro
