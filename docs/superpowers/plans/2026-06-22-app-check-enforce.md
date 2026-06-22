# App Check (Android) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Proteger o Firestore de `bichim-prd` com Firebase App Check (Play Integrity no Android), ativado de forma flavor-aware, com rollout fásico (monitorar → enforce).

**Architecture:** Ativação inline no `lib/main.dart` logo após a configuração do emulador, escolhendo o provider pelo `FLAVOR` (`playIntegrity` em prd, `debug` nos demais) e pulando sob emulador. Sem serviço/abstração dedicada. O enforce do Firestore é manual no console, em fase posterior, documentado num arquivo de instruções.

**Tech Stack:** Flutter, `firebase_core ^4.7.0`, `firebase_app_check`, Firebase Console (Play Integrity).

**Spec:** `docs/superpowers/specs/2026-06-22-app-check-enforce-design.md`

---

### Task 1: Adicionar a dependência `firebase_app_check`

**Files:**
- Modify: `pubspec.yaml` (seção `dependencies`, perto de `firebase_core`/`firebase_auth`/`cloud_firestore` nas linhas ~47-49)

- [ ] **Step 1: Adicionar a dependência via pub**

Run: `flutter pub add firebase_app_check`
Expected: o `pubspec.yaml` ganha `firebase_app_check: ^<versão>` e o `pubspec.lock` é atualizado; comando termina com "Changed N dependencies!".

- [ ] **Step 2: Conferir resolução compatível com firebase_core 4.x**

Run: `flutter pub get`
Expected: PASS, sem conflito de versão (sem mensagem "version solving failed"). Se houver conflito, deixar o pub resolver a versão compatível (não fixar à mão).

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "build(app-check): adiciona dependência firebase_app_check

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: Ativar App Check no `main.dart` (flavor-aware, pulando emulador)

**Files:**
- Modify: `lib/main.dart` (import junto aos outros `package:firebase_*` nas linhas 5-6; bloco de ativação após o `if (useEmulator) { ... }` que hoje termina na linha ~57)

- [ ] **Step 1: Adicionar o import**

Adicionar, junto aos imports `package:firebase_*` existentes (linhas 5-6):

```dart
import 'package:firebase_app_check/firebase_app_check.dart';
```

- [ ] **Step 2: Inserir o bloco de ativação após o bloco do emulador**

O `main.dart` já declara `const flavor` (linha ~38) e `const useEmulator` (linha ~49), e tem o bloco:

```dart
  if (useEmulator) {
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  }
```

Logo **depois** desse bloco, inserir:

```dart
  // App Check — protege o Firestore contra clientes não-oficiais.
  // Pulado sob emulador (o emulador não valida tokens de App Check).
  if (!useEmulator) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: flavor == 'prd'
          ? AndroidProvider.playIntegrity
          : AndroidProvider.debug,
      // iOS: adicionar appleProvider quando a conta Apple Developer estiver ativa
    );
  }
```

- [ ] **Step 3: Verificar análise estática**

Run: `flutter analyze`
Expected: "No issues found!" (ou, no mínimo, nenhum erro/aviso novo introduzido por estas linhas — sem "Undefined name 'FirebaseAppCheck'", sem import não usado).

- [ ] **Step 4: Verificar que o build prd compila**

Run: `flutter build apk --flavor prod --release --dart-define=FLAVOR=prd --dart-define=AD_UNIT_ANDROID=ca-app-pub-7740393771713068/1418419253 --dart-define=AD_UNIT_IOS=stub`
Expected: "✓ Built build/app/outputs/flutter-apk/app-prod-release.apk". Se a máquina não tiver toolchain de release configurada, ao menos `flutter build apk --flavor tst --dart-define=FLAVOR=dev --debug` deve compilar.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart
git commit -m "feat(app-check): ativa App Check flavor-aware no startup

Play Integrity em prd, debug provider nos demais flavors, pulado sob
emulador. Mantém o Firestore não imposto (enforce é passo manual de console).

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: Criar o arquivo de instruções de configuração do enforce no Firebase

**Files:**
- Create: `docs/FIREBASE_APP_CHECK.md`

- [ ] **Step 1: Escrever o documento de instruções**

Criar `docs/FIREBASE_APP_CHECK.md` cobrindo, em português, linguagem operacional clara:

1. **Contexto** — por que App Check (auditoria: Firestore aberto a qualquer cliente com auth), e que o código já envia tokens (Play Integrity em prd).
2. **Pré-requisitos** — app Android `1:957303334019:android:dfec2109cc1c2f631d27b6` em `bichim-prd`; SHA-256 (Play App Signing + upload key) registrados em Project Settings (cf. memória `play-app-signing-sha`); Play Integrity API habilitada.
3. **Fase 1 — registrar e monitorar (sem enforce):**
   - Console → `bichim-prd` → App Check → aba Apps → registrar o app Android com provider **Play Integrity**.
   - Confirmar os SHA-256 em Project Settings.
   - Deixar Firestore em **"Não imposto / Monitorar"**.
   - Publicar o build prd; acompanhar métricas "verified vs unverified" por alguns dias.
4. **Fase 2 — ligar o enforce (manual, posterior):**
   - Quando a fração de "verified" estiver alta, Console → App Check → APIs → Cloud Firestore → **Impor (Enforce)**.
   - Vigiar a taxa de erro pós-enforce; como reverter (desligar o toggle) se houver pico.
5. **Dev/CI** — `olha-o-bichim-dev` nunca entra em enforce; builds debug usam o provider debug; tokens de debug são opcionais (só para testar enforce em dev) e como obtê-los (token impresso no logcat → App Check → Gerenciar tokens de depuração).
6. **Verificação** — onde ver as métricas; o que significa "verified".
7. **iOS (pendente)** — adicionar `appleProvider` (DeviceCheck/App Attest) e registrar o app iOS quando a conta Apple Developer estiver ativa (cf. memória `ios-universal-links-pendente`).

- [ ] **Step 2: Revisar legibilidade**

Reler o arquivo: garantir que cada passo de console é acionável (onde clicar, o que selecionar), sem jargão desnecessário, e que a separação Fase 1 / Fase 2 está inequívoca.

- [ ] **Step 3: Commit**

```bash
git add docs/FIREBASE_APP_CHECK.md
git commit -m "docs(app-check): instruções de configuração e enforce no Firebase

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: Revisar o arquivo de instruções com subagente (2 passadas)

**Files:**
- Modify (conforme achados): `docs/FIREBASE_APP_CHECK.md`

- [ ] **Step 1: Primeira revisão por subagente**

Dispachar um subagente para revisar `docs/FIREBASE_APP_CHECK.md` quanto a: precisão técnica do fluxo de App Check/Play Integrity, ordem segura do rollout (nunca enforce antes de adoção), completude dos passos de console, clareza operacional, e qualquer passo ambíguo ou faltante. Aplicar inline os achados válidos.

- [ ] **Step 2: Segunda revisão por subagente**

Dispachar um segundo subagente (contexto limpo) para revisar a versão já corrigida, confirmando que os achados da 1ª passada foram resolvidos e caçando o que sobrou. Aplicar inline os achados válidos.

- [ ] **Step 3: Commit (se houve mudanças)**

```bash
git add docs/FIREBASE_APP_CHECK.md
git commit -m "docs(app-check): ajustes de revisão das instruções de configuração

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Notas de verificação final

- `flutter analyze` limpo.
- Build prd (ou ao menos tst) compila.
- `docs/FIREBASE_APP_CHECK.md` existe, com Fase 1 (monitorar) e Fase 2 (enforce) bem separadas.
- O enforce **não** é ligado por este plano — é passo manual de console, documentado.
- Atualizar `CHANGELOG.md` segue o release checklist do `CLAUDE.md` no momento do merge (fora do escopo das tasks acima, decidido no fechamento da branch).
