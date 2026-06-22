# App Check (Android) com rollout fásico — Design

**Data:** 2026-06-22
**Projeto Firebase:** `bichim-prd` (produção) e `olha-o-bichim-dev` (dev)
**Origem:** auditoria de segurança da configuração Firebase apontou que, sem App Check,
qualquer cliente com um token de auth válido fala direto com o Firestore — o que torna
triviais os ataques de fraude de compra, duplicação de gift codes e manipulação de ranking.

## Objetivo

Adicionar Firebase App Check ao app (Android) para que apenas o app oficial e íntegro
acesse o Firestore de produção. Conduzir o rollout em **duas fases** para evitar derrubar
usuários já instalados.

## Escopo

**Inclui (esta fase / este release):**

- Dependência `firebase_app_check` no `pubspec.yaml`.
- Ativação do App Check no `lib/main.dart`, escolhendo o provider por flavor.
- Checklist de console para a Fase 1 (registrar Play Integrity, manter **não imposto**).

**Não inclui:**

- O toggle de **enforce** no Firestore — é manual, no console, num passo posterior (Fase 2).
- iOS — adiado até a conta Apple Developer estar ativa (DeviceCheck/App Attest exige chave
  do portal da Apple). Deixar apenas um comentário/hook no código.
- Cloud Functions, validação de ranges nas regras, headers de Hosting — itens separados da
  mesma auditoria, fora deste spec.

## Decisão de rollout (crítica)

Ativar enforce no Firestore **antes** de ter uma versão publicada com App Check rodando na
maioria dos aparelhos bloqueia todos os usuários já instalados (o Firestore para de
responder a eles). Por isso o rollout é fásico:

1. **Fase 1 (este release):** cliente passa a enviar tokens de App Check; Firestore fica em
   modo **não imposto / monitorar**. Zero downtime. Acompanhar métricas por alguns dias.
2. **Fase 2 (depois, manual):** quando a fração de requests "verified" estiver alta, ligar o
   **enforce** no console.

## Abordagem escolhida

**Ativação flavor-aware inline no `main.dart`** (abordagem A), seguindo o padrão já existente
no arquivo (o bloco AdMob já é `if (flavor == 'prd')`). Sem serviço/abstração dedicada —
são ~8 linhas de configuração sem lógica de negócio (YAGNI).

## Mudanças de código

### `pubspec.yaml`

Adicionar `firebase_app_check` na versão compatível com `firebase_core ^4.7.0`
(resolver via `flutter pub add firebase_app_check` na implementação, não fixar versão a dedo).

### `lib/main.dart`

Após o bloco do emulador (que já declara as consts `flavor`, `useEmulator`), ativar o
App Check, pulando sob emulador:

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

Adicionar o import `package:firebase_app_check/firebase_app_check.dart`.

## Comportamento por cenário

| Cenário                       | Provider          | Resultado                                            |
| ----------------------------- | ----------------- | ---------------------------------------------------- |
| `prd` release (loja)          | Play Integrity    | atestação real → requests marcadas como "verified"   |
| `dev` / `tst` (device)        | Debug             | funciona; projeto dev permanece **não imposto**      |
| Emulador (`USE_EMULATOR`)     | — (pulado)        | emulador ignora App Check; nada quebra               |
| CI / integration tests        | Debug             | dev não imposto → passam sem registrar token         |

**Princípio de segurança do CI:** o projeto `olha-o-bichim-dev` **nunca** entra em enforce.
Apenas `bichim-prd` será imposto. Assim, builds debug/CI continuam funcionando sem precisar
registrar tokens de debug.

## Checklist de console (executado pelo usuário; não acessível via CLI)

### Fase 1 — agora, com este release (SEM enforce)

1. Console → `bichim-prd` → App Check → registrar o app Android
   (`1:957303334019:android:dfec2109cc1c2f631d27b6`) com provider **Play Integrity**.
2. Confirmar que os SHA-256 (Play App Signing + upload key) estão em Project Settings —
   Play Integrity depende disso (ver memória `play-app-signing-sha`).
3. Manter o Firestore em **"Não imposto / monitorar"**.
4. Publicar o build prd. Acompanhar as métricas (verified vs unverified) por alguns dias.

### Fase 2 — depois, passo separado e manual

5. Quando a % de "verified" estiver alta (maioria dos usuários atualizou), virar
   Firestore → **Enforce** no console.
6. Vigiar a taxa de erro; reverter o toggle se houver pico.

### Paridade dev (opcional)

- Registrar Play Integrity também em `olha-o-bichim-dev`, mantendo **não imposto**.
- Registrar tokens de debug só se quiser testar o enforce em dev. Não é obrigatório.

## Critérios de verificação

- `flutter analyze` limpo.
- Build prd release compila (`flutter build apk --flavor prod --release --dart-define=FLAVOR=prd ...`).
- Device prd: Firestore funciona normalmente e as métricas de App Check mostram requests "verified".
- Device dev e emulador: continuam funcionando sem regressão.

## Riscos e mitigações

| Risco                                                       | Mitigação                                                        |
| ----------------------------------------------------------- | --------------------------------------------------------------- |
| Enforce ligado cedo demais bloqueia usuários instalados     | Rollout fásico; enforce só na Fase 2, fora deste release        |
| Play Integrity falha por SHA ausente                        | Passo 2 do checklist confirma os SHA-256 antes de publicar      |
| Builds dev/CI quebram                                       | Provider debug + projeto dev nunca imposto                      |
| Emulador rejeita tokens                                     | App Check pulado sob `USE_EMULATOR`                              |
