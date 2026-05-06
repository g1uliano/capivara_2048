# Firebase — Guia de Configuração

Este documento descreve o passo a passo completo para configurar o Firebase no projeto **Olha o Bichim!**. Siga este guia antes de iniciar a implementação da Sub-A (Fase 4).

> **Dois projetos Firebase:** use projetos separados para desenvolvimento (`bichim-dev`) e produção (`bichim-prd`). Nunca aponte o build de desenvolvimento para o projeto de produção.

---

## Índice

1. [Pré-requisitos](#1-pré-requisitos)
2. [Criar projetos Firebase](#2-criar-projetos-firebase)
3. [Registrar apps Android](#3-registrar-apps-android)
4. [Registrar apps iOS](#4-registrar-apps-ios)
5. [FlutterFire CLI](#5-flutterfire-cli)
6. [Habilitar Auth providers](#6-habilitar-auth-providers)
7. [Configurar Google Sign-In (Android)](#7-configurar-google-sign-in-android)
8. [Configurar Apple Sign-In (iOS)](#8-configurar-apple-sign-in-ios)
9. [Criar banco Firestore](#9-criar-banco-firestore)
10. [Security Rules iniciais](#10-security-rules-iniciais)
11. [Firebase Emulator Suite (desenvolvimento local)](#11-firebase-emulator-suite-desenvolvimento-local)
12. [Variáveis de ambiente e flavors](#12-variáveis-de-ambiente-e-flavors)
13. [Checklist de verificação](#13-checklist-de-verificação)

---

## 1. Pré-requisitos

- Conta Google com acesso ao [Firebase Console](https://console.firebase.google.com)
- Node.js 18+ instalado (`node --version`)
- Flutter SDK 3.x instalado e no PATH
- Conta Apple Developer (para Apple Sign-In e build iOS)
- Firebase CLI instalado:
  ```bash
  npm install -g firebase-tools
  firebase login
  firebase --version   # deve ser 13+
  ```
- FlutterFire CLI instalado:
  ```bash
  dart pub global activate flutterfire_cli
  flutterfire --version
  ```

---

## 2. Criar projetos Firebase

### 2.1 Projeto de desenvolvimento

1. Acesse [console.firebase.google.com](https://console.firebase.google.com)
2. Clique em **"Adicionar projeto"**
3. Nome: `Olha o Bichim Dev` / ID sugerido: `bichim-dev`
4. **Desative** o Google Analytics (não necessário para dev)
5. Clique em **"Criar projeto"**

### 2.2 Projeto de produção

Repita os passos acima com:

- Nome: `Olha o Bichim` / ID sugerido: `bichim-prd`
- **Ative** o Google Analytics (necessário para dados de uso em produção)

---

## 3. Registrar apps Android

Repita para cada projeto (`bichim-dev` e `bichim-prd`):

1. No Console Firebase, clique no ícone Android **"</>"**
2. **Package name:**
   - Dev: `com.seunome.capivara2048.dev`
   - Prd: `com.seunome.capivara2048`
3. **App nickname:** `Olha o Bichim Android (dev)` / `(prd)`
4. **Debug signing certificate SHA-1** (necessário para Google Sign-In):
   ```bash
   # No diretório do projeto Flutter:
   cd android
   ./gradlew signingReport
   # Copie o SHA-1 do variant "debug"
   ```
5. Clique em **"Registrar app"**
6. Faça download do `google-services.json`
7. Salve em:
   - Dev: `android/app/src/dev/google-services.json`
   - Prd: `android/app/src/prd/google-services.json`

> **Atenção:** não commite `google-services.json` no repositório. Adicione ao `.gitignore`:
>
> ```
> android/app/src/dev/google-services.json
> android/app/src/prd/google-services.json
> ```

---

## 4. Registrar apps iOS

Repita para cada projeto (`bichim-dev` e `bichim-prd`):

1. No Console Firebase, clique no ícone iOS **"</>"**
2. **Bundle ID:**
   - Dev: `com.seunome.capivara2048.dev`
   - Prd: `com.seunome.capivara2048`
3. **App nickname:** `Olha o Bichim iOS (dev)` / `(prd)`
4. Clique em **"Registrar app"**
5. Faça download do `GoogleService-Info.plist`
6. No Xcode, adicione o arquivo ao target `Runner`:
   - Dev: `ios/Runner/dev/GoogleService-Info.plist`
   - Prd: `ios/Runner/prd/GoogleService-Info.plist`

> **Atenção:** não commite `GoogleService-Info.plist`. Adicione ao `.gitignore`:
>
> ```
> ios/Runner/dev/GoogleService-Info.plist
> ios/Runner/prd/GoogleService-Info.plist
> ```

---

## 5. FlutterFire CLI

O FlutterFire CLI gera o arquivo `firebase_options.dart` automaticamente com as configurações de cada plataforma.

### 5.1 Configurar flavor dev

```bash
flutterfire configure \
  --project=olha-o-bichim-dev \
  --out=lib/firebase_options_dev.dart \
  --platforms=android,ios
```

### 5.2 Configurar flavor prd

```bash
flutterfire configure \
  --project=bichim-prd \
  --out=lib/firebase_options_prd.dart \
  --platforms=android,ios
```

### 5.3 Inicializar no main.dart

```dart
// lib/main.dart
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prd.dart' as prd;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  final options = flavor == 'prd'
      ? prd.DefaultFirebaseOptions.currentPlatform
      : dev.DefaultFirebaseOptions.currentPlatform;

  await Firebase.initializeApp(options: options);
  runApp(const ProviderScope(child: App()));
}
```

> **Nota:** `firebase_options_dev.dart` e `firebase_options_prd.dart` contêm chaves de API — adicione ao `.gitignore` se o repositório for público. Para repositórios privados, commitar é aceitável.

---

## 6. Habilitar Auth providers

Repita para cada projeto (`bichim-dev` e `bichim-prd`):

1. No Console Firebase → **Authentication** → **Sign-in method**
2. Habilite:
   - **Google** → clique em Google → ative → salve o `Web client ID` (necessário para Android)
   - **Apple** → clique em Apple → ative (configuração adicional necessária — ver Seção 8)
   - **E-mail/senha** → ative a primeira opção (sem link mágico)

---

## 7. Configurar Google Sign-In (Android)

### 7.1 SHA-1 de release

Para produção, adicione também o SHA-1 do keystore de release:

```bash
keytool -list -v \
  -keystore ~/upload-keystore.jks \
  -alias upload \
  -storepass [senha]
```

Adicione o SHA-1 no Console Firebase → Project Settings → Seu app Android.

### 7.2 android/app/build.gradle.kts

> **Nota:** este projeto usa Kotlin DSL (`.gradle.kts`), não Groovy.

O `flutterfire configure` já adiciona automaticamente o plugin. Confirme que
`android/app/build.gradle.kts` contém:

```kotlin
plugins {
    // ...
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // ...
}
```

### 7.3 android/settings.gradle.kts

Confirme que `android/settings.gradle.kts` contém na seção `plugins`:

```kotlin
// START: FlutterFire Configuration
id("com.google.gms.google-services") version("4.3.15") apply false
// END: FlutterFire Configuration
```

Se os blocos `// START: FlutterFire Configuration` já estiverem presentes (adicionados
pelo `flutterfire configure`), nenhuma ação manual é necessária.

---

## 8. Configurar Apple Sign-In (iOS)

Apple Sign-In requer configuração no Apple Developer Console **além** do Firebase.

### 8.1 Apple Developer Console

1. Acesse [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles**
2. Selecione seu App ID (`com.seunome.capivara2048`)
3. Habilite a capability **Sign In with Apple**
4. Crie um **Service ID** para o Firebase:
   - Identifier: `com.seunome.capivara2048.signin`
   - Habilite **Sign In with Apple**
   - Configure o domínio: `bichim-prd.firebaseapp.com`
   - Return URL: `https://bichim-prd.firebaseapp.com/__/auth/handler`
5. Crie uma **Key** com Sign In with Apple habilitado
   - Faça download do arquivo `.p8`
   - Anote o Key ID e o Team ID

### 8.2 Firebase Console — Apple provider

Em Authentication → Sign-in method → Apple:

- **Services ID:** `com.seunome.capivara2048.signin`
- **Apple Team ID:** (do Developer Console)
- **Key ID:** (da Key criada)
- **Private Key (.p8):** faça upload do arquivo

### 8.3 Xcode — capability

1. Abra `ios/Runner.xcworkspace` no Xcode
2. Target Runner → **Signing & Capabilities** → **+ Capability**
3. Adicione **Sign In with Apple**

---

## 9. Criar banco Firestore

Repita para cada projeto:

1. Console Firebase → **Firestore Database** → **Criar banco de dados**
2. **Modo de produção** (regras restritivas — serão configuradas na Seção 10)
3. **Localização:** `southamerica-east1` (São Paulo) — menor latência para Brasil
4. Clique em **"Criar"**

---

## 10. Security Rules iniciais

No Console Firebase → Firestore → **Rules**, cole e publique:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Usuários: leitura e escrita somente pelo próprio userId
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /personalRecords/{doc} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /inventory/{doc} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Rankings semanais: leitura pública; escrita somente pelo userId da entry
    match /rankings/{weekId}/entries/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /rankings/{weekId}/meta {
      allow read: if true;
      // meta é escrito pelo primeiro jogador que detecta o novo weekId
      allow write: if request.auth != null;
    }

    // Ranking Lendas: leitura pública; escrita somente pelo userId da entry
    match /legendsRankings/{level}/entries/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Convites: convidante gerencia; convidado pode atualizar status
    match /invites/{inviterId} {
      allow read, write: if request.auth != null && request.auth.uid == inviterId;
      // Convidado pode atualizar o status do próprio convite
      allow update: if request.auth != null;
    }

    // ShareCodes: leitura pública para resgate; escrita pelo criador ou resgatador
    match /shareCodes/{code} {
      allow read: if true;
      allow create: if request.auth != null
        && request.resource.data.createdByUserId == request.auth.uid;
      allow update: if request.auth != null
        && (resource.data.createdByUserId == request.auth.uid
            || resource.data.status == 'pending');
    }

    // Compras: somente pelo próprio userId
    match /purchases/{userId}/{purchaseId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

> **Nota:** estas são as regras iniciais para desenvolvimento. Revisar antes do lançamento — especialmente as regras de `rankings/meta` e `invites` que permitem escrita mais ampla.

---

## 11. Firebase Emulator Suite (desenvolvimento local)

O emulador permite desenvolver e testar sem tocar nos dados de produção.

### 11.1 Instalar e inicializar

```bash
# Na raiz do projeto
firebase init emulators

# Selecione: Authentication, Firestore
# Portas padrão:
#   Auth:      9099
#   Firestore: 8080
#   UI:        4000
```

Isso cria `firebase.json` e `.firebaserc` na raiz.

### 11.2 Iniciar emuladores

```bash
firebase emulators:start
# Acesse a UI em: http://localhost:4000
```

### 11.3 Conectar o app ao emulador (flavor dev)

```dart
// lib/data/repositories/firebase_sync_engine.dart
// Ou em um arquivo de configuração de dev

if (flavor == 'dev') {
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
}
```

> **Dica:** emuladores preservam dados apenas durante a sessão. Para seeds de teste, crie um script `scripts/seed_emulator.dart`.

---

## 12. Variáveis de ambiente e flavors

### 12.1 Dart defines

Ad Unit IDs e outras configs sensíveis são passadas via `--dart-define`, nunca hardcoded:

```bash
# Desenvolvimento
flutter run \
  --dart-define=FLAVOR=dev \
  --dart-define=AD_UNIT_ANDROID=ca-app-pub-3940256099942544/5224354917 \  # test ID
  --dart-define=AD_UNIT_IOS=ca-app-pub-3940256099942544/1712485313         # test ID

# Produção
flutter build apk \
  --dart-define=FLAVOR=prd \
  --dart-define=AD_UNIT_ANDROID=ca-app-pub-XXXXX/XXXXX \
  --dart-define=AD_UNIT_IOS=ca-app-pub-XXXXX/XXXXX
```

### 12.2 Leitura no código

```dart
// lib/core/constants/ad_config.dart
class AdConfig {
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const adUnitAndroid = String.fromEnvironment('AD_UNIT_ANDROID');
  static const adUnitIos = String.fromEnvironment('AD_UNIT_IOS');
  static const maxAdsPerDay = 40;
}
```

### 12.3 CI/CD (GitHub Actions)

Os valores de produção são armazenados como **GitHub Secrets** e injetados no workflow:

```yaml
# .github/workflows/release.yml
- name: Build APK
  run: flutter build apk --dart-define=FLAVOR=prd --dart-define=AD_UNIT_ANDROID=${{ secrets.AD_UNIT_ANDROID }}
```

---

## 13. Checklist de verificação

Antes de iniciar a implementação da Sub-A, confirme:

### Firebase Console

- [ ] Projeto `bichim-dev` criado
- [ ] Projeto `bichim-prd` criado
- [ ] App Android registrado em ambos os projetos (com SHA-1 debug e release)
- [ ] App iOS registrado em ambos os projetos
- [ ] `google-services.json` baixado e salvo nos diretórios corretos
- [ ] `GoogleService-Info.plist` baixado e adicionado ao Xcode
- [ ] Auth habilitado: Google, Apple, Email/senha em ambos os projetos
- [ ] Firestore criado em `southamerica-east1` em ambos os projetos
- [ ] Security Rules publicadas

### Apple Developer (iOS)

- [ ] Sign In with Apple habilitado no App ID
- [ ] Service ID criado com domínio Firebase configurado
- [ ] Key `.p8` criada e upada no Firebase Console
- [ ] Capability adicionada no Xcode

### Ambiente local

- [ ] `firebase-tools` 13+ instalado
- [ ] `flutterfire_cli` instalado
- [ ] `firebase_options_dev.dart` gerado via FlutterFire CLI
- [ ] `firebase_options_prd.dart` gerado via FlutterFire CLI
- [ ] Emuladores funcionando (`firebase emulators:start`)
- [ ] App conectando ao emulador no flavor dev
- [ ] `google-services.json` e `GoogleService-Info.plist` no `.gitignore`

### Build de verificação

- [ ] `flutter run --dart-define=FLAVOR=dev` sem crash
- [ ] `Firebase.initializeApp()` sem erro de configuração
- [ ] Auth Sign-In com Google abre o fluxo OAuth (mesmo que ainda não persista dados)
