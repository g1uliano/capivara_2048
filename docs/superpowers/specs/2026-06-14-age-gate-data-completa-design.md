# Age Gate — data completa (dia/mês/ano) por conta

**Data:** 2026-06-14
**Status:** Aprovado (design)

## Problema

O gate de idade atual (`lib/presentation/widgets/age_gate_dialog.dart`) pede
apenas o **ano de nascimento** e calcula `idade = anoAtual - anoNascimento`.
Esse cálculo assume que o aniversário do ano já passou, então **superestima a
idade em até ~1 ano**: uma criança nascida em dez/2014, em jun/2026, tem 11 anos
reais mas o app calcula 12 e a deixa entrar. A regra desejada é **pelo menos 12
anos completos garantidos**, o que exige dia, mês e ano.

Além disso, a verificação é hoje um `bool age_gate_passed` em SharedPreferences —
global por dispositivo e sem registro por conta. Contas que já passaram pelo gate
antigo (só o ano) precisam responder novamente no próximo login.

## Decisões tomadas

- **Persistência:** `birthDate` por conta no Firestore (`users/{uid}.birthDate`).
- **Widget de seleção:** `DropdownMenu` nativo do Material 3 (com
  `enableFilter`/`enableSearch` no ano). Zero dependências novas.
- **Re-perguntar contas antigas:** automático — contas sem o campo `birthDate`
  (todas as que responderam só o ano) são perguntadas no próximo login.

## Arquitetura

### 1. Lógica pura — `lib/core/utils/age_check.dart`

Dart puro, sem Flutter, testável isoladamente (conforme regra do game engine
estendida a utils de regra de negócio).

```dart
/// True se `birth` garante 12 anos completos em `now`.
bool isAtLeast12(DateTime birth, DateTime now);

/// Quantidade de dias no mês (trata ano bissexto), p/ limitar o select de dia.
int daysInMonth(int year, int month);
```

`isAtLeast12`: `final twelfth = DateTime(birth.year + 12, birth.month, birth.day);
return !now.isBefore(twelfth);` — ou seja, passa somente quando `now >=` 12º
aniversário.

### 2. Persistência — `AuthService`

Dois métodos novos na interface `lib/domain/auth/auth_service.dart`:

```dart
Future<DateTime?> getBirthDate();         // lê users/{uid}.birthDate (null se ausente)
Future<void> saveBirthDate(DateTime dob); // merge users/{uid}.birthDate
```

- **`FirebaseAuthService`** (`lib/data/repositories/firebase_auth_service.dart`):
  segue o padrão de `updateDisplayName` — `FirebaseFirestore.instance
  .collection('users').doc(uid).set({'birthDate': '<ISO YYYY-MM-DD>'},
  SetOptions(merge: true))` para escrever; leitura via `get()` do mesmo doc e
  `DateTime.parse`. Formato armazenado: string ISO data-só (`'2008-03-15'`).
- **`FakeAuthService`** (flavor tst / testes): campo `DateTime? _birthDate`
  in-memory; `getBirthDate`/`saveBirthDate` operam sobre ele. Default que não
  bloqueia testes existentes (ex.: data adulta), ajustável via construtor se algum
  teste precisar exercitar o gate.

`PlayerProfile` **não** ganha campo `birthDate` — o model é derivado do Firebase
Auth `User` e não lê Firestore; nenhuma UI consome a data. (YAGNI)

### 3. Modal refinado — `AgeGateDialog`

Reescreve `lib/presentation/widgets/age_gate_dialog.dart` mantendo o visual
cartoon atual (borda esmeralda `0xFF2E7D52`, título Fredoka, fundo branco do
`AlertDialog`).

- Substitui o `TextField` por **três `DropdownMenu<int>`**: **Dia · Mês · Ano**.
  - Mês: rótulos por nome (Janeiro…Dezembro), valor 1–12.
  - Ano: `enableFilter: true, enableSearch: true`, opções de `anoAtual` até
    `anoAtual - 110`, ordenadas do mais recente ao mais antigo.
  - Dia: opções 1..`daysInMonth(anoSel, mesSel)`; ao trocar mês/ano, se o dia
    selecionado exceder o limite, ele é **limpo** (volta a vazio, exige reescolha)
    — evita gravar silenciosamente um dia errado.
- Botão "Continuar" só habilita com dia, mês e ano escolhidos.
- Ao confirmar: monta `DateTime(ano, mes, dia)`; se `isAtLeast12` falso → estado
  "bloqueado" (🚫 + "precisa ter pelo menos 12 anos … pode jogar sem conta").
- API pública passa a retornar a data:

```dart
/// Retorna a data escolhida se o usuário tem 12+ e confirmou; null se cancelou
/// ou foi bloqueado (o próprio dialog mostra a mensagem de bloqueio).
Future<DateTime?> showAgeGateDialog(BuildContext context);
```

Remove `showAgeGateIfNeeded` e a chave `age_gate_passed` (SharedPreferences) — a
verificação passa a ser por conta, não por dispositivo.

### 4. Fluxo nos pontos de entrada

Assimetria necessária: no login não dá pra gatear antes de autenticar, porque o
`uid` (e portanto a checagem de "já respondeu?") só existe após o auth.

**Cadastro por e-mail** — `email_auth_screen.dart` `_submit` (`_isSignUp`):
```
final dob = await showAgeGateDialog(context);
if (dob == null || !mounted) return;          // cancelou/menor → não cria conta
await controller.createAccountWithEmail(...);
await ref.read(authServiceProvider).saveBirthDate(dob);
// → AvatarPickerScreen → Home
```

**Login por e-mail** — `email_auth_screen.dart` `_submit` (`else`):
```
await controller.signInWithEmail(...);
final ok = await _ensureBirthDate(context, ref);  // helper compartilhado
if (!ok || !mounted) return;                       // signOut já feito dentro
// → Home
```

**Login Google/Apple** — `onboarding_auth_screen.dart` `_handleSignIn`:
```
await action();                                    // autentica
final ok = await _ensureBirthDate(context, ref);
if (!ok || !mounted) return;
_navigateHome();
```

Helper compartilhado — função de topo no mesmo arquivo do dialog
(`age_gate_dialog.dart`), reusada pelas duas telas de login:
```dart
/// Garante que a conta atual tem birthDate. Lê do Firestore; se ausente, mostra
/// o modal e salva. Retorna false (e faz signOut) se cancelar/menor.
Future<bool> _ensureBirthDate(BuildContext context, WidgetRef ref) async {
  final auth = ref.read(authServiceProvider);
  if (await auth.getBirthDate() != null) return true;   // já respondeu antes
  final dob = await showAgeGateDialog(context);
  if (dob == null) { await auth.signOut(); return false; }
  await auth.saveBirthDate(dob);
  return true;
}
```

"Jogar sem conta" (`_navigateHome` direto, anônimo) permanece sem gate.

## Testes

- **Unitário** `test/core/age_check_test.dart`:
  - véspera do 12º aniversário → `false`; no dia → `true`; um dia depois → `true`.
  - bem mais novo → `false`; bem mais velho → `true`.
  - `daysInMonth`: fev em ano comum (28) e bissexto (29), meses de 30 e 31.
- **Widget** (opcional, se houver infra): `AgeGateDialog` retorna data com 12+ e
  estado bloqueado com <12.
- **Fake**: confirmar que `FakeAuthService.getBirthDate/saveBirthDate` funcionam
  para os cenários de tst.

## Limites de escopo

- Re-pergunta ocorre **no próximo login**. Usuário com sessão já persistida não é
  re-perguntado no startup — só ao deslogar e logar novamente. (Decisão explícita.)
- Não migra/backfill contas existentes server-side; a ausência de `birthDate` é o
  próprio sinal de "precisa perguntar".
- Sem coleta de dia/mês/ano para jogo anônimo (sem conta).
