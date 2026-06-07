# Configuração de Anúncios AdMob — Olha o Bichim!

Este documento cobre a configuração de anúncios AdMob no app.

| Tipo         | Status              | Onde é usado                                               |
| ------------ | ------------------- | ---------------------------------------------------------- |
| Premiado     | ✅ Implementado      | Game over sem itens (+ 1 vida) e dobrar recompensa diária  |
| Banner       | 🔲 Não implementado  | —                                                          |
| Intersticial | 🔲 Não implementado  | —                                                          |

As seções de Banner e Intersticial abaixo são referência para quando forem implementados.
O anúncio Premiado já está em produção — veja `lib/data/repositories/google_mobile_ads_service.dart`.

---

## IDs de teste do Google

Use estes IDs em dev/tst. **Nunca** use IDs reais em builds de desenvolvimento.

| Tipo no AdMob           | Plataforma | ID de teste                              |
| ----------------------- | ---------- | ---------------------------------------- |
| Premiado                | Android    | `ca-app-pub-3940256099942544/5224354917` |
| Premiado                | iOS        | `ca-app-pub-3940256099942544/1712485313` |
| Banner                  | Android    | `ca-app-pub-3940256099942544/6300978111` |
| Banner                  | iOS        | `ca-app-pub-3940256099942544/2934735716` |
| Intersticial            | Android    | `ca-app-pub-3940256099942544/1033173712` |
| Intersticial            | iOS        | `ca-app-pub-3940256099942544/4411468910` |
| Intersticial premiado   | Android    | `ca-app-pub-3940256099942544/5354046379` |
| Intersticial premiado   | iOS        | `ca-app-pub-3940256099942544/6978759866` |
| Nativo avançado         | Android    | `ca-app-pub-3940256099942544/2247696110` |
| Nativo avançado         | iOS        | `ca-app-pub-3940256099942544/3986624511` |
| Abertura do app         | Android    | `ca-app-pub-3940256099942544/9257395921` |
| Abertura do app         | iOS        | `ca-app-pub-3940256099942544/5575463023` |

> Referência oficial: <https://developers.google.com/admob/flutter/test-ads>

---

## App IDs (já configurados)

O App ID de produção já está nos arquivos nativos.
Em dev usa-se o App ID de teste do Google.

| Plataforma | Onde fica                          | Valor atual (prd)                         |
| ---------- | ---------------------------------- | ----------------------------------------- |
| Android    | `android/app/src/main/AndroidManifest.xml` | `ca-app-pub-3940256099942544~3347511713` |
| iOS        | `ios/Runner/Info.plist` → `GADApplicationIdentifier` | `ca-app-pub-3940256099942544~3347511713` |

Para trocar o App ID de produção, substitua o valor nesses dois arquivos.

---

## Criando blocos de anúncio no AdMob Console

### Premiado (em uso)

1. Acesse **AdMob Console → [seu app] → Blocos de anúncio**
2. Clique em **Adicionar bloco de anúncio → Premiado**
3. Preencha os campos:

   | Campo                    | O que preencher                                      |
   | ------------------------ | ---------------------------------------------------- |
   | Nome do bloco de anúncios | `premiado_android` ou `premiado_ios`                |
   | Lances de parceiros      | Deixar **desmarcado** (não usamos mediação externa)  |
   | Valor do prêmio          | `1`                                                  |
   | Item do prêmio           | `item`                                               |

   > Os campos de prêmio são obrigatórios no AdMob mas o app os ignora —
   > a recompensa (vida ou dobrar pontos) é controlada internamente pelo código.

4. Salvar → copiar o **ID do bloco de anúncio** gerado (formato `ca-app-pub-XXXX/XXXXXXXXXX`)
5. Repetir para iOS
6. Injetar os IDs no build de produção via `--dart-define` (veja seção abaixo)

### Banners (não implementado)

1. Acesse **AdMob Console → [seu app] → Blocos de anúncio**
2. Clique em **Adicionar bloco de anúncio → Banner**
3. Nome sugerido: `banner_home_android` / `banner_home_ios`
4. Formato: **Banner adaptável ancorado** (recomendado para jogos)
5. Salvar → copiar o **ID da bloco de anúncio** gerado
6. Repetir para iOS

### Intersticiais (não implementado)

1. **Adicionar bloco de anúncio → Intersticial**
2. Nome sugerido: `intersticial_game_over_android` / `intersticial_game_over_ios`
3. Selecionar os formatos aceitos (vídeo, imagem, texto conforme necessidade)
4. Salvar → copiar o ID gerado
5. Repetir para iOS

---

## Configuração no app

### 1. Adicionar os novos IDs em `ad_config.dart`

```dart
// lib/core/constants/ad_config.dart

static const bannerAndroid = String.fromEnvironment(
  'BANNER_UNIT_ANDROID',
  defaultValue: 'ca-app-pub-3940256099942544/6300978111', // teste
);

static const bannerIos = String.fromEnvironment(
  'BANNER_UNIT_IOS',
  defaultValue: 'ca-app-pub-3940256099942544/2934735716', // teste
);

static const interstitialAndroid = String.fromEnvironment(
  'INTERSTITIAL_UNIT_ANDROID',
  defaultValue: 'ca-app-pub-3940256099942544/1033173712', // teste
);

static const interstitialIos = String.fromEnvironment(
  'INTERSTITIAL_UNIT_IOS',
  defaultValue: 'ca-app-pub-3940256099942544/4411468910', // teste
);
```

### 2. Injetar os IDs reais no build de produção

Adicione os `--dart-define` abaixo ao comando de build prd (atualizar também
`CLAUDE.md` e os GitHub Secrets do CI):

```bash
flutter build apk --flavor prd --release \
  --dart-define=FLAVOR=prd \
  --dart-define=AD_UNIT_ANDROID=<premiado-android-real> \
  --dart-define=AD_UNIT_IOS=<premiado-ios-real> \
  --dart-define=BANNER_UNIT_ANDROID=<banner-android-real> \
  --dart-define=BANNER_UNIT_IOS=<banner-ios-real> \
  --dart-define=INTERSTITIAL_UNIT_ANDROID=<interstitial-android-real> \
  --dart-define=INTERSTITIAL_UNIT_IOS=<interstitial-ios-real>
```

### 3. Implementar o serviço

Criar `lib/data/repositories/banner_ad_service.dart` e
`lib/data/repositories/interstitial_ad_service.dart` seguindo o mesmo padrão
de `google_mobile_ads_service.dart` (interface em `lib/domain/`, implementação
em `lib/data/repositories/`).

Pontos de atenção:

- **Banner**: chamar `_bannerAd.dispose()` no `dispose()` do widget que o exibe
- **Intersticial**: pré-carregar o próximo anúncio imediatamente após exibir o atual
  (mesmo padrão já usado no tipo Premiado — `unawaited(_loadAd())`)
- Verificar `AdConfig.flavor == 'prd'` antes de qualquer chamada de rede (mesmo
  padrão de `main.dart` — AdMob só é inicializado no flavor `prd`)

---

## Configuração de conteúdo (já ativa)

O app já define `RequestConfiguration` em `main.dart` voltado para público infantil:

```dart
RequestConfiguration(
  tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
  tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
  maxAdContentRating: MaxAdContentRating.g,
)
```

Isso limita os anúncios exibidos à classificação G e ativa o modo
COPPA/GDPR para menores. Não alterar sem consultar os requisitos das lojas.

---

## Testando

### Devices de teste (recomendado)

Registre o ID do dispositivo físico como **dispositivo de teste** no AdMob Console
para receber anúncios de teste mesmo com IDs de produção, sem risco de ban.

```dart
// Temporário — apenas durante desenvolvimento local
MobileAds.instance.updateRequestConfiguration(
  RequestConfiguration(
    testDeviceIds: ['SEU_DEVICE_ID_HASH'],
  ),
);
```

O hash do dispositivo aparece nos logs do Android (`Logcat`) na primeira
requisição de anúncio: `Use RequestConfiguration.Builder.setTestDeviceIds()`

### Flavor `dev` / `tst`

Nos flavors `dev` e `tst` o AdMob **não é inicializado** (`main.dart` só
chama `MobileAds.instance.initialize()` quando `FLAVOR == 'prd'`).
Os IDs de teste do Google retornam anúncios fictícios mesmo sem inicialização
completa, mas o comportamento correto só é validado no flavor `prd`.

---

## Código-fonte relacionado

| Arquivo                                                    | Responsabilidade                                              |
| ---------------------------------------------------------- | ------------------------------------------------------------- |
| `lib/core/constants/ad_config.dart`                        | IDs dos blocos via `--dart-define`; limite diário de anúncio premiado |
| `lib/domain/daily_rewards/ad_service.dart`                 | Interface `AdService` + `FakeAdService`                       |
| `lib/data/repositories/google_mobile_ads_service.dart`     | Implementação do tipo Premiado (`RewardedAd`) com pré-carregamento    |
| `lib/main.dart` (linha ~66)                                | Inicialização do SDK + `RequestConfiguration` infantil        |
| `android/app/src/main/AndroidManifest.xml`                 | App ID no `<meta-data>` do AdMob                              |
| `ios/Runner/Info.plist`                                    | `GADApplicationIdentifier`                                    |
