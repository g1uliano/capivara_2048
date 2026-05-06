# IAP.md — Configuração de In-App Purchases

Guia para configurar e testar compras no Google Play Store e Apple App Store.
Siga este guia antes de testar com `USE_REAL_IAP=true`.

---

## 1. Product IDs

Os 6 pacotes da loja têm IDs exatos que devem ser cadastrados nas lojas:

| Pacote | Nome | ID na loja | Preço BRL |
|--------|------|-----------|-----------|
| p1 | 4× Bomba 3 | `bichim_pack_p1` | R$ 3,99 |
| p2 | 4× Desfazer 3 | `bichim_pack_p2` | R$ 1,99 |
| p3 | 6 Vidas | `bichim_pack_p3` | R$ 2,49 |
| p4 | 10 Vidas | `bichim_pack_p4` | R$ 4,99 |
| p5 | Combo Mata Atlântica | `bichim_pack_p5` | R$ 4,99 |
| p6 | Combo Floresta Amazônica | `bichim_pack_p6` | R$ 9,99 |

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
3. No menu lateral: **Monetizar → Produtos → Produtos para apps**
4. Clique em **Criar produto**
5. Para cada pacote da tabela acima:
   - **ID do produto:** exatamente como na coluna "ID na loja" (ex: `bichim_pack_p1`)
   - **Nome:** nome do pacote (ex: `4× Bomba 3`)
   - **Descrição:** descrição do pacote
   - **Status:** Ativo
   - **Preço padrão:** valor em BRL
6. Salvar e repetir para todos os 6 pacotes

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

| Comando | Flavor | IAP | Uso |
|---------|--------|-----|-----|
| `flutter run --dart-define=FLAVOR=dev` | dev | Fake | Desenvolvimento local |
| `flutter build apk --dart-define=FLAVOR=tst` | tst | Fake | QA — testa UI sem lojas |
| `flutter build apk --dart-define=FLAVOR=tst --dart-define=USE_REAL_IAP=true` | tst | Real (sandbox) | QA — testa fluxo completo |
| `flutter build apk --dart-define=FLAVOR=prd` | prd | Real (produção) | Release |

### Build e instalação rápida (Android)

```bash
# Build + install TST com IAP real
flutter build apk --dart-define=FLAVOR=tst --dart-define=USE_REAL_IAP=true
flutter install

# Build + install PRD
flutter build apk --dart-define=FLAVOR=prd
flutter install
```

---

## 5. Checklist antes de testar IAP real

- [ ] Todos os 6 produtos cadastrados no Play Console / App Store Connect com IDs exatos
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
