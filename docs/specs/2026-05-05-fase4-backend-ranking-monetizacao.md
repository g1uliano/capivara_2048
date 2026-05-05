# Spec — Fase 4: Backend, Ranking e Monetização

**Data:** 2026-05-05  
**Versão alvo:** v1.4.x  
**Status:** Aprovado — aguardando plano de implementação  
**Pré-requisito:** Seguir o guia [`FIREBASE.md`](../../FIREBASE.md) antes de iniciar Sub-A.

---

## Índice

1. [Visão geral](#1-visão-geral)
2. [Decisões de design](#2-decisões-de-design)
3. [Arquitetura geral + Sync Engine](#3-arquitetura-geral--sync-engine)
4. [Sub-A — Firebase + Auth + PlayerProfile](#4-sub-a--firebase--auth--playerprofile)
5. [Sub-B — Ranking Global Semanal](#5-sub-b--ranking-global-semanal)
6. [Sub-C — Ranking Lendas](#6-sub-c--ranking-lendas)
7. [Sub-D — Sistema de Convites](#7-sub-d--sistema-de-convites)
8. [Sub-E — Anúncios Reais](#8-sub-e--anúncios-reais)
9. [Sub-F — IAP Real](#9-sub-f--iap-real)
10. [Modelo de dados Firestore completo](#10-modelo-de-dados-firestore-completo)
11. [Estratégia de testes](#11-estratégia-de-testes)
12. [Critérios de aceite](#12-critérios-de-aceite)
13. [Prompt de brainstorm — Fase 5](#13-prompt-de-brainstorm--fase-5)

---

## 1. Visão geral

A Fase 4 conecta o jogo à infraestrutura remota, habilitando ranking global real, persistência multi-device, monetização via IAP e anúncios reais. É a fase que transforma o jogo de uma experiência local em um produto publicável.

**Sub-entregas:**

| ID | Nome | Dependências |
|---|---|---|
| A | Firebase + Auth + PlayerProfile + Sync Engine | — |
| B | Ranking Global Semanal | A |
| C | Ranking Lendas persistido | A |
| D | Sistema de Convites | A |
| E | Anúncios Reais (Google Mobile Ads) | — |
| F | IAP Real (in_app_purchase) | A |

---

## 2. Decisões de design

| Ponto aberto | Decisão | Justificativa |
|---|---|---|
| Reset semanal | Client-side com timestamp check (`weekId` ISO 8601 determinístico) | Lançamento Brasil-only; Cloud Function desnecessária nesta escala; pode ser adicionada futuramente sem retrabalho |
| Login anônimo | **Conta obrigatória** para loja, ranking, diária e inventário persistido. Sem fluxo anônimo → autenticado | Simplifica arquitetura; sem estado relevante a preservar sem conta |
| Merge multi-device | Opção 2: **Sync Engine** com Hive como cache local e Firestore como fonte da verdade | Suporte real a multi-device; inventário/vidas sincronizados entre devices do mesmo usuário |
| Account collision | Login na conta existente + merge silencioso "best value" campo a campo | Preserva conquistas legítimas; sem tela extra |
| IAP UX | **Bottom sheet de confirmação no app** antes de chamar a IAP do SO | Evita chargebacks; mostra conteúdo completo do pacote antes do commit |
| Lendas offline | **Otimista local**: evento salvo no Hive, sync via `drainPendingEvents()` ao reconectar | Conquistas raras não podem ser perdidas por falta de sinal |
| Login location | **ProfileScreen** dedicada, acessível via ícone de avatar na HomeScreen | Padrão de jogos F2P (Clash Royale); mais visível que Settings |

---

## 3. Arquitetura geral + Sync Engine

### Camadas

```
Presentation / Riverpod Notifiers
        │
        ▼
  [ Domain Layer ]          ← Dart puro, sem Flutter, sem Firebase
  RankingRepository (abstract)
  AdService (abstract)
  IAPService (abstract)
  AuthService (abstract)
  SyncEngine (abstract)
        │
        ▼
  [ Data Layer — Firebase ]
  FirestoreRankingRepository
  GoogleMobileAdsService
  IAPServiceImpl
  FirebaseAuthService
  FirebaseSyncEngine
        │
  ┌─────┴──────┐
  ▼            ▼
 Hive       Firestore
(cache      (fonte da
 local,      verdade,
 offline)    multi-device)
```

### Providers Riverpod

```dart
// Flavor dev → Fake; flavor prd → Firebase
syncEngineProvider        → FirebaseSyncEngine   | FakeSyncEngine
authServiceProvider       → FirebaseAuthService  | FakeAuthService
rankingRepositoryProvider → FirestoreRankingRepository | FakeRankingService (existente)
adServiceProvider         → GoogleMobileAdsService | FakeAdService (existente)
iapServiceProvider        → IAPServiceImpl       | FakeIAPService
```

Os testes da Fase 3 continuam funcionando sem modificação — todos usam os Fakes via injeção de providers.

### Sync Engine — responsabilidades

**`FirebaseSyncEngine`** tem três responsabilidades independentes:

#### 1. Snapshot listener
Ao fazer login, abre `StreamSubscription` em `users/{userId}`. Mudanças remotas (outro device) disparam merge no Hive local. Riverpod notifiers reagem via `watch` no Hive.

#### 2. Write queue (offline-first)
Todo write local é aplicado no Hive imediatamente (otimista) e enfileirado em `pendingWrites` (Box Hive). Quando há conexão, o engine drena a fila para o Firestore. Writes pendentes sobrevivem ao fechamento do app.

#### 3. Conflict resolution por tipo de campo

| Campo | Estratégia |
|---|---|
| `bestTimeMs` | `min(local, remote)` |
| `bestNumber`, `timesReached4096/8192` | `max(local, remote)` |
| `firstReached4096/8192At` | timestamp mais antigo vence |
| `inventory` (contadores de itens) | Firestore fonte da verdade; consumo via **transação atômica**; se saldo insuficiente no Firestore → zera e notifica |
| `lives` | Último write válido (timestamp); sem sync em tempo real — vidas são por sessão |
| `highestLevelEver` | `max(local, remote)` |
| `displayName`, `avatarUrl` | Remote sempre vence (vem do Google/Apple) |

#### Interface

```dart
abstract class SyncEngine {
  Future<void> init(String userId);
  Future<void> dispose();
  Future<void> syncProfile();
  Future<void> drainPendingEvents();
  Stream<SyncStatus> get statusStream;
}
```

---

## 4. Sub-A — Firebase + Auth + PlayerProfile

### Provedores de autenticação

| Provedor | Plataforma | Observação |
|---|---|---|
| Google Sign-In | Android + iOS | Principal |
| Apple Sign-In | iOS apenas | Obrigatório pela App Store |
| Email/senha | Android + iOS | Fallback |

### Fluxo de onboarding

```
Primeiro launch
      │
      ▼
SplashScreen (existente)
      │
      ▼
OnboardingAuthScreen (nova)   ← apenas no primeiro launch
  [Entrar com Google]
  [Entrar com Apple]  (iOS only)
  [Entrar com Email]
  [Jogar sem conta →]  (acesso limitado)
      │ login bem-sucedido
      ▼
HomeScreen
```

Lançamentos subsequentes: `authStateChanges` logado → pula `OnboardingAuthScreen`.

**"Jogar sem conta":** leva à HomeScreen com `AuthBanner` persistente. Ranking, loja, diária e inventário desabilitados com CTA inline de login.

### ProfileScreen (nova)

Acessível via ícone de avatar no canto superior da HomeScreen.

- **Logado:** avatar, displayName, PersonalRecords resumidos, histórico de compras, botão "Restaurar compras", botão "Sair"
- **Não logado:** CTA de login com botões Google/Apple/Email

### PlayerProfile — novo model

```dart
class PlayerProfile {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? email;
  final AuthProvider provider; // google | apple | email
  final DateTime createdAt;
  final DateTime lastSeenAt;
}
```

Armazenado em `users/{userId}` no Firestore e em cache no Hive (box `playerProfile`).

### Account collision

Usuário tenta login com credencial Google que já existe (usado em outro device):
1. Firebase retorna sucesso — é o mesmo UID
2. `SyncEngine` detecta divergência Hive/Firestore
3. Merge silencioso "best value" (Seção 3)
4. Nenhuma tela extra necessária

### Logout

- Hive **não** é apagado ao fazer logout (cache preservado para uso offline)
- Re-login do mesmo usuário: merge reconcilia local com remoto
- Login de usuário diferente no mesmo device: Hive limpo antes de popular novo perfil

### Arquivos afetados — Sub-A

| Arquivo | Ação |
|---|---|
| `pubspec.yaml` | Adicionar dependências Firebase (ver abaixo) |
| `lib/main.dart` | `await Firebase.initializeApp()` |
| `lib/app.dart` | Rota inicial: `OnboardingAuthScreen` vs `HomeScreen` |
| `lib/data/models/player_profile.dart` | **Novo** |
| `lib/domain/auth/auth_service.dart` | **Novo** (abstract + FakeAuthService) |
| `lib/data/repositories/firebase_auth_service.dart` | **Novo** |
| `lib/domain/sync/sync_engine.dart` | **Novo** (abstract + FakeSyncEngine) |
| `lib/data/repositories/firebase_sync_engine.dart` | **Novo** |
| `lib/data/models/pending_event.dart` | **Novo** |
| `lib/presentation/screens/onboarding_auth_screen.dart` | **Novo** |
| `lib/presentation/screens/profile_screen.dart` | **Novo** |
| `lib/presentation/widgets/auth_banner.dart` | **Novo** |
| `lib/presentation/controllers/auth_controller.dart` | **Novo** (Riverpod notifier) |
| `lib/presentation/screens/home_screen.dart` | Adicionar ícone de avatar no header |

### Dependências novas

```yaml
firebase_core: ^3.x
firebase_auth: ^5.x
cloud_firestore: ^5.x
google_sign_in: ^6.x
sign_in_with_apple: ^6.x
connectivity_plus: ^6.x
```

---

## 5. Sub-B — Ranking Global Semanal

### weekId determinístico

`weekId` = semana ISO 8601 (`"2025-W19"`). Calculado client-side deterministicamente — qualquer device com mesmo horário produz o mesmo `weekId`.

**Reset:** sábado 21h UTC (= sábado 18h BRT). O client compara `DateTime.now().toUtc()` com o sábado 21h UTC da semana corrente.

### Fluxo ao abrir o app

```
app launch → AuthController verifica login
    │ logado
    ▼
SyncEngine.checkWeeklyReset()
    ├── Busca rankings/{currentWeekId}/meta
    ├── Se endsAt < now E rewardsDistributed == false:
    │     ├── Lê entry do jogador na semana encerrada
    │     ├── Calcula recompensa por posição
    │     ├── Entrega itens via SyncEngine (transação atômica)
    │     ├── Marca rewardsDistributed = true
    │     └── Exibe WeeklyRewardModal
    └── Segue para HomeScreen
```

**Idempotência:** flag `rewardsDistributed: true` garante entrega única mesmo com múltiplos opens.

### Tabela de recompensas

| Posição | Recompensa |
|---|---|
| 🥇 1º | 5 vidas + 3× Bomba 3 + 3× Desfazer |
| 🥈 2º | 4 vidas + 2× Bomba 3 + 2× Desfazer |
| 🥉 3º | 3 vidas + 2× Bomba 2 + 1× Desfazer |
| 4º–10º | 2 vidas + 1× Bomba 2 |
| 11º–50º | 1 vida |
| Fora do top 50 | Sem recompensa |

### Interface atualizada

```dart
abstract class RankingRepository {
  // Existentes — mantidos
  Future<List<RankingEntry>> getWeeklyTop(RankingType type);
  Future<RankingEntry?> getPlayerEntry(RankingType type);
  Future<void> submitScore(RankingType type, int value);
  // Novos
  Future<WeeklyRewardResult?> checkAndClaimWeeklyReward();
  Stream<List<RankingEntry>> watchWeeklyTop(RankingType type);
}
```

### Arquivos afetados — Sub-B

| Arquivo | Ação |
|---|---|
| `lib/domain/ranking/ranking_repository.dart` | Adicionar 2 métodos novos |
| `lib/data/repositories/fake_ranking_service.dart` | Implementar novos métodos (mock/no-op) |
| `lib/data/repositories/firestore_ranking_repository.dart` | **Novo** |
| `lib/presentation/widgets/weekly_reward_modal.dart` | **Novo** |
| `lib/presentation/controllers/ranking_controller.dart` | **Novo** (Riverpod notifier) |

---

## 6. Sub-C — Ranking Lendas

### Fluxo ao atingir 4096 ou 8192

```
game engine detecta merge → tile 4096 ou 8192
    │
    ▼
GameController.onLegendaryReached(level)
    ├── Atualiza PersonalRecords local (Hive) — imediato
    ├── Cria PendingEvent(type: legendReached, level, timestamp: now)
    └── SyncEngine.drainPendingEvents()
          ├── Online: transação Firestore
          │     ├── Incrementa legendsRankings/{level}/entries/{userId}.timesReached
          │     ├── Se firstReachedAt == null → seta com timestamp do evento
          │     ├── Atualiza users/{userId}/personalRecords
          │     └── Remove PendingEvent do Hive
          └── Offline: PendingEvent persiste no Hive → drenado no próximo launch online
```

### Desempate

Query Firestore: `orderBy('timesReached', descending: true).orderBy('firstReachedAt', descending: false)`.

### Reinstalação

Login após reinstalar → `SyncEngine` baixa `users/{userId}/personalRecords` do Firestore. `legendsRankings/{level}/entries/{userId}` nunca é apagado — vitalício.

### Arquivos afetados — Sub-C

| Arquivo | Ação |
|---|---|
| `lib/domain/game_engine/` | Emitir evento `LegendaryReached(level)` ao detectar tile 4096/8192 |
| `lib/domain/sync/sync_engine.dart` | Adicionar `drainPendingEvents()` |
| `lib/data/repositories/firebase_sync_engine.dart` | Implementar drain com transação Firestore |
| `lib/data/models/pending_event.dart` | Já criado em Sub-A |

---

## 7. Sub-D — Sistema de Convites

### Fluxo completo

```
Convidante
    ├── ProfileScreen → "Convidar Amigos" → InviteFriendsScreen
    ├── "Gerar link de convite"
    │     └── Cria invites/{inviterId} se não existir
    │         Gera deep link: olhabichim://invite?ref={inviterId}
    │         Compartilha via share_plus (já instalado)

Convidado
    ├── Instala app → abre link
    ├── app_links captura deep link no launch
    ├── OnboardingAuthScreen detecta ?ref={inviterId} → salva no Hive
    ├── Cria conta
    ├── SyncEngine registra em invites/{inviterId}/invites[] status: "pending"
    │
    └── Conclui 1ª partida
          GameController.onGameOver()
          ├── Verifica pendingInviteRef no Hive
          ├── Transação Firestore:
          │     ├── invites[n].status = "completed"
          │     ├── Entrega recompensa ao convidante (inventory write em users/{inviterId})
          │     └── Entrega recompensa ao convidado (inventory write em users/{userId})
          └── Limpa pendingInviteRef do Hive
```

### Recompensas de convite

| Quem | Recompensa |
|---|---|
| Convidante | 2 vidas + 1× Bomba 2 |
| Convidado | 2 vidas + 1× Bomba 2 |

### Regras e limites

- Máximo de **20 convites ativos** por usuário
- Convidado vinculado a **1 convidante** apenas — primeiro link clicado vence
- Link de convite não expira; recompensa gerada apenas na 1ª partida concluída
- Convidante com conta deletada: convite órfão, recompensa não entregue (edge case aceitável)

### Configuração de deep link

- **Android:** `intent-filter` com scheme `olhabichim` no `AndroidManifest.xml`
- **iOS:** URL scheme em `Info.plist` + Associated Domains para Universal Links (futuro)
- `app_links` captura em cold start e foreground

### Arquivos afetados — Sub-D

| Arquivo | Ação |
|---|---|
| `pubspec.yaml` | Adicionar `app_links: ^6.x` |
| `lib/main.dart` | Inicializar listener de deep link |
| `lib/domain/invites/invite_service.dart` | **Novo** (abstract + FakeInviteService) |
| `lib/data/repositories/firestore_invite_repository.dart` | **Novo** |
| `lib/presentation/screens/invite_friends_screen.dart` | Substituir stub por implementação real |
| `lib/presentation/controllers/invite_controller.dart` | **Novo** |
| `android/app/src/main/AndroidManifest.xml` | Adicionar `intent-filter` para deep link |
| `ios/Runner/Info.plist` | Adicionar URL scheme |

---

## 8. Sub-E — Anúncios Reais

### Substituição cirúrgica

Interface `AdService` não muda. Apenas a implementação concreta é trocada no flavor `prd`:

```dart
// lib/data/repositories/google_mobile_ads_service.dart
class GoogleMobileAdsService implements AdService {
  @override
  Future<bool> showRewardedAd() async {
    // Carrega (se não pré-carregado) e exibe rewarded ad.
    // Retorna true se o usuário assistiu até o fim.
    // Retorna false se fechou antes ou se falhou o carregamento.
  }
}
```

### Configurações obrigatórias

| Parâmetro | Valor |
|---|---|
| `tagForChildDirectedTreatment` | `true` |
| `tagForUnderAgeOfConsent` | `true` |
| `maxAdContentRating` | `G` |
| Limite diário | 40 anúncios (contador compartilhado `adWatchesToday`) |
| Ad Unit ID Android | Via `--dart-define=AD_UNIT_ANDROID=...` (não hardcoded) |
| Ad Unit ID iOS | Via `--dart-define=AD_UNIT_IOS=...` |

### Pool de anúncios

`GoogleMobileAdsService` pré-carrega o próximo anúncio imediatamente após o atual ser exibido. Se carregamento falhar: `showRewardedAd()` retorna `false` e jogador vê *"Anúncio indisponível no momento, tente em instantes"*.

### Arquivos afetados — Sub-E

| Arquivo | Ação |
|---|---|
| `pubspec.yaml` | Adicionar `google_mobile_ads: ^5.x` |
| `android/app/src/main/AndroidManifest.xml` | `<meta-data>` com App ID |
| `ios/Runner/Info.plist` | `GADApplicationIdentifier` |
| `lib/domain/daily_rewards/ad_service.dart` | Sem mudança na interface |
| `lib/data/repositories/google_mobile_ads_service.dart` | **Novo** |
| `lib/core/constants/ad_config.dart` | **Novo** (Ad Unit IDs, limite diário) |

---

## 9. Sub-F — IAP Real

### Fluxo completo de compra

```
Usuário toca "Comprar" (ShopScreen ou GameOverNoItemsOverlay)
    │
    ▼
IAPConfirmationSheet (bottom sheet)
  Exibe: nome do pacote, conteúdo completo, conteúdo do presente (ShareCode), preço
  [Confirmar — R$ X,XX]  [Cancelar]
    │ Confirmar
    ▼
in_app_purchase.buyConsumable(purchaseParam)
    │
    ▼
PurchaseStream listener (IAPService)
    ├── purchased:
    │     ├── Verifica idempotência: purchases/{userId}/{purchaseId} já existe?
    │     │     Se delivered → ignora (proteção contra crash entre entrega e completePurchase)
    │     ├── Escreve purchases/{userId}/{purchaseId} status: "pending"
    │     ├── Entrega itens via SyncEngine (inventory write)
    │     ├── Atualiza status: "delivered"
    │     ├── Gera ShareCode em shareCodes/{code}
    │     ├── completePurchase() — confirma para o SO
    │     └── Exibe PurchaseSuccessSheet com ShareCode
    ├── error / canceled:
    │     └── Snackbar de erro; nenhum item entregue
    └── restored:
          └── Re-entrega se purchases/{purchaseId}.status == "pending"
```

### IAPConfirmationSheet — layout

```
┌─────────────────────────────────────────┐
│  📦 [Nome do Pacote]                     │
│  ─────────────────────────────────────  │
│  Conteúdo:                              │
│  🧨 N× Bomba 3   ↩️ N× Desfazer         │
│  ❤️  N Vidas                            │
│  ─────────────────────────────────────  │
│  + Presente para um amigo:              │
│  🎁 [conteúdo do giftContents]          │
│  ─────────────────────────────────────  │
│  [Confirmar — R$ X,XX]                  │
│  [Cancelar]                             │
└─────────────────────────────────────────┘
```

### PurchaseSuccessSheet — layout

```
┌─────────────────────────────────────────┐
│  ✅ Compra realizada!                    │
│  Seus itens foram adicionados.          │
│                                         │
│  🎁 Presente para um amigo:             │
│  Código: BOTO-4821-XK                   │
│  [📋 Copiar]  [📤 Compartilhar]         │
│  Válido por 30 dias · 1 uso             │
│                                         │
│  [Continuar jogando]                    │
└─────────────────────────────────────────┘
```

**Formato do código:** `{animal}-{4 dígitos}-{2 letras maiúsculas}` (ex: `BOTO-4821-XK`). Legível, memorável, resistente a força bruta.

### Restore de compras

`ProfileScreen` expõe botão "Restaurar compras" → `in_app_purchase.restorePurchases()`. Obrigatório pela App Store Review Guidelines.

### IDs de produto IAP

Padrão: `bichim_pack_{id}` (ex: `bichim_pack_floresta`). Todos **consumable**.

### Arquivos afetados — Sub-F

| Arquivo | Ação |
|---|---|
| `pubspec.yaml` | Adicionar `in_app_purchase: ^3.x` |
| `lib/domain/shop/iap_service.dart` | **Novo** (abstract + FakeIAPService) |
| `lib/data/repositories/iap_service_impl.dart` | **Novo** |
| `lib/data/repositories/share_codes_repository.dart` | Adicionar escrita no Firestore (hoje só Hive) |
| `lib/presentation/widgets/iap_confirmation_sheet.dart` | **Novo** |
| `lib/presentation/widgets/purchase_success_sheet.dart` | **Novo** |
| `lib/presentation/widgets/game_over_no_items_overlay.dart` | Substituir mock por `IAPService` |
| `lib/presentation/screens/shop_screen.dart` | Substituir mock por `IAPService` |
| `lib/presentation/controllers/shop_controller.dart` | Refatorar para orquestrar fluxo IAP |

---

## 10. Modelo de dados Firestore completo

```
users/{userId}
  ├── displayName: string
  ├── avatarUrl: string?
  ├── email: string?
  ├── provider: "google" | "apple" | "email"
  ├── createdAt: timestamp
  ├── lastSeenAt: timestamp
  ├── personalRecords/
  │     bestTimeMs: int
  │     bestNumber: int
  │     totalGames: int
  │     totalWins: int
  │     timesReached4096: int
  │     timesReached8192: int
  │     firstReached4096At: timestamp?
  │     firstReached8192At: timestamp?
  ├── inventory/
  │     bomb2: int
  │     bomb3: int
  │     undo1: int
  │     undo3: int
  │     lives: int
  │     adWatchesToday: int
  │     adWatchDate: string          ← "yyyy-MM-dd"
  └── pendingEvents: []              ← drenados ao reconectar; apagados após sync

rankings/{weekId}/entries/{userId}
  ├── userId: string
  ├── displayName: string
  ├── bestTimeMs: int
  ├── bestNumber: int
  ├── completedAt: timestamp
  └── country: string?               ← reservado; não exibido no lançamento

rankings/{weekId}/meta
  ├── weekId: string                 ← ex: "2025-W19"
  ├── startsAt: timestamp
  ├── endsAt: timestamp              ← sábado 21h UTC
  └── rewardsDistributed: bool

legendsRankings/4096/entries/{userId}
  ├── userId: string
  ├── displayName: string
  ├── timesReached: int
  ├── firstReachedAt: timestamp
  └── country: string?

legendsRankings/8192/entries/{userId}
  ├── userId: string
  ├── displayName: string
  ├── timesReached: int
  ├── firstReachedAt: timestamp
  └── country: string?

invites/{inviterId}
  ├── inviterDisplayName: string
  ├── invites: [
  │     { inviteeId, inviteeDisplayName, status: "pending"|"completed", completedAt? }
  │   ]
  └── totalRewardsClaimed: int

shareCodes/{code}
  ├── code: string
  ├── packageId: string
  ├── giftContents: { lives, bomb2, bomb3, undo1, undo3 }
  ├── status: "pending" | "redeemed" | "expired"
  ├── createdByUserId: string
  ├── redeemedByUserId: string?
  ├── createdAt: timestamp
  └── expiresAt: timestamp           ← createdAt + 30 dias

purchases/{userId}/{purchaseId}
  ├── purchaseId: string             ← token do SO
  ├── packageId: string
  ├── platform: "android" | "ios"
  ├── status: "pending" | "delivered" | "failed"
  ├── purchasedAt: timestamp
  └── deliveredAt: timestamp?
```

### Security Rules (esboço)

```
users/{userId}           → leitura/escrita somente pelo próprio userId
rankings/**              → leitura pública; escrita somente pelo userId da entry
legendsRankings/**       → leitura pública; escrita somente pelo userId da entry
invites/{inviterId}      → leitura/escrita pelo inviterId; leitura pelo convidado para atualizar status
shareCodes/{code}        → leitura pública (resgate); escrita pelo createdByUserId ou resgatador
purchases/{userId}/**    → leitura/escrita somente pelo próprio userId
```

---

## 11. Estratégia de testes

### Princípio

Os testes da Fase 3 **não são modificados**. Rodam contra os Fakes. A Fase 4 adiciona testes novos para lógica de sync/merge e fluxos de compra/convite.

### Helper global

Criar `test/helpers/test_container.dart` com `testContainer({List<Override> extra})` que inclui por padrão: `FakeSyncEngine`, `FakeAuthService`, `FakeIAPService`, `FakeAdService`, `FakeRankingService`.

### Testes unitários novos

| Caso | Arquivo |
|---|---|
| Merge `bestTimeMs` — local menor vence | `test/sync/sync_engine_merge_test.dart` |
| Merge `timesReached4096` — maior vence | idem |
| Merge `firstReachedAt` — mais antigo vence | idem |
| Inventory conflict — saldo insuficiente → zera e notifica | idem |
| Drain pendingEvents — evento `legendReached` aplicado corretamente | `test/sync/pending_events_test.dart` |
| Drain idempotente — mesmo evento drenado 2× não duplica contador | idem |
| `weekId` calculado corretamente antes do reset (sexta 20h BRT) | `test/ranking/week_id_test.dart` |
| `weekId` calculado corretamente após reset (sábado 19h BRT) | idem |
| Recompensa por posição 1º, 3º, 10º, 51º | `test/ranking/weekly_reward_test.dart` |
| Entrega IAP idempotente — `status: delivered` não re-entrega | `test/shop/iap_idempotency_test.dart` |
| Convite duplicado — convidado já vinculado → rejeitado | `test/invites/invite_duplicate_test.dart` |
| Recompensa de convite — entregue somente na 1ª partida | `test/invites/invite_reward_test.dart` |

### Widget tests novos

| Widget | Caso |
|---|---|
| `IAPConfirmationSheet` | Exibe conteúdo completo do pacote antes de confirmar |
| `IAPConfirmationSheet` | Botão desabilitado enquanto IAP processa |
| `PurchaseSuccessSheet` | Exibe ShareCode; botões Copiar e Compartilhar presentes |
| `WeeklyRewardModal` | Exibe posição e itens corretos para cada faixa |
| `OnboardingAuthScreen` | Botões Google, Apple (iOS), Email e "Jogar sem conta" visíveis |
| `AuthBanner` | Aparece quando não logado; oculto quando logado |
| `ProfileScreen` | Exibe avatar + nome + PersonalRecords quando logado |
| `ProfileScreen` | Exibe CTA de login quando não logado |

### Cenários E2E da Fase 3 — revisão de setup

| Cenário | Risco | Mitigação |
|---|---|---|
| `game_over_no_items` — compra mock | `ShopController` agora chama `IAPService` | `FakeIAPService` retorna sucesso imediato |
| `daily_reward` — dobrar via anúncio | `adServiceProvider` reconfigurado | `FakeAdService` permanece no flavor dev/test |
| `ranking_screen` — exibe entradas fake | `SyncEngine` no contexto | Injetar `FakeSyncEngine` no setUp |
| `lives_refill` — ver anúncio para vida | Idem `AdService` | Sem mudança esperada |

---

## 12. Critérios de aceite

### Sub-A — Firebase + Auth

- [ ] App inicializa sem crash com `Firebase.initializeApp()`
- [ ] Login Google funciona em Android e iOS
- [ ] Login Apple funciona em iOS
- [ ] `PlayerProfile` criado no Firestore na primeira autenticação
- [ ] Logout limpa sessão; re-login restaura perfil do Firestore
- [ ] `ProfileScreen` exibe dados corretos do usuário logado
- [ ] `AuthBanner` aparece quando não logado; desaparece após login
- [ ] Reinstalar app + re-login restaura `PersonalRecords` do Firestore
- [ ] Merge silencioso ao logar em device com dados locais divergentes

### Sub-B — Ranking Semanal

- [ ] `weekId` calculado identicamente em dois devices com mesmo horário
- [ ] Score submetido aparece no top da `RankingScreen` em < 3s
- [ ] `WeeklyRewardModal` exibido ao abrir o app após reset (simulado em teste)
- [ ] `rewardsDistributed: true` impede segunda entrega ao reabrir o app
- [ ] Jogador sem entry na semana não recebe modal de recompensa

### Sub-C — Ranking Lendas

- [ ] Atingir 4096 online incrementa `legendsRankings/4096/entries/{userId}`
- [ ] Atingir 4096 offline cria `PendingEvent`; sync ao reconectar atualiza Firestore
- [ ] `firstReachedAt` preservado em reinstalação (restaurado via login)
- [ ] Desempate por `firstReachedAt` correto na query de ranking

### Sub-D — Convites

- [ ] Deep link `olhabichim://invite?ref={id}` capturado em cold start e foreground
- [ ] Convidante recebe recompensa após convidado concluir 1ª partida
- [ ] Convidado não pode ser vinculado a dois convidantes
- [ ] Limite de 20 convites ativos por usuário respeitado

### Sub-E — Anúncios

- [ ] `tagForChildDirectedTreatment: true` configurado e verificável
- [ ] Limite de 40 anúncios/dia respeitado (compartilhado entre `GameOver` e `DailyReward`)
- [ ] Mensagem "Anúncio indisponível" exibida quando carregamento falha
- [ ] Próximo anúncio pré-carregado após exibição

### Sub-F — IAP

- [ ] `IAPConfirmationSheet` exibe conteúdo completo antes de chamar IAP do SO
- [ ] Entrega idempotente: reabertura após crash não duplica itens
- [ ] `ShareCode` gerado e exibido após compra bem-sucedida
- [ ] "Restaurar compras" re-entrega apenas compras com `status: pending`
- [ ] Compra cancelada não entrega itens

---

## 13. Prompt de brainstorm — Fase 5

> Use a skill `superpowers/brainstorming` pra refinar o design da **Fase 5 — Arte adicional e polimento visual** do projeto **Olha o Bichim!** (Flutter, codename `capivara_2048`).
>
> **Contexto:** Fase 4 (Backend, ranking e monetização) concluída. Use `CAPIVARA_2048_DESIGN.md` como spec geral (especialmente §10 Identidade Visual e §15 Roadmap). A spec da Fase 4 está em `docs/specs/2026-05-05-fase4-backend-ranking-monetizacao.md`.
>
> **Tópico do brainstorm:** **Fase 5 — Arte adicional e polimento visual**. Refinamento da identidade visual antes do lançamento: logo final, ícone do app, splash screen, background da HomeScreen e validação visual completa em dispositivos reais.
>
> **Sub-entregas principais:**
>
> **A — Logo do jogo:** versão final do logotipo "Olha o Bichim!" para uso na HomeScreen, splash screen, stores (Play Store / App Store) e materiais de marketing. Diretrizes: cartoon fofo, Fredoka, laranja-tucano `#FF8C42`, integração com animal (Capivara Lendária ou Tucano).
>
> **B — Ícone do app:** revisão do ícone atual (`app_icon_tight.png`) para versão final. Requisitos: legível em 48×48dp, sem texto, adaptive icon Android, fundo `#D4F1DE`.
>
> **C — Splash screen:** revisão da splash screen atual (`splashscreen.png`). Fundo `#1B3610`. Deve funcionar em `flutter_native_splash` para Android e iOS.
>
> **D — Background da HomeScreen:** substituir ou aprimorar o fundo atual. Referências: floresta amazônica, paleta do jogo, sem competir com os elementos de UI.
>
> **E — Validação visual completa:** checklist de consistência visual em todas as telas (Home, Jogo, Coleção, Ranking, Loja, Configurações, Perfil, Convites). Verificar em 3 viewports: small (360×640), medium (390×844), large (412×915).
>
> **Pontos abertos para explorar no brainstorm:**
>
> - Sub-A: o logo deve ter versão horizontal (HomeScreen) e quadrada (ícone/stores) — como manter coerência entre as duas versões sem que o quadrado pareça um recorte mal feito?
> - Sub-B: o ícone atual usa `app_icon_tight.png` — manter o conceito ou redesenhar do zero para a versão final?
> - Sub-D: background animado (parallax leve com folhagem) ou estático? Qual o impacto em performance em devices Android entry-level?
> - Sub-E: existe uma tela ou widget que ficou visualmente inconsistente após as adições da Fase 4 (ProfileScreen, OnboardingAuthScreen, IAPConfirmationSheet)? Como garantir que o estilo cartoon fofo se mantém nas novas telas?
>
> **Output esperado:** spec detalhada da Fase 5 com decisões visuais, assets a criar/modificar por sub-entrega, especificações de tamanho/formato para cada asset, critérios de aceite visual e checklist de validação em dispositivos. Ao final: **prompt de brainstorm da Fase 6** (Áudio).
>
> **Não escreva código nesta etapa.**
