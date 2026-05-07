# Fase 4: Auth Completo, Avatar e Polimento Visual — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Completar a Fase 4 com criação de conta por e-mail, tela de e-mail dedicada com validação, seleção de avatar com tiles do jogo, destaque do perfil na Home e correção de legibilidade.

**Architecture:** Novo método `updateAvatar()` no `SyncEngine`/`AuthController` persiste avatar como string `"tile:NomeAnimal"` no Firestore. Widget `AvatarWidget` reutilizável centraliza a renderização do avatar (tile asset, inicial ou ícone padrão). Duas novas telas: `EmailAuthScreen` e `AvatarPickerScreen`.

**Tech Stack:** Flutter/Dart, Riverpod, Firebase Auth, Firestore (via `SyncEngine`), `flutter_riverpod`, `google_fonts`.

---

## Arquivo map

| Arquivo | Ação |
|---|---|
| `lib/domain/sync/sync_engine.dart` | Adicionar `updateAvatar()` à interface e ao `FakeSyncEngine` |
| `lib/data/repositories/firebase_sync_engine.dart` | Implementar `updateAvatar()` (Firestore update) |
| `lib/presentation/controllers/auth_controller.dart` | Novo método `updateAvatar()` |
| `lib/presentation/widgets/avatar_widget.dart` | **NOVO** — widget reutilizável de avatar |
| `lib/presentation/screens/avatar_picker_screen.dart` | **NOVO** — grid de tiles para escolha |
| `lib/presentation/screens/email_auth_screen.dart` | **NOVO** — tela completa de e-mail/senha |
| `lib/presentation/screens/onboarding_auth_screen.dart` | Logo maior; botão e-mail → `EmailAuthScreen` |
| `lib/presentation/screens/home_screen.dart` | `IconButton` → `AvatarWidget` com círculo verde |
| `lib/presentation/screens/profile_screen.dart` | Botão editar avatar; usar `AvatarWidget` |
| `lib/presentation/screens/invite_friends_screen.dart` | Textos com `outlinedWhiteTextStyle` |
| `test/domain/auth/auth_controller_test.dart` | Adicionar testes para `updateAvatar()` |

---

## Task 1: `updateAvatar()` no SyncEngine + AuthController

**Files:**
- Modify: `lib/domain/sync/sync_engine.dart`
- Modify: `lib/data/repositories/firebase_sync_engine.dart`
- Modify: `lib/presentation/controllers/auth_controller.dart`
- Modify: `test/domain/auth/auth_controller_test.dart`

- [ ] **Step 1.1: Adicionar `updateAvatar()` à interface `SyncEngine` e ao `FakeSyncEngine`**

Em `lib/domain/sync/sync_engine.dart`, adicionar à interface abstrata:
```dart
Future<void> updateAvatar(String? avatarUrl);
```

No `FakeSyncEngine`, adicionar a implementação e o rastreador:
```dart
String? lastAvatarUrl = _sentinel;
static const _sentinel = '__not_set__';

@override
Future<void> updateAvatar(String? avatarUrl) async {
  lastAvatarUrl = avatarUrl;
}
```

- [ ] **Step 1.2: Implementar `updateAvatar()` no `FirebaseSyncEngine`**

Em `lib/data/repositories/firebase_sync_engine.dart`, adicionar após `syncProfile()`:
```dart
@override
Future<void> updateAvatar(String? avatarUrl) async {
  if (_userId == null) return;
  await _firestore.collection('users').doc(_userId).set(
    {'avatarUrl': avatarUrl},
    SetOptions(merge: true),
  );
}
```

- [ ] **Step 1.3: Adicionar `updateAvatar()` ao `AuthController`**

Em `lib/presentation/controllers/auth_controller.dart`, adicionar após `signOut()`:
```dart
Future<void> updateAvatar(String? avatarAsset) async {
  if (state == null) return;
  await ref.read(syncEngineProvider).updateAvatar(avatarAsset);
  state = state!.copyWith(avatarUrl: avatarAsset);
}
```

- [ ] **Step 1.4: Escrever testes para `updateAvatar()`**

Em `test/domain/auth/auth_controller_test.dart`, adicionar dentro de `main()`:
```dart
test('updateAvatar atualiza estado local e chama syncEngine', () async {
  await container.read(authControllerProvider.notifier).signInWithGoogle();
  await container
      .read(authControllerProvider.notifier)
      .updateAvatar('tile:Capivara');
  final profile = container.read(authControllerProvider);
  expect(profile!.avatarUrl, 'tile:Capivara');
  expect(fakeSyncEngine.lastAvatarUrl, 'tile:Capivara');
});

test('updateAvatar com null limpa o avatar', () async {
  await container.read(authControllerProvider.notifier).signInWithGoogle();
  await container
      .read(authControllerProvider.notifier)
      .updateAvatar('tile:Onca');
  await container
      .read(authControllerProvider.notifier)
      .updateAvatar(null);
  final profile = container.read(authControllerProvider);
  expect(profile!.avatarUrl, isNull);
  expect(fakeSyncEngine.lastAvatarUrl, isNull);
});

test('updateAvatar não faz nada se não logado', () async {
  await container
      .read(authControllerProvider.notifier)
      .updateAvatar('tile:Tucano');
  expect(container.read(authControllerProvider), isNull);
  expect(fakeSyncEngine.lastAvatarUrl, FakeSyncEngine._sentinel);
});
```

> **Nota:** o campo `_sentinel` no `FakeSyncEngine` é `static const`, precisa ser `static` para ser acessado como `FakeSyncEngine._sentinel` no teste. Ajustar visibilidade se necessário usando `'__not_set__'` diretamente na asserção.

- [ ] **Step 1.5: Rodar os testes**

```bash
cd /home/giuliano/rf/capivara_2048
flutter test test/domain/auth/auth_controller_test.dart
```

Esperado: todos os testes passam.

- [ ] **Step 1.6: Commit**

```bash
git add lib/domain/sync/sync_engine.dart \
        lib/data/repositories/firebase_sync_engine.dart \
        lib/presentation/controllers/auth_controller.dart \
        test/domain/auth/auth_controller_test.dart
git commit -m "feat: updateAvatar no SyncEngine e AuthController"
```

---

## Task 2: `AvatarWidget` — widget reutilizável

**Files:**
- Create: `lib/presentation/widgets/avatar_widget.dart`

- [ ] **Step 2.1: Criar `AvatarWidget`**

Criar `lib/presentation/widgets/avatar_widget.dart`:
```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/player_profile.dart';

/// Mapa de nome do animal para o asset do tile correspondente.
const Map<String, String> kAnimalTileAssets = {
  'Tanajura': 'assets/images/animals/tile/Tanajura.png',
  'LoboGuara': 'assets/images/animals/tile/LoboGuara.png',
  'Cururu': 'assets/images/animals/tile/Cururu.png',
  'Tucano': 'assets/images/animals/tile/Tucano.png',
  'Sagui': 'assets/images/animals/tile/Sagui.png',
  'Preguica': 'assets/images/animals/tile/Preguica.png',
  'MicoLeao': 'assets/images/animals/tile/MicoLeao.png',
  'Boto': 'assets/images/animals/tile/Boto.png',
  'Onca': 'assets/images/animals/tile/Onca.png',
  'Sucuri': 'assets/images/animals/tile/Sucuri.png',
  'Capivara': 'assets/images/animals/tile/Capivara.png',
  'PeixeBoi': 'assets/images/animals/tile/PeixeBoi.png',
  'Jacare': 'assets/images/animals/tile/Jacare.png',
};

/// Lista ordenada dos animais disponíveis como avatar (ordem do jogo).
const List<String> kAvatarAnimals = [
  'Tanajura', 'LoboGuara', 'Cururu', 'Tucano', 'Sagui', 'Preguica',
  'MicoLeao', 'Boto', 'Onca', 'Sucuri', 'Capivara', 'PeixeBoi', 'Jacare',
];

/// Widget de avatar reutilizável.
///
/// Renderiza:
/// - Avatar tile animal (`"tile:NomeAnimal"`) → Image.asset
/// - URL HTTP (Google/Apple) → NetworkImage
/// - null / sem prefixo → inicial do displayName sobre fundo verde
/// - profile null → Icons.person_outline sobre fundo verde
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    required this.radius,
    this.profile,
  });

  final double radius;
  final PlayerProfile? profile;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile?.avatarUrl;

    if (avatarUrl != null && avatarUrl.startsWith('tile:')) {
      final animalName = avatarUrl.substring(5); // remove "tile:"
      final asset = kAnimalTileAssets[animalName];
      if (asset != null) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary,
          child: ClipOval(
            child: Image.asset(
              asset,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    }

    if (avatarUrl != null && avatarUrl.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary,
        backgroundImage: NetworkImage(avatarUrl),
      );
    }

    // Inicial ou ícone padrão
    final initial = profile?.displayName.isNotEmpty == true
        ? profile!.displayName[0].toUpperCase()
        : null;

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: initial != null
          ? Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.9,
                fontWeight: FontWeight.bold,
              ),
            )
          : Icon(Icons.person_outline, color: Colors.white, size: radius * 1.2),
    );
  }
}
```

- [ ] **Step 2.2: Verificar que compila**

```bash
cd /home/giuliano/rf/capivara_2048
flutter analyze lib/presentation/widgets/avatar_widget.dart
```

Esperado: sem erros.

- [ ] **Step 2.3: Commit**

```bash
git add lib/presentation/widgets/avatar_widget.dart
git commit -m "feat: AvatarWidget reutilizável com suporte a tile, URL e inicial"
```

---

## Task 3: `AvatarPickerScreen`

**Files:**
- Create: `lib/presentation/screens/avatar_picker_screen.dart`

- [ ] **Step 3.1: Criar `AvatarPickerScreen`**

Criar `lib/presentation/screens/avatar_picker_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../controllers/auth_controller.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/game_background.dart';

/// Tela de seleção de avatar com tiles do jogo.
///
/// [onDone] é chamado após salvar ou pular — permite ao chamador
/// decidir a navegação (ex: ir para HomeScreen ou voltar).
class AvatarPickerScreen extends ConsumerStatefulWidget {
  const AvatarPickerScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends ConsumerState<AvatarPickerScreen> {
  String? _selected;
  bool _saving = false;

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateAvatar('tile:$_selected');
      if (mounted) widget.onDone();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar avatar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _skip() => widget.onDone();

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Escolha seu avatar',
            style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Qual animal vai te representar?',
                style: outlinedWhiteTextStyle(
                  GoogleFonts.nunito(fontSize: 15),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: kAvatarAnimals.length,
                  itemBuilder: (context, index) {
                    final animal = kAvatarAnimals[index];
                    final isSelected = _selected == animal;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = animal),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.4),
                                    blurRadius: 8,
                                  )
                                ]
                              : [],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            kAnimalTileAssets[animal]!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed:
                          (_selected != null && !_saving) ? _confirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Confirmar',
                              style: GoogleFonts.fredoka(fontSize: 18),
                            ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _saving ? null : _skip,
                      child: Text(
                        'Pular por agora',
                        style: outlinedWhiteTextStyle(
                          GoogleFonts.nunito(
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3.2: Verificar que compila**

```bash
cd /home/giuliano/rf/capivara_2048
flutter analyze lib/presentation/screens/avatar_picker_screen.dart
```

Esperado: sem erros.

- [ ] **Step 3.3: Commit**

```bash
git add lib/presentation/screens/avatar_picker_screen.dart
git commit -m "feat: AvatarPickerScreen com grid de tiles do jogo"
```

---

## Task 4: `EmailAuthScreen`

**Files:**
- Create: `lib/presentation/screens/email_auth_screen.dart`

- [ ] **Step 4.1: Criar `EmailAuthScreen`**

Criar `lib/presentation/screens/email_auth_screen.dart`:
```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/home_constants.dart';
import '../../core/theme/text_styles.dart';
import '../controllers/auth_controller.dart';
import '../widgets/game_background.dart';
import '../widgets/game_title_image.dart';
import 'avatar_picker_screen.dart';
import 'home_screen.dart';

class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isSignUp = false;
  bool _loading = false;
  bool _showPass = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
    final re = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!re.hasMatch(v.trim())) return 'E-mail inválido';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Informe a senha';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'\d').hasMatch(v)) return 'Deve conter ao menos 1 número';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _passCtrl.text) return 'As senhas não conferem';
    return null;
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'Senha muito fraca.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente mais tarde.';
      case 'network-request-failed':
        return 'Sem conexão. Verifique sua internet.';
      default:
        return 'Erro ao autenticar. Tente novamente.';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final controller = ref.read(authControllerProvider.notifier);
      if (_isSignUp) {
        await controller.createAccountWithEmail(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => AvatarPickerScreen(
                onDone: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                ),
              ),
            ),
            (_) => false,
          );
        }
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
    } catch (e) {
      if (mounted) {
        final code = e.toString().contains('firebase_auth/')
            ? e.toString().split('firebase_auth/')[1].split(']')[0].trim()
            : e.toString().split('[')[0].trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mapFirebaseError(code))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = min(size.width / 390.0, size.height / 844.0).clamp(0.1, 1.0);

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: size.height * 0.06),
                  GameTitleImage(
                    asset: GameTitleImage.pickAsset(),
                    height: HomeConstants.titleHeight(scale),
                  ),
                  const SizedBox(height: 32),
                  // Toggle Entrar / Criar Conta
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _ToggleTab(
                          label: 'Entrar',
                          selected: !_isSignUp,
                          onTap: () =>
                              setState(() => _isSignUp = false),
                        ),
                        _ToggleTab(
                          label: 'Criar conta',
                          selected: _isSignUp,
                          onTap: () =>
                              setState(() => _isSignUp = true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Campos
                  _AuthField(
                    controller: _emailCtrl,
                    label: 'E-mail',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 12),
                  _AuthField(
                    controller: _passCtrl,
                    label: 'Senha',
                    obscureText: !_showPass,
                    validator: _validatePassword,
                    suffix: IconButton(
                      icon: Icon(
                        _showPass
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white70,
                      ),
                      onPressed: () =>
                          setState(() => _showPass = !_showPass),
                    ),
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 12),
                    _AuthField(
                      controller: _confirmCtrl,
                      label: 'Confirmar senha',
                      obscureText: !_showConfirm,
                      validator: _validateConfirm,
                      suffix: IconButton(
                        icon: Icon(
                          _showConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () =>
                            setState(() => _showConfirm = !_showConfirm),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (_loading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isSignUp ? 'Criar conta' : 'Entrar',
                        style: GoogleFonts.fredoka(fontSize: 18),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      '← Voltar',
                      style: outlinedWhiteTextStyle(
                        GoogleFonts.nunito(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              color: selected ? AppColors.primary : Colors.white,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.autofillHints,
    this.obscureText = false,
    this.validator,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }
}
```

- [ ] **Step 4.2: Verificar que compila**

```bash
cd /home/giuliano/rf/capivara_2048
flutter analyze lib/presentation/screens/email_auth_screen.dart
```

Esperado: sem erros.

- [ ] **Step 4.3: Commit**

```bash
git add lib/presentation/screens/email_auth_screen.dart
git commit -m "feat: EmailAuthScreen com validação e toggle entrar/criar conta"
```

---

## Task 5: `OnboardingAuthScreen` — logo maior + navegar para `EmailAuthScreen`

**Files:**
- Modify: `lib/presentation/screens/onboarding_auth_screen.dart`

- [ ] **Step 5.1: Ajustar `OnboardingAuthScreen`**

Em `lib/presentation/screens/onboarding_auth_screen.dart`:

1. Adicionar imports necessários:
```dart
import 'dart:math';
import '../../core/constants/home_constants.dart';
import 'email_auth_screen.dart';
```

2. Substituir o `build` para calcular scale e usar logo responsivo:

Localizar:
```dart
  @override
  Widget build(BuildContext context) {
    final controller = ref.read(authControllerProvider.notifier);

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameTitleImage(asset: GameTitleImage.pickAsset(), height: 80),
```

Substituir por:
```dart
  @override
  Widget build(BuildContext context) {
    final controller = ref.read(authControllerProvider.notifier);
    final size = MediaQuery.of(context).size;
    final scale =
        min(size.width / 390.0, size.height / 844.0).clamp(0.1, 1.0);

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameTitleImage(
                  asset: GameTitleImage.pickAsset(),
                  height: HomeConstants.titleHeight(scale),
                ),
```

3. Substituir o `onPressed` do botão "Entrar com Email":

Localizar:
```dart
                  _AuthButton(
                    label: 'Entrar com Email',
                    icon: Icons.email_outlined,
                    onPressed: () => _showEmailDialog(context, controller),
                  ),
```

Substituir por:
```dart
                  _AuthButton(
                    label: 'Entrar com Email',
                    icon: Icons.email_outlined,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EmailAuthScreen(),
                      ),
                    ),
                  ),
```

4. Remover o método `_showEmailDialog` inteiro (não é mais usado).

- [ ] **Step 5.2: Verificar que compila**

```bash
cd /home/giuliano/rf/capivara_2048
flutter analyze lib/presentation/screens/onboarding_auth_screen.dart
```

Esperado: sem erros.

- [ ] **Step 5.3: Commit**

```bash
git add lib/presentation/screens/onboarding_auth_screen.dart
git commit -m "feat: logo responsivo e navegação para EmailAuthScreen"
```

---

## Task 6: Home — avatar com círculo verde

**Files:**
- Modify: `lib/presentation/screens/home_screen.dart`

- [ ] **Step 6.1: Substituir `IconButton` por `AvatarWidget` na `HomeScreen`**

Adicionar import em `home_screen.dart`:
```dart
import '../widgets/avatar_widget.dart';
```

Localizar o bloco do perfil:
```dart
              // Topo centro — Perfil
              Positioned(
                top: HomeConstants.edgePad(scale),
                left: 0,
                right: 0,
                child: Center(
                  child: IconButton(
                    key: const Key('home_btn_perfil'),
                    icon: Icon(
                      playerProfile != null
                          ? Icons.person
                          : Icons.person_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                    tooltip: 'Perfil',
                    onPressed: () => _nav(const ProfileScreen()),
                  ),
                ),
              ),
```

Substituir por:
```dart
              // Topo centro — Perfil
              Positioned(
                top: HomeConstants.edgePad(scale),
                left: 0,
                right: 0,
                child: Center(
                  child: Tooltip(
                    message: 'Perfil',
                    child: GestureDetector(
                      key: const Key('home_btn_perfil'),
                      onTap: () => _nav(const ProfileScreen()),
                      child: AvatarWidget(
                        radius: 20,
                        profile: playerProfile,
                      ),
                    ),
                  ),
                ),
              ),
```

- [ ] **Step 6.2: Verificar que compila**

```bash
cd /home/giuliano/rf/capivara_2048
flutter analyze lib/presentation/screens/home_screen.dart
```

Esperado: sem erros.

- [ ] **Step 6.3: Commit**

```bash
git add lib/presentation/screens/home_screen.dart
git commit -m "feat: avatar com círculo verde na Home"
```

---

## Task 7: `ProfileScreen` — usar `AvatarWidget` + botão editar avatar

**Files:**
- Modify: `lib/presentation/screens/profile_screen.dart`

- [ ] **Step 7.1: Atualizar `ProfileScreen`**

Adicionar imports:
```dart
import '../widgets/avatar_widget.dart';
import 'avatar_picker_screen.dart';
```

Na classe `_LoggedIn`, substituir o bloco do `CircleAvatar` no topo:

Localizar:
```dart
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
        ),
```

Substituir por:
```dart
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarWidget(radius: 40, profile: profile),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AvatarPickerScreen(
                        onDone: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D52),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
```

- [ ] **Step 7.2: Verificar que compila**

```bash
cd /home/giuliano/rf/capivara_2048
flutter analyze lib/presentation/screens/profile_screen.dart
```

Esperado: sem erros.

- [ ] **Step 7.3: Commit**

```bash
git add lib/presentation/screens/profile_screen.dart
git commit -m "feat: AvatarWidget e botão editar avatar na ProfileScreen"
```

---

## Task 8: "Convidar Amigos" — legibilidade dos textos

**Files:**
- Modify: `lib/presentation/screens/invite_friends_screen.dart`

- [ ] **Step 8.1: Corrigir textos com `outlinedWhiteTextStyle`**

Em `lib/presentation/screens/invite_friends_screen.dart`, adicionar import se não existir:
```dart
import '../../core/theme/text_styles.dart';
```

Localizar e substituir os dois textos com `Colors.white70`:

**Texto 1 — descrição de recompensas:**
```dart
// antes
                    Text(
                      'Você e seu amigo recebem 2 vidas + 1× Bomba 2\nquando ele completar a primeira partida.',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
// depois
                    Text(
                      'Você e seu amigo recebem 2 vidas + 1× Bomba 2\nquando ele completar a primeira partida.',
                      style: outlinedWhiteTextStyle(
                        GoogleFonts.nunito(fontSize: 14),
                      ),
                      textAlign: TextAlign.center,
                    ),
```

**Texto 2 — "Faça login para convidar":**
```dart
// antes
                        Text(
                          'Faça login para convidar amigos.',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                        )
// depois
                        Text(
                          'Faça login para convidar amigos.',
                          style: outlinedWhiteTextStyle(
                            GoogleFonts.nunito(fontSize: 15),
                          ),
                        )
```

- [ ] **Step 8.2: Verificar que compila**

```bash
cd /home/giuliano/rf/capivara_2048
flutter analyze lib/presentation/screens/invite_friends_screen.dart
```

Esperado: sem erros.

- [ ] **Step 8.3: Commit**

```bash
git add lib/presentation/screens/invite_friends_screen.dart
git commit -m "fix: textos legíveis em InviteFriendsScreen com outlinedWhiteTextStyle"
```

---

## Task 9: Verificação final

- [ ] **Step 9.1: Rodar todos os testes**

```bash
cd /home/giuliano/rf/capivara_2048
flutter test
```

Esperado: todos passam.

- [ ] **Step 9.2: Analyze geral**

```bash
cd /home/giuliano/rf/capivara_2048
flutter analyze
```

Esperado: sem erros (warnings aceitáveis se pré-existentes).

- [ ] **Step 9.3: Atualizar CHANGELOG, README e AGENTS.md**

Em `CHANGELOG.md`, adicionar no topo:
```
## [1.5.0] — 2026-05-07
### Added
- EmailAuthScreen: tela dedicada de e-mail/senha com validação robusta e toggle entrar/criar conta
- AvatarPickerScreen: seleção de avatar com tiles do jogo (13 animais)
- AvatarWidget: widget reutilizável de avatar (tile, URL HTTP, inicial, ícone padrão)
- updateAvatar() no AuthController e SyncEngine
- Avatar com círculo verde de destaque na Home
- Botão editar avatar na ProfileScreen

### Fixed
- Logo na tela de login agora tem o mesmo tamanho da Home
- Textos legíveis na tela "Convidar Amigos" (outlinedWhiteTextStyle)
```

Em `AGENTS.md`, atualizar a fase atual para **Fase 4 completa (v1.5.0)**.

- [ ] **Step 9.4: Commit final**

```bash
git add CHANGELOG.md AGENTS.md README.md
git commit -m "chore: release v1.5.0 — Fase 4 completa"
```
