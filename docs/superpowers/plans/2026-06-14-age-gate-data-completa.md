# Age Gate — data completa (dia/mês/ano) por conta — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trocar o gate de idade "só ano" por coleta de dia/mês/ano que garante 12 anos completos, com a data salva por conta no Firestore e contas antigas re-perguntadas no próximo login.

**Architecture:** Lógica de idade pura e testável em `core/utils/age_check.dart`. Persistência por conta via dois métodos novos em `AuthService` (`getBirthDate`/`saveBirthDate`), implementados no `FirebaseAuthService` (Firestore `users/{uid}.birthDate`) e no `FakeAuthService` (in-memory). Modal reescrito com três `DropdownMenu` (Material 3). Cadastro gateia antes de criar a conta; logins gateiam após autenticar via helper `ensureBirthDate`.

**Tech Stack:** Flutter/Dart, Riverpod, cloud_firestore, firebase_auth, google_fonts, flutter_test.

**Spec:** `docs/superpowers/specs/2026-06-14-age-gate-data-completa-design.md`

---

## File Structure

- **Create** `lib/core/utils/age_check.dart` — funções puras `isAtLeast12`, `daysInMonth`.
- **Create** `test/core/utils/age_check_test.dart` — testes das funções puras.
- **Modify** `lib/domain/auth/auth_service.dart` — interface + `FakeAuthService` (2 métodos, campo `_birthDate`, provider tst com data adulta).
- **Create** `test/domain/auth_birthdate_test.dart` — testa `FakeAuthService.getBirthDate/saveBirthDate`.
- **Modify** `lib/data/repositories/firebase_auth_service.dart` — implementa os 2 métodos (Firestore).
- **Modify** `lib/presentation/widgets/age_gate_dialog.dart` — reescrita completa: `showAgeGateDialog` (retorna `DateTime?`), `ensureBirthDate` helper, modal com 3 `DropdownMenu`. Remove `showAgeGateIfNeeded` e a chave `age_gate_passed`.
- **Modify** `lib/presentation/screens/email_auth_screen.dart` — fluxo cadastro (gate antes) e login (gate depois).
- **Modify** `lib/presentation/screens/onboarding_auth_screen.dart` — `_handleSignIn` gateia após `action()`.

---

## Task 1: Lógica pura de idade

**Files:**
- Create: `lib/core/utils/age_check.dart`
- Test: `test/core/utils/age_check_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/utils/age_check_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/core/utils/age_check.dart';

void main() {
  group('isAtLeast12', () {
    final birth = DateTime(2014, 6, 15);

    test('day before 12th birthday → false', () {
      expect(isAtLeast12(birth, DateTime(2026, 6, 14)), isFalse);
    });
    test('on 12th birthday → true', () {
      expect(isAtLeast12(birth, DateTime(2026, 6, 15)), isTrue);
    });
    test('day after 12th birthday → true', () {
      expect(isAtLeast12(birth, DateTime(2026, 6, 16)), isTrue);
    });
    test('much younger → false', () {
      expect(isAtLeast12(DateTime(2020, 1, 1), DateTime(2026, 6, 14)), isFalse);
    });
    test('much older → true', () {
      expect(isAtLeast12(DateTime(1990, 1, 1), DateTime(2026, 6, 14)), isTrue);
    });
    test('Feb 29 birth → exact 12th birthday is valid Feb 29', () {
      final leapBirth = DateTime(2008, 2, 29); // 2008 e 2020 são bissextos
      expect(isAtLeast12(leapBirth, DateTime(2020, 2, 29)), isTrue);
      expect(isAtLeast12(leapBirth, DateTime(2020, 2, 28)), isFalse);
    });
  });

  group('daysInMonth', () {
    test('February common year', () => expect(daysInMonth(2025, 2), 28));
    test('February leap year', () => expect(daysInMonth(2024, 2), 29));
    test('30-day month (April)', () => expect(daysInMonth(2025, 4), 30));
    test('31-day month (January)', () => expect(daysInMonth(2025, 1), 31));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/utils/age_check_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'capivara_2048' ... age_check.dart` / "isAtLeast12 not defined".

- [ ] **Step 3: Write minimal implementation**

Create `lib/core/utils/age_check.dart`:

```dart
// lib/core/utils/age_check.dart
//
// Pure age helpers — no Flutter dependency, unit-testable.

/// True se [birth] garante pelo menos 12 anos completos em [now].
bool isAtLeast12(DateTime birth, DateTime now) {
  final twelfthBirthday = DateTime(birth.year + 12, birth.month, birth.day);
  return !now.isBefore(twelfthBirthday);
}

/// Número de dias no [month] (1–12) de [year], tratando ano bissexto.
/// O dia 0 do mês seguinte é o último dia deste mês.
int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/utils/age_check_test.dart`
Expected: PASS — all tests green.

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/age_check.dart test/core/utils/age_check_test.dart
git commit -m "feat(age-gate): lógica pura isAtLeast12 + daysInMonth"
```

---

## Task 2: Persistência no AuthService (interface + Fake)

**Files:**
- Modify: `lib/domain/auth/auth_service.dart`
- Test: `test/domain/auth_birthdate_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/domain/auth_birthdate_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/auth/auth_service.dart';

void main() {
  group('FakeAuthService birthDate', () {
    test('getBirthDate null por padrão', () async {
      final svc = FakeAuthService();
      expect(await svc.getBirthDate(), isNull);
    });

    test('saveBirthDate persiste e getBirthDate devolve', () async {
      final svc = FakeAuthService();
      await svc.saveBirthDate(DateTime(2008, 3, 15));
      expect(await svc.getBirthDate(), DateTime(2008, 3, 15));
    });

    test('initialBirthDate é respeitado', () async {
      final svc = FakeAuthService(initialBirthDate: DateTime(1990, 1, 1));
      expect(await svc.getBirthDate(), DateTime(1990, 1, 1));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/auth_birthdate_test.dart`
Expected: FAIL — `The method 'getBirthDate' isn't defined` / `No named parameter 'initialBirthDate'`.

- [ ] **Step 3a: Add methods to the abstract interface**

In `lib/domain/auth/auth_service.dart`, dentro de `abstract class AuthService`, após `Future<void> signOut();` (linha ~23) adicione:

```dart
  Future<DateTime?> getBirthDate();
  Future<void> saveBirthDate(DateTime dob);
```

- [ ] **Step 3b: Implement in FakeAuthService**

No `class FakeAuthService`, troque o campo/construtor:

```dart
  PlayerProfile? _profile;
  DateTime? _birthDate;
  final _controller = StreamController<PlayerProfile?>.broadcast();

  FakeAuthService({PlayerProfile? initialProfile, DateTime? initialBirthDate})
      : _profile = initialProfile,
        _birthDate = initialBirthDate;
```

E adicione os dois métodos (junto aos outros overrides, ex. antes de `void dispose()`):

```dart
  @override
  Future<DateTime?> getBirthDate() async => _birthDate;

  @override
  Future<void> saveBirthDate(DateTime dob) async {
    _birthDate = dob;
  }
```

- [ ] **Step 3c: Dar data adulta ao Fake do flavor tst**

No `authServiceProvider` (final do arquivo), no `FakeAuthService(...)` de fallback, adicione `initialBirthDate` para que o gate não bloqueie fluxos tst:

```dart
  return FakeAuthService(
    initialBirthDate: DateTime(1990, 1, 1),
    initialProfile: PlayerProfile(
      userId: 'fake-user-id',
      displayName: 'Jogador Teste',
      provider: AuthProvider.google,
      createdAt: DateTime(2025, 1, 1),
      lastSeenAt: DateTime(2025, 1, 1),
      tutorialCompleted: true,
    ),
  );
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/auth_birthdate_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/auth/auth_service.dart test/domain/auth_birthdate_test.dart
git commit -m "feat(age-gate): getBirthDate/saveBirthDate no AuthService + Fake"
```

---

## Task 3: Implementação Firestore no FirebaseAuthService

**Files:**
- Modify: `lib/data/repositories/firebase_auth_service.dart`

> Sem teste unitário — depende do Firestore real. Verificação é a compilação (a interface obriga implementar) + análise estática.

- [ ] **Step 1: Implement the two methods**

Em `lib/data/repositories/firebase_auth_service.dart`, após `updateDisplayName` (antes de `sendPasswordReset`, ~linha 67), adicione:

```dart
  @override
  Future<DateTime?> getBirthDate() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final raw = snap.data()?['birthDate'];
    return raw is String ? DateTime.tryParse(raw) : null;
  }

  @override
  Future<void> saveBirthDate(DateTime dob) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final iso = '${dob.year.toString().padLeft(4, '0')}-'
        '${dob.month.toString().padLeft(2, '0')}-'
        '${dob.day.toString().padLeft(2, '0')}';
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'birthDate': iso},
      SetOptions(merge: true),
    );
  }
```

- [ ] **Step 2: Verify it compiles / analyzes**

Run: `flutter analyze lib/data/repositories/firebase_auth_service.dart lib/domain/auth/auth_service.dart`
Expected: "No issues found!" (nenhum erro de "missing concrete implementation").

- [ ] **Step 3: Commit**

```bash
git add lib/data/repositories/firebase_auth_service.dart
git commit -m "feat(age-gate): persistência de birthDate no Firestore (users/{uid})"
```

---

## Task 4: Reescrever o modal (AgeGateDialog) + helper ensureBirthDate

**Files:**
- Modify (rewrite): `lib/presentation/widgets/age_gate_dialog.dart`

> Substituição completa do arquivo. Sem teste automatizado do widget nesta task (a verificação é `flutter analyze`); o comportamento é exercitado nas telas na Task 5.

- [ ] **Step 1: Rewrite the file**

Sobrescreva `lib/presentation/widgets/age_gate_dialog.dart` com:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/age_check.dart';
import '../../domain/auth/auth_service.dart';

const _kEmerald = Color(0xFF2E7D52);
const _months = <String>[
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

/// Mostra o modal de data de nascimento. Retorna a data escolhida se o usuário
/// tem 12+ e confirmou; null se cancelou ou foi bloqueado (o próprio modal
/// exibe a mensagem de bloqueio para menores de 12).
Future<DateTime?> showAgeGateDialog(BuildContext context) {
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _AgeGateDialog(),
  );
}

/// Para os fluxos de login: garante que a conta atual tem birthDate. Lê do
/// backend; se ausente, mostra o modal e salva. Retorna false (e faz signOut)
/// se o usuário cancelar ou for menor de 12.
Future<bool> ensureBirthDate(BuildContext context, WidgetRef ref) async {
  final auth = ref.read(authServiceProvider);
  if (await auth.getBirthDate() != null) return true;
  if (!context.mounted) return false;
  final dob = await showAgeGateDialog(context);
  if (dob == null) {
    await auth.signOut();
    return false;
  }
  await auth.saveBirthDate(dob);
  return true;
}

class _AgeGateDialog extends StatefulWidget {
  const _AgeGateDialog();

  @override
  State<_AgeGateDialog> createState() => _AgeGateDialogState();
}

class _AgeGateDialogState extends State<_AgeGateDialog> {
  int? _day;
  int? _month;
  int? _year;
  bool _blocked = false;

  int get _currentYear => DateTime.now().year;

  bool get _complete => _day != null && _month != null && _year != null;

  /// Máximo de dias para a seleção atual. Sem ano definido usa 2000 (bissexto)
  /// para permitir 29 em fevereiro até o ano ser escolhido.
  int get _maxDay {
    final m = _month;
    if (m == null) return 31;
    return daysInMonth(_year ?? 2000, m);
  }

  void _clampDay() {
    if (_day != null && _day! > _maxDay) _day = null;
  }

  void _confirm() {
    if (!_complete) return;
    final birth = DateTime(_year!, _month!, _day!);
    if (!isAtLeast12(birth, DateTime.now())) {
      setState(() => _blocked = true);
      return;
    }
    Navigator.of(context).pop(birth);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _kEmerald, width: 3),
      ),
      title: Text(
        'Confirmação de idade 🌿',
        style: GoogleFonts.fredoka(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: _kEmerald,
        ),
        textAlign: TextAlign.center,
      ),
      content: _blocked ? _buildBlocked() : _buildForm(),
      actionsAlignment: MainAxisAlignment.center,
      actions: _blocked ? _blockedActions() : _formActions(),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Para criar uma conta, informe sua data de nascimento.',
          style: GoogleFonts.nunito(fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _menu(
          label: 'Dia',
          value: _day,
          entries: [
            for (var d = 1; d <= _maxDay; d++)
              DropdownMenuEntry(value: d, label: '$d'),
          ],
          search: false,
          onSelected: (v) => setState(() => _day = v),
        ),
        const SizedBox(height: 12),
        _menu(
          label: 'Mês',
          value: _month,
          entries: [
            for (var m = 1; m <= 12; m++)
              DropdownMenuEntry(value: m, label: _months[m - 1]),
          ],
          search: false,
          onSelected: (v) => setState(() {
            _month = v;
            _clampDay();
          }),
        ),
        const SizedBox(height: 12),
        _menu(
          label: 'Ano',
          value: _year,
          entries: [
            for (var y = _currentYear; y >= _currentYear - 110; y--)
              DropdownMenuEntry(value: y, label: '$y'),
          ],
          search: true,
          onSelected: (v) => setState(() {
            _year = v;
            _clampDay();
          }),
        ),
      ],
    );
  }

  Widget _menu({
    required String label,
    required int? value,
    required List<DropdownMenuEntry<int>> entries,
    required bool search,
    required ValueChanged<int?> onSelected,
  }) {
    return DropdownMenu<int>(
      // a chave força o DropdownMenu a refletir mudanças em `value`/entries
      // (ex.: dia limpo ao trocar o mês).
      key: ValueKey('$label-$value-${entries.length}'),
      expandedInsets: EdgeInsets.zero,
      initialSelection: value,
      label: Text(label, style: GoogleFonts.nunito(fontSize: 14)),
      enableFilter: search,
      enableSearch: search,
      requestFocusOnTap: search,
      menuHeight: 280,
      dropdownMenuEntries: entries,
      onSelected: onSelected,
    );
  }

  List<Widget> _formActions() => [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar',
              style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey[600])),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kEmerald,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
          onPressed: _complete ? _confirm : null,
          child: Text('Continuar',
              style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ];

  Widget _buildBlocked() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🚫', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(
          'Para criar uma conta você precisa ter pelo menos 12 anos.\n\n'
          'Você pode jogar sem conta normalmente!',
          style: GoogleFonts.nunito(fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Widget> _blockedActions() => [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kEmerald,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Entendi',
              style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ];
}
```

- [ ] **Step 2: Verify analyze (file still has unresolved callers — expected)**

Run: `flutter analyze lib/presentation/widgets/age_gate_dialog.dart`
Expected: "No issues found!" para o próprio arquivo. (As telas que ainda chamam `showAgeGateIfNeeded` darão erro só na Task 5 — não rode `flutter analyze` global ainda.)

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/age_gate_dialog.dart
git commit -m "feat(age-gate): modal com dia/mês/ano (DropdownMenu) + ensureBirthDate"
```

---

## Task 5: Ligar nos fluxos de auth

**Files:**
- Modify: `lib/presentation/screens/email_auth_screen.dart:129-161`
- Modify: `lib/presentation/screens/onboarding_auth_screen.dart:29-44`

- [ ] **Step 1: email_auth — bloco de cadastro (`if (_isSignUp)`)**

Em `lib/presentation/screens/email_auth_screen.dart`, no `_submit`, substitua o início do bloco `if (_isSignUp) {` que hoje é:

```dart
      if (_isSignUp) {
        final ageOk = await showAgeGateIfNeeded(context);
        if (!ageOk || !mounted) return;
        await controller.createAccountWithEmail(
          _emailCtrl.text.trim(),
          _passCtrl.text,
          _nameCtrl.text.trim(),
        );
```

por:

```dart
      if (_isSignUp) {
        final dob = await showAgeGateDialog(context);
        if (dob == null || !mounted) return;
        await controller.createAccountWithEmail(
          _emailCtrl.text.trim(),
          _passCtrl.text,
          _nameCtrl.text.trim(),
        );
        await ref.read(authServiceProvider).saveBirthDate(dob);
```

(O restante do bloco — navegação para `AvatarPickerScreen` — permanece igual.)

- [ ] **Step 2: email_auth — bloco de login (`else`)**

No mesmo `_submit`, no `else`, substitua:

```dart
      } else {
        await controller.signInWithEmail(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
          );
        }
      }
```

por:

```dart
      } else {
        await controller.signInWithEmail(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
        if (!mounted) return;
        final ok = await ensureBirthDate(context, ref);
        if (!ok || !mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
```

- [ ] **Step 3: onboarding — gateia após autenticar**

Em `lib/presentation/screens/onboarding_auth_screen.dart`, substitua `_handleSignIn`:

```dart
  Future<void> _handleSignIn(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      final ageOk = await showAgeGateIfNeeded(context);
      if (!ageOk || !mounted) return;
      await action();
      if (mounted) _navigateHome();
    } catch (e) {
```

por:

```dart
  Future<void> _handleSignIn(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      if (!mounted) return;
      final ok = await ensureBirthDate(context, ref);
      if (!ok || !mounted) return;
      _navigateHome();
    } catch (e) {
```

- [ ] **Step 4: Verify analyze global**

Run: `flutter analyze`
Expected: "No issues found!" — nenhuma referência restante a `showAgeGateIfNeeded`. Se aparecer "undefined name 'showAgeGateIfNeeded'", reveja Steps 1–3.

- [ ] **Step 5: Run full test suite**

Run: `flutter test`
Expected: PASS — incluindo `age_check_test.dart` e `auth_birthdate_test.dart`; nenhum teste existente quebrado.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/screens/email_auth_screen.dart lib/presentation/screens/onboarding_auth_screen.dart
git commit -m "feat(age-gate): cadastro gateia antes; logins gateiam após autenticar"
```

---

## Task 6: Verificação final e documentação

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Smoke manual (flavor tst)**

Run: `flutter run --flavor tst --dart-define=FLAVOR=dev`
Verificar:
- Cadastro por e-mail abre o modal com Dia/Mês/Ano; o select de Ano filtra por digitação.
- Trocar para um mês de fevereiro após escolher dia 31 limpa o dia.
- Data que dá <12 anos completos mostra a tela de bloqueio "pelo menos 12 anos".
- Data 12+ prossegue para o seletor de avatar.

(No flavor tst o login social usa `FakeAuthService` com data adulta → não reabre o modal, confirmando o caminho "já respondeu".)

- [ ] **Step 2: Atualizar CHANGELOG**

Adicione no topo de `CHANGELOG.md` uma entrada descrevendo: gate de idade agora coleta dia/mês/ano (12 anos completos garantidos), data salva por conta no Firestore, contas antigas re-perguntadas no próximo login. Siga o formato/versão já usados no arquivo.

- [ ] **Step 3: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs(changelog): age gate por data completa"
```

---

## Notas de escopo (do spec)

- Re-pergunta ocorre **no próximo login**; sessão já persistida não é re-perguntada no startup.
- `PlayerProfile` **não** ganha campo `birthDate` (não é lido do Firestore; nenhuma UI consome).
- Sem backfill server-side: a ausência de `birthDate` é o sinal de "precisa perguntar".
- Jogo anônimo ("jogar sem conta") continua sem gate.
