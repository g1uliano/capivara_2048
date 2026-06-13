# IAP.md — Configuração de In-App Purchases

Guia para configurar e testar compras no Google Play Store e Apple App Store.
Siga este guia antes de testar com `USE_REAL_IAP=true`.

---

## 1. Product IDs

O ID na loja é sempre `bichim_pack_<id_interno>` — o `IAPServiceImpl` aplica esse prefixo automaticamente (`'bichim_pack_${package.id}'`).

### Pacotes

| ID interno | Nome                     | ID na loja            | Preço BRL |
| ---------- | ------------------------ | --------------------- | --------- |
| p1         | 4× Bomba 3               | `bichim_pack_p1`      | R$ 3,99   |
| p2         | 4× Desfazer 3            | `bichim_pack_p2`      | R$ 1,99   |
| p3         | 6 Vidas                  | `bichim_pack_p3`      | R$ 2,49   |
| p4         | 10 Vidas                 | `bichim_pack_p4`      | R$ 4,99   |
| p5         | Combo Mata Atlântica     | `bichim_pack_p5`      | R$ 4,99   |
| p6         | Combo Floresta Amazônica | `bichim_pack_p6`      | R$ 9,99   |

### Produtos únicos (compra por unidade)

| ID interno | Nome           | ID na loja               | Preço BRL |
| ---------- | -------------- | ------------------------ | --------- |
| u_bomb3    | 1× Bomba 3     | `bichim_pack_u_bomb3`    | R$ 1,99   |
| u_undo3    | 1× Desfazer 3  | `bichim_pack_u_undo3`    | R$ 0,99   |
| u_bomb2    | 1× Bomba 2     | `bichim_pack_u_bomb2`    | R$ 1,19   |
| u_undo1    | 1× Desfazer 1  | `bichim_pack_u_undo1`    | R$ 0,49   |

Todos os produtos são do tipo **Consumable** (podem ser comprados múltiplas vezes).

---

## 2. Google Play Console

### 2.1 Pré-requisitos

- App criado no Google Play Console (pode ser em closed testing — não precisa estar publicado)
- APK `tst` ou `prd` enviado para alguma track (mesmo um upload de draft serve para liberar a seção de In-App Products)
- Conta de desenvolvedor com acesso à conta do app

### 2.2 Criar os produtos

1. Acesse [Google Play Console](https://play.google.com/console)
2. Selecione o app "Olha o Bichim!"
3. No menu lateral: **Monetizar → Produtos → Produtos únicos**
4. Clique em **Criar produto**
5. Para cada item da seção 1 (pacotes **e** produtos únicos — 10 no total):
   - **ID do produto:** exatamente como na coluna "ID na loja" (ex: `bichim_pack_p1`, `bichim_pack_u_bomb3`)
   - **Nome:** nome do item (ex: `4× Bomba 3`, `1× Bomba 3`)
   - **Descrição:** descrição do item
   - **Status:** Ativo
   - **Preço padrão:** valor em BRL conforme tabela
6. Salvar e repetir para todos os 10 produtos

> Os IDs dos produtos únicos seguem o mesmo padrão: `bichim_pack_u_bomb3`, `bichim_pack_u_undo3`, `bichim_pack_u_bomb2`, `bichim_pack_u_undo1`.

### 2.2.1 Alternativa automatizada (Fastlane)

Em vez de cadastrar os 10 produtos manualmente, use a lane `create_iap_products`. Ela
cria (ou atualiza, se já existirem) todos os produtos via Android Publisher API e os deixa
**ativos**, reutilizando a mesma service account do `supply` (`PLAY_STORE_JSON_KEY` ou
`fastlane/play-store-key.json`).

> **Importante:** isso usa a API do Google por baixo — o `fastlane supply` em si **não**
> gerencia produtos in-app. A lane é só um wrapper conveniente em cima da API.

```bash
cd android

# Pré-visualizar sem enviar nada (não autentica, não toca na API)
fastlane android create_iap_products dry_run:true

# Criar/atualizar/ativar todos os 10 produtos
fastlane android create_iap_products

# Apenas um subconjunto (aceita ID interno ou ID na loja)
fastlane android create_iap_products only:u_bomb3,u_undo1
```

A lista de produtos (IDs, nomes, descrições e preços BRL) vive na constante `IAP_PRODUCTS`
no `android/fastlane/Fastfile` e deve espelhar a seção 1 deste documento.

**Como funciona (Monetization API / one-time products):**

- O endpoint legado `inappproducts` foi desativado (`403 "Please migrate to the new
  publishing API"`); a lane usa a nova API de **one-time products**.
- Cada produto vira um *one-time product* com um *purchase option* do tipo "buy"
  (`legacy_compatible: true`, para a billing library atual enxergar). A consumibilidade é
  decidida pelo app no consumo.
- A lane faz **dois passos** por produto: `patch` (cria/atualiza, `allow_missing`) e
  `purchaseOptions:batchUpdateStates` para **ativar** (sai de `DRAFT` → `ACTIVE`).
  Ambos são idempotentes — pode rodar quantas vezes quiser.
- **Disponibilidade: apenas Brasil (BRL)**, com os preços exatos da seção 1. A nova API
  não tem `autoConvertMissingPrices`; expandir para outras regiões exigiria âncoras de
  preço em USD/EUR. Para vender em mais regiões, adicione-as manualmente no Play Console.
- A lane preserva regiões já cadastradas (a API proíbe remover uma região existente):
  regiões fora do BR ficam como `NO_LONGER_AVAILABLE`.

**Pré-requisitos:** app já criado no Play Console com pelo menos um build enviado a alguma
track (libera a seção de produtos in-app) e a service account com permissão de gerenciar
produtos.

### 2.3 Licença de teste (compras gratuitas)

Para testar sem cobrar o cartão do testador:

1. No Google Play Console → **Configurações → Licença e informações sobre o app**
2. Em **Testadores de licença**, adicione o e-mail da conta Google do testador
3. Essa conta pode comprar qualquer produto sem cobrança real
4. **Importante:** a conta do testador deve estar no dispositivo Android como conta principal

### 2.4 Closed Testing Track

Para distribuir o APK `tst` com IAP real para testadores internos:

1. **Testes → Testadores internos → Criar release**
2. Upload do APK `tst` gerado com:
   ```bash
   flutter build apk --dart-define=FLAVOR=tst --dart-define=USE_REAL_IAP=true
   ```
3. Adicionar e-mails dos testadores
4. Cada testador instala via link da track (não pela loja pública)

### 2.5 Testar em dispositivo

Requisitos:

- Dispositivo físico Android (emulador **não** suporta compras reais)
- APK instalado da closed testing track ou via `flutter install`
- Conta Google do testador configurada como conta principal no dispositivo

---

## 3. App Store Connect

### 3.1 Pré-requisitos

- App criado no App Store Connect
- Contrato de pagamento ativo (mesmo para testes)
- Xcode com o projeto Flutter configurado

### 3.2 Criar os produtos

1. Acesse [App Store Connect](https://appstoreconnect.apple.com)
2. Selecione o app → **Features → In-App Purchases**
3. Clique em **+** e escolha **Consumable**
4. Para cada pacote:
   - **Reference Name:** nome legível (ex: `4x Bomba 3`)
   - **Product ID:** exatamente como na coluna "ID na loja" (ex: `bichim_pack_p1`)
   - **Pricing:** tier equivalente ao preço BRL
   - **Localization (pt-BR):** Display Name + Description
5. Status: **Ready to Submit**

### 3.3 Sandbox Testers

1. App Store Connect → **Users and Access → Sandbox → Testers**
2. Criar conta sandbox (e-mail fictício nunca usado em Apple ID real)
3. No iPhone de teste: **Configurações → App Store → Conta Sandbox** → fazer login
4. Compras em sandbox são gratuitas

### 3.4 StoreKit Configuration (testes locais no Xcode)

Para testar sem conectar ao servidor da Apple:

1. No Xcode: **File → New → File → StoreKit Configuration File**
2. Salvar como `Configuration.storekit` dentro de `ios/Runner/`
3. Para cada produto: **+** → **Add Product** → **Consumable**
   - **Product ID:** `bichim_pack_p1` (etc.)
   - **Price:** equivalente ao BRL
4. No scheme de teste: **Edit Scheme → Run → Options → StoreKit Configuration** → selecionar o arquivo
5. Executar `flutter run` — as compras usam StoreKit local, sem conta Apple

> **Nota:** Adicionar `ios/Runner/Configuration.storekit` ao `.gitignore` se não quiser commitar.

---

## 4. Builds com IAP

O `iapServiceProvider` decide qual implementação usar com base em **duas** variáveis de ambiente Dart:

```dart
const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
const useRealIap = bool.fromEnvironment('USE_REAL_IAP', defaultValue: false);

// Usa IAPServiceImpl (real) se:
//   FLAVOR=prd  OU
//   FLAVOR=dev  OU
//   FLAVOR=tst && USE_REAL_IAP=true
// Caso contrário: FakeIAPService
```

> **Nota:** `--flavor` (argumento do Flutter/Android) e `--dart-define=FLAVOR=` são dois valores independentes. O primeiro controla o flavor do Android build (app ID, signing, etc.); o segundo controla a lógica de IAP em runtime.

| Comando | Android flavor | Dart FLAVOR | IAP | Uso |
| ------- | -------------- | ----------- | --- | --- |
| `flutter run --dart-define=FLAVOR=dev` | default | dev | Real (sandbox) | Desenvolvimento local com IAP |
| `flutter run --dart-define=FLAVOR=dev` (sem dart-define) | default | dev* | Real (sandbox) | Idem — `dev` é o default |
| `flutter build apk --flavor tst --debug --dart-define=FLAVOR=tst` | tst | tst | Fake | QA — testa UI sem lojas |
| `flutter build apk --flavor tst --debug --dart-define=FLAVOR=dev` | tst | dev | **Real (sandbox)** | Sandbox com app ID do flavor `tst` |
| `flutter build apk --flavor tst --dart-define=FLAVOR=tst --dart-define=USE_REAL_IAP=true` | tst | tst | Real (sandbox) | QA — testa fluxo completo |
| `flutter build apk --flavor prod --release --dart-define=FLAVOR=prd` | prod | prd | Real (produção) | Release |

### Sandbox rápido com flavor `tst` + `FLAVOR=dev`

```bash
flutter build apk --flavor tst --debug --dart-define=FLAVOR=dev
flutter install --flavor tst
```

Esse combo é útil para testar o fluxo IAP completo durante desenvolvimento:
- `--flavor tst` usa o app ID de teste (evita poluir o histórico do app de produção no Play Console)
- `--dart-define=FLAVOR=dev` ativa o `IAPServiceImpl` real (sem precisar de `USE_REAL_IAP=true`)
- `--debug` mantém hot-reload e logs

**Pré-requisito:** o app ID do flavor `tst` deve estar cadastrado no Play Console e os produtos devem estar ativos lá. A conta do testador deve ser licenciada (seção 2.3).

### Build e instalação para QA completo

```bash
# Build + install TST com IAP real (via USE_REAL_IAP)
flutter build apk --flavor tst --release \
  --dart-define=FLAVOR=tst \
  --dart-define=USE_REAL_IAP=true
flutter install --flavor tst

# Build + install PRD
flutter build apk --flavor prod --release --dart-define=FLAVOR=prd
flutter install --flavor prod
```

---

## 5. Checklist antes de testar IAP real

- [ ] Todos os 10 produtos cadastrados no Play Console / App Store Connect com IDs exatos (6 pacotes + 4 produtos únicos)
- [ ] Status dos produtos: **Ativo** (Google) / **Ready to Submit** (Apple)
- [ ] Conta de testador configurada (Google License Tester / Apple Sandbox)
- [ ] Dispositivo físico Android (emulador não suporta IAP)
- [ ] APK `tst` instalado com `USE_REAL_IAP=true`
- [ ] Usuário logado no app (IAP requer autenticação — sem login usa FakeIAPService)

---

## 6. Troubleshooting

### "BillingClient is not ready"

- Causa: Google Play Services não inicializado ou dispositivo sem Google Play
- Solução: testar em dispositivo físico com Google Play; reiniciar o app

### "SKErrorDomain code 0" (iOS)

- Causa: StoreKit não conseguiu carregar o produto
- Solução: verificar se o Product ID está exatamente igual ao cadastrado

### "Produto não encontrado na loja"

- Causa: ID do produto no código não bate com o cadastrado na loja
- Solução: verificar tabela da seção 1; no Play Console, confirmar status "Ativo"

### Compra não entregue após sucesso

- Verificar Firestore → `purchases/{userId}/items/{purchaseId}` → status deve ser `'delivered'`
- Se `'pending_orphan'`: usar "Restaurar compras" na ProfileScreen
- Checar logs: `[IAPStartup]` e `[IAPServiceImpl]` no console

### Compra duplicada

- Não é possível: entrega é idempotente via Firestore (verifica `status == 'delivered'`)
