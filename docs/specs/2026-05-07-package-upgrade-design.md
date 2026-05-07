# Package Upgrade — Design Spec

**Data:** 2026-05-07  
**Flutter instalado:** 3.41.7 (stable) · Dart 3.11.x  
**Escopo:** atualizar todos os 47 pacotes desatualizados listados em `flutter pub outdated`

---

## 1. Inventário de breaking changes

### 1.1 Criticalidade por pacote

| Pacote                          | De     | Para   | Risco    | Impacto no código                                                   |
| ------------------------------- | ------ | ------ | -------- | ------------------------------------------------------------------- |
| `flutter_riverpod` + `riverpod` | 2.6.1  | 3.3.1  | 🔴 Alto  | 51 arquivos; `StateNotifierProvider` legado; `AutoDispose` removido |
| `google_sign_in`                | 6.3.0  | 7.2.0  | 🔴 Alto  | `firebase_auth_service.dart` — API completamente redesenhada        |
| `firebase_core`                 | 3.15.2 | 4.7.0  | 🟡 Médio | iOS SDK 12.0 + Android SDK 34 obrigatórios                          |
| `firebase_auth`                 | 5.7.0  | 6.4.0  | 🟡 Médio | funções depreciadas removidas                                       |
| `cloud_firestore`               | 5.6.12 | 6.3.0  | 🟡 Médio | funções depreciadas removidas                                       |
| `google_mobile_ads`             | 5.3.1  | 8.0.0  | 🟡 Médio | UISceneDelegate; renomeação de métodos                              |
| `share_plus`                    | 10.1.4 | 13.1.0 | 🟡 Médio | `Share.share()` depreciado → `SharePlus.instance.share()`           |
| `sign_in_with_apple`            | 6.1.4  | 8.0.0  | 🟢 Baixo | renomeação de enum; min Flutter 3.41                                |
| `app_links`                     | 6.4.1  | 7.0.0  | 🟢 Baixo | sem mudança de API; min iOS 13 + Flutter 3.38                       |
| `connectivity_plus`             | 6.1.5  | 7.1.1  | 🟢 Baixo | sem mudança de API Dart; requisitos Android AGP/Gradle              |
| `package_info_plus`             | 8.3.1  | 10.1.0 | 🟢 Baixo | sem mudança de API; requisitos Android AGP/Gradle                   |
| `google_fonts`                  | 6.3.3  | 8.1.0  | 🟢 Baixo | apenas adição/remoção de fontes; sem mudança de API                 |
| Demais (build, lints, test…)    | —      | —      | 🟢 Baixo | sem mudança de API                                                  |

---

## 2. Detalhes das breaking changes

### 2.1 Riverpod 2 → 3

**Fonte:** https://riverpod.dev/docs/3.0_migration

#### `StateNotifierProvider`, `StateProvider`, `ChangeNotifierProvider` → `legacy.dart`

Não foram removidos, mas saíram da importação padrão. O projeto usa `StateNotifierProvider` em **11 providers**:

```
lib/core/providers/reduce_effects_provider.dart
lib/domain/lives/lives_notifier.dart
lib/domain/inventory/inventory_notifier.dart
lib/domain/daily_rewards/daily_rewards_notifier.dart
lib/domain/shop/share_codes_notifier.dart
lib/presentation/controllers/settings_notifier.dart
lib/presentation/controllers/personal_records_notifier.dart
lib/presentation/controllers/auth_controller.dart
lib/presentation/controllers/game_notifier.dart
lib/presentation/controllers/invite_controller.dart
lib/presentation/controllers/ranking_controller.dart
```

**Estratégia adotada (migração completa):** converter cada `StateNotifier` para `Notifier` / `AsyncNotifier` com `build()` nativo, eliminando a dependência de `legacy.dart`. Cada notifier receberá o `ref` como propriedade embutida em vez de parâmetro de construtor, e o estado inicial será definido em `build()`.

#### `AutoDispose` variants removidas

`AutoDisposeNotifier`, `AutoDisposeAsyncNotifier` etc. foram fundidos com as classes base. Basta fazer find-replace de `AutoDispose` → `""` (string vazia).

#### `Ref` sem type parameter; subclasses removidas

`ProviderRef<T>`, `FutureProviderRef<T>` etc. removidos. Usar `Ref` diretamente.  
Afeta principalmente código com `riverpod_generator` (não usado neste projeto).

#### `FamilyNotifier` removido

Substituído por `Notifier` com construtor próprio. Não identificado uso no projeto.

#### `ProviderObserver` com nova assinatura

```dart
// Antes:
void didAddProvider(ProviderBase provider, Object? value, ProviderContainer container)
// Depois:
void didAddProvider(ProviderObserverContext context, Object? value)
```

Verificar se o projeto tem observers customizados.

#### Retry automático e pausa out-of-view (mudanças de lifecycle)

- Providers que falharem serão automaticamente retentados. Para desabilitar globalmente:
  ```dart
  ProviderScope(retry: (count, error) => null, child: MyApp())
  ```
- Providers fora de view são pausados por padrão. Usar `TickerMode(enabled: true)` para desabilitar por widget.

#### Erros de provider relançados como `ProviderException`

```dart
// Antes:
} on NotFoundException { ... }
// Depois:
} on ProviderException catch (e) {
  if (e.exception is NotFoundException) { ... }
}
```

---

### 2.2 `google_sign_in` 6 → 7

**Fonte:** https://github.com/flutter/packages/blob/main/packages/google_sign_in/google_sign_in/MIGRATION.md

API completamente redesenhada. O projeto usa `firebase_auth_service.dart` com o padrão antigo:

```dart
_googleSignIn = GoogleSignIn();           // ❌ construtor removido
await _googleSignIn.signIn();             // ❌ substituído
await _googleSignIn.signOut();            // ainda existe, mas contexto mudou
googleAuth.accessToken                    // ainda existe, mas obtido diferente
```

**Mudanças obrigatórias:**

| Antigo                                   | Novo                                                                       |
| ---------------------------------------- | -------------------------------------------------------------------------- |
| `GoogleSignIn()` (construtor)            | `GoogleSignIn.instance` (singleton)                                        |
| Sem `initialize`                         | `await GoogleSignIn.instance.initialize()` antes de tudo                   |
| `_googleSignIn.signIn()`                 | `await GoogleSignIn.instance.authenticate()`                               |
| `_googleSignIn.signInSilently()`         | `GoogleSignIn.instance.attemptLightweightAuthentication()`                 |
| `_googleSignIn.signOut()`                | `await GoogleSignIn.instance.signOut()`                                    |
| `_googleSignIn.clearAuthCache()`         | `GoogleSignIn.instance.clearAuthorizationToken(token)`                     |
| "current user" via retorno de `signIn()` | `authenticationEvents` stream                                              |
| `googleUser.authentication.accessToken`  | `(await GoogleSignIn.instance.authorizationForScopes([...]))?.accessToken` |

O fluxo de Firebase Auth com Google precisa ser reescrito. Exemplo novo:

```dart
await GoogleSignIn.instance.initialize();
// ouvir authenticationEvents em vez de await signIn()
GoogleSignIn.instance.authenticationEvents.listen((event) {
  // event é GoogleSignInAccount ou GoogleSignInException
});
await GoogleSignIn.instance.authenticate(); // dispara o fluxo
```

---

### 2.3 Firebase suite (`firebase_core` 3→4, `firebase_auth` 5→6, `cloud_firestore` 5→6)

**Fonte:** https://pub.dev/packages/firebase_core/changelog · https://pub.dev/packages/firebase_auth/changelog

#### `firebase_core` 4.0.0

```
BREAKING: bump iOS SDK to 12.0.0
BREAKING: bump Android SDK to 34.0.0
```

Apenas requisitos de plataforma. Sem mudança de API Dart.

#### `firebase_auth` 6.0.0

```
BREAKING: remove deprecated functions
BREAKING: bump iOS SDK to 12.0.0
BREAKING: bump Android SDK to 34.0.0
```

Funções depreciadas removidas. Verificar se o projeto usa alguma API depreciada do `firebase_auth` 5.x.  
O uso atual (`signInWithCredential`, `signInWithEmailAndPassword`, `signOut`, `currentUser`) permanece estável.

#### `cloud_firestore` 6.0.0

```
BREAKING: remove deprecated functions
BREAKING: bump iOS SDK to 12.0.0
BREAKING: bump Android SDK to 34.0.0
```

Sem mudança nas APIs usadas no projeto (`collection`, `doc`, `set`, `get`, `snapshots`, `where`, `orderBy`, `limit`).

---

### 2.4 `google_mobile_ads` 5 → 8

**Fonte:** https://github.com/googleads/googleads-mobile-flutter/blob/main/packages/google_mobile_ads/CHANGELOG.md

#### 8.0.0

- Updates GMA Android SDK → 25.1.0
- Updates GMA iOS SDK → 13.2.0
- Migrated to `UISceneDelegate` protocol (iOS)
- `getCurrentOrientationAnchoredAdaptiveBannerAdSize` **depreciado** → usar `AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize()` (novo nome). Verificar uso em `google_mobile_ads_service.dart`.
- Requires min Flutter SDK 3.38.1 ✅ (projeto usa 3.41.7)

#### 7.0.0 (intermediária)

- UMP SDK: Android 3.x, iOS 2.x

O projeto não usa `getCurrentOrientationAnchoredAdaptiveBannerAdSize` diretamente — uso é via `AdSize.banner` e `AdSize.fullBanner`. **Impacto: zero no código Dart.**

---

### 2.5 `share_plus` 10 → 13

**Fonte:** https://pub.dev/packages/share_plus/versions/13.0.0

#### Métodos estáticos depreciados → novo padrão de instância

```dart
// ❌ Antes (ainda funciona, mas depreciado):
Share.share('texto');
Share.shareXFiles([XFile(path)]);

// ✅ Depois:
await SharePlus.instance.share(ShareParams(text: 'texto'));
await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
```

**Arquivos afetados:**

- `lib/presentation/screens/invite_friends_screen.dart`
- `lib/presentation/widgets/purchase_success_sheet.dart`
- `lib/testing/share_results.dart`

Requisitos: min Flutter 3.41.6 ✅, Dart 3.11.0 ✅, iOS 13.0, AGP ≥ 8.12.1, Gradle ≥ 8.13, Kotlin 2.2.0.

---

### 2.6 `sign_in_with_apple` 6 → 8

**Fonte:** https://pub.dev/packages/sign_in_with_apple/changelog

#### 8.0.0

- `SignInWithAppleButton`'s `iconAlignment` renomeado para `SignInWithAppleIconAlignment` (evita conflito com `IconAlignment` do Material).
- Min Flutter SDK 3.41.0 ✅

O projeto não usa `SignInWithAppleButton` diretamente (usa apenas `SignInWithApple.getAppleIDCredential`). **Impacto: zero no código Dart.**

---

### 2.7 `app_links` 6 → 7

**Fonte:** https://pub.dev/packages/app_links/changelog

#### 7.0.0

- Breaking apenas de plataforma: min iOS 13, Flutter 3.38.1 ✅
- API Dart **inalterada**: `AppLinks()`, `.getInitialLink()`, `.uriLinkStream` continuam iguais.

**Impacto: zero no código Dart.**

---

### 2.8 `connectivity_plus` 6 → 7

**Fonte:** https://pub.dev/packages/connectivity_plus/changelog

#### 7.0.0

- Breaking de build: AGP ≥ 8.12.1, Gradle ≥ 8.13, Kotlin 2.2.0
- API Dart **inalterada**: `Connectivity().onConnectivityChanged`, `ConnectivityResult` continuam iguais.

**Impacto: zero no código Dart.** Verificar versões do Gradle/Kotlin no `build.gradle.kts`.

---

### 2.9 `package_info_plus` 8 → 10

**Fonte:** https://pub.dev/packages/package_info_plus/changelog

#### 9.0.0 / 10.0.0

- Breaking de build: AGP ≥ 8.12.1, Gradle ≥ 8.13, Kotlin 2.2.0, min iOS 13, min macOS 10.15
- API Dart **inalterada**: `PackageInfo.fromPlatform()` continua igual.

**Impacto: zero no código Dart.**

---

### 2.10 `google_fonts` 6 → 8

**Fonte:** https://pub.dev/packages/google_fonts/changelog

#### 7.0.0 / 8.0.0

- Apenas adição e remoção de famílias de fontes (Big Condensed variants removidas, novas fontes adicionadas).
- **Nenhuma mudança de API.** Verificar se o projeto usa alguma fonte removida.
- Fonte usada no projeto: `GoogleFonts.luckiestGuy()`, `GoogleFonts.nunito()` — ambas mantidas.

**Impacto: zero no código Dart.**

---

### 2.11 Pacotes de baixo risco (sem mudança de API)

Atualizações de patch/minor sem breaking changes para o código do projeto:

| Pacote                                        | De      | Para    | Natureza                          |
| --------------------------------------------- | ------- | ------- | --------------------------------- |
| `build`                                       | 4.0.5   | 4.0.6   | patch                             |
| `build_runner`                                | 2.14.1  | 2.15.0  | minor                             |
| `built_value`                                 | 8.12.5  | 8.12.6  | patch                             |
| `dart_style`                                  | 3.1.7   | 3.1.9   | patch                             |
| `flutter_lints`                               | 5.0.0   | 6.0.0   | minor (novas regras de lint)      |
| `matcher`                                     | 0.12.19 | 0.12.20 | patch                             |
| `meta`                                        | 1.17.0  | 1.18.2  | minor                             |
| `test` + `test_api` + `test_core`             | várias  | últimas | minor                             |
| `url_launcher_web`                            | 2.4.2   | 2.4.3   | patch                             |
| `vector_math`                                 | 2.2.0   | 2.3.0   | minor                             |
| `xml`                                         | 6.6.1   | 7.0.1   | major (sem impacto neste projeto) |
| `_fe_analyzer_shared`, `analyzer`, `cli_util` | várias  | últimas | dev-only                          |

---

## 3. Requisitos de build Android

Vários pacotes de `plus_plugins` (connectivity, package_info, share) exigem:

- **Android Gradle Plugin ≥ 8.12.1**
- **Gradle wrapper ≥ 8.13**
- **Kotlin 2.2.0**

**Versões atuais do projeto:**

| Ferramenta            | Atual                                  | Requerido | Ação         |
| --------------------- | -------------------------------------- | --------- | ------------ |
| Android Gradle Plugin | 8.11.1 (`android/settings.gradle.kts`) | ≥ 8.12.1  | ❌ Atualizar |
| Gradle wrapper        | 8.14 (`gradle-wrapper.properties`)     | ≥ 8.13    | ✅ OK        |
| Kotlin                | 2.2.20 (`android/settings.gradle.kts`) | ≥ 2.2.0   | ✅ OK        |

---

## 4. Arquivos com mudanças de código necessárias

| Arquivo                                                       | Pacote             | Mudança                                                                                        |
| ------------------------------------------------------------- | ------------------ | ---------------------------------------------------------------------------------------------- |
| `lib/data/repositories/firebase_auth_service.dart`            | `google_sign_in` 7 | Reescrever fluxo Google Sign-In (singleton + initialize + authenticate + authenticationEvents) |
| `lib/core/providers/reduce_effects_provider.dart`             | `riverpod` 3       | `StateNotifier` → `Notifier`, `StateNotifierProvider` → `NotifierProvider`                     |
| `lib/domain/lives/lives_notifier.dart`                        | `riverpod` 3       | Idem                                                                                           |
| `lib/domain/inventory/inventory_notifier.dart`                | `riverpod` 3       | Idem                                                                                           |
| `lib/domain/daily_rewards/daily_rewards_notifier.dart`        | `riverpod` 3       | Idem                                                                                           |
| `lib/domain/shop/share_codes_notifier.dart`                   | `riverpod` 3       | Idem                                                                                           |
| `lib/presentation/controllers/settings_notifier.dart`         | `riverpod` 3       | Idem                                                                                           |
| `lib/presentation/controllers/personal_records_notifier.dart` | `riverpod` 3       | Idem                                                                                           |
| `lib/presentation/controllers/auth_controller.dart`           | `riverpod` 3       | Idem                                                                                           |
| `lib/presentation/controllers/game_notifier.dart`             | `riverpod` 3       | Idem                                                                                           |
| `lib/presentation/controllers/invite_controller.dart`         | `riverpod` 3       | Idem — usar `AsyncNotifier` (já retorna `AsyncValue`)                                          |
| `lib/presentation/controllers/ranking_controller.dart`        | `riverpod` 3       | Idem — usar `AsyncNotifier` (já retorna `AsyncValue`)                                          |
| `lib/presentation/screens/invite_friends_screen.dart`         | `share_plus` 13    | `Share.share()` → `SharePlus.instance.share(ShareParams(...))`                                 |
| `lib/presentation/widgets/purchase_success_sheet.dart`        | `share_plus` 13    | Idem                                                                                           |
| `lib/testing/share_results.dart`                              | `share_plus` 13    | `Share.shareXFiles()` → `SharePlus.instance.share(ShareParams(files:[...]))`                   |
| `android/settings.gradle.kts`                                 | vários             | AGP: 8.11.1 → 8.12.1+                                                                          |

---

## 5. Estratégia de upgrade

### Abordagem recomendada: por grupos de risco (3 PRs)

**Grupo 1 — Infra de build + baixo risco** (sem toque no código Dart)

- Atualizar `pubspec.yaml`: todos os pacotes de baixo risco (seção 2.11) + `app_links`, `connectivity_plus`, `package_info_plus`, `google_fonts`, `sign_in_with_apple`, `firebase_core`, `firebase_auth`, `cloud_firestore`
- Ajustar `build.gradle.kts` e `gradle-wrapper.properties` para AGP 8.12.1+, Gradle 8.13+, Kotlin 2.2.0
- Verificar build e testes

**Grupo 2 — `share_plus` + `google_mobile_ads`** (mudanças pontuais, ~3 arquivos)

- Atualizar `pubspec.yaml`
- Migrar `Share.share()` → `SharePlus.instance.share(ShareParams(...))`
- Verificar build e testes

**Grupo 3 — Riverpod 3 + google_sign_in 7** (mudanças estruturais)

- Atualizar `pubspec.yaml`
- Migrar cada `StateNotifier` para `Notifier`/`AsyncNotifier` nos 11 arquivos: remover herança de `StateNotifier`, implementar `build()` com estado inicial, remover `ref` do construtor
- Atualizar os `StateNotifierProvider` correspondentes para `NotifierProvider`
- Reescrever `firebase_auth_service.dart` para nova API do `google_sign_in`
- Verificar build, testes unitários e teste manual do fluxo de login Google

---

## 6. Riscos e mitigações

| Risco                                                            | Probabilidade | Mitigação                                                                                     |
| ---------------------------------------------------------------- | ------------- | --------------------------------------------------------------------------------------------- |
| Login Google quebrado em produção                                | Alta          | Testar em dispositivo físico antes de subir para alpha                                        |
| Providers com retry automático causarem comportamento inesperado | Média         | Adicionar `retry: (_, __) => null` no `ProviderScope` durante migração e remover gradualmente |
| Providers pausados out-of-view quebrarem animações/timers        | Baixa         | Monitorar em testes manuais; usar `TickerMode` se necessário                                  |
| Gradle/Kotlin upgrade quebrar CI                                 | Baixa         | Testar build local antes de push                                                              |
