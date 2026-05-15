# Design: Invite Deep Links + Gift Code Redemption

**Data:** 2026-05-15  
**Status:** Aprovado  
**Fase:** 5 (polimento visual / funcionalidades sociais)

---

## Contexto

Duas funcionalidades sociais estavam incompletas:

1. **Convite de amigos** — o link gerado (`https://bichim-prd.web.app/invite?ref={userId}`) não era interceptado pelo app Android; abria no navegador sem nenhuma ação.
2. **Resgate de gift code** — após uma compra na loja, um código de presente é gerado e exibido ao comprador, mas o destinatário não tinha onde digitá-lo para receber o item.

---

## Fora do Escopo

- iOS Universal Links (configuração separada)
- Página web de fallback em `bichim-prd.web.app/invite`
- Troca de domínio (infra separada; o domínio é uma string configurável)
- Notificação push ao comprador quando o código é resgatado
- Cloud Functions para validação server-side (desnecessário para este jogo)

---

## Seção 1 — Modelo de Dados

### Gift Codes (Firestore)

Coleção: `gift_codes/{code}`

```
{
  code:         string,        // ex: "DEV-1747234567890-AB"
  packageId:    string,        // ex: "p2"
  giftContents: {
    lives: int, bomb2: int, bomb3: int, undo1: int, undo3: int
  },
  status:       "pending" | "redeemed" | "expired",
  createdAt:    Timestamp,
  createdBy:    string,        // userId do comprador
  redeemedBy:   string?,       // userId do resgatador (null até resgate)
  redeemedAt:   Timestamp?
}
```

O modelo local `ShareCode` (`lib/data/models/share_code.dart`) já existe com campos equivalentes — o documento Firestore espelha esse modelo.

### Invites (sem mudança de modelo)

O modelo de convites em Firestore já está correto. Apenas o fluxo de UI muda.

---

## Seção 2 — Feature 1: Android App Links + Welcome Bottom Sheet

### Infra (configuração única)

1. **`assetlinks.json`** — hospedado em `https://bichim-prd.web.app/.well-known/assetlinks.json` via Firebase Hosting. Declara o SHA-256 do keystore de produção e debug para que o Android confie no domínio.

2. **`AndroidManifest.xml`** — adicionar intent filter no `MainActivity` para interceptar `https://bichim-prd.web.app/invite` com `android:autoVerify="true"`.

### Fluxo: link clicado

```
Usuário clica https://bichim-prd.web.app/invite?ref={userId}
  ├─ App instalado
  │    └─ Android abre o app via App Link
  │         └─ main.dart: handler detecta path /invite?ref={userId}
  │              ├─ Salva ref no Hive (já implementado)
  │              ├─ Usuário já logado? → ignora silenciosamente
  │              └─ Usuário não logado?
  │                   ├─ Busca displayName do anfitrião no Firestore
  │                   └─ Exibe InviteWelcomeSheet
  │                        ├─ "[Nome] te convidou! Crie sua conta e ganhe recompensas."
  │                        ├─ Botão "Criar conta" → navega para OnboardingAuthScreen
  │                        └─ Botão "Agora não" → fecha
  └─ App não instalado
       └─ Abre bichim-prd.web.app/invite no navegador
            └─ (página de fallback — fora do escopo desta spec)
```

### Componentes

| Arquivo | Ação |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | Adicionar intent filter para App Links HTTPS |
| `firebase.json` | Configurar hosting para servir `.well-known/assetlinks.json` |
| `public/.well-known/assetlinks.json` | Criar arquivo com SHA-256 do app |
| `lib/main.dart` | Tratar path `/invite` no handler; exibir sheet se não logado |
| `lib/domain/invites/invite_service.dart` | Adicionar `getInviterName(userId) → String?` |
| `lib/presentation/widgets/invite_welcome_sheet.dart` | **Novo** — bottom sheet de boas-vindas |

### InviteWelcomeSheet

- Exibe nome do anfitrião (ou "Um amigo" se lookup falhar)
- Botão primário: "Criar conta" → `OnboardingAuthScreen`
- Botão secundário: "Agora não" → fecha (ref já foi salvo no Hive)
- Não bloqueia navegação (não é `PopScope(canPop: false)`)

---

## Seção 3 — Feature 2: Resgate de Gift Code

### Fluxo: geração (comprador)

```
Comprador finaliza compra na ShopScreen
  └─ IAPService.buyPackage() → sucesso
  └─ Gera código local (já existe)
  └─ shareCodesNotifier.add(code)           ← já existe
  └─ [NOVO] GiftCodeRepository.writeToFirestore(shareCode)
  └─ PurchaseSuccessSheet exibe código      ← já existe
```

### Fluxo: resgate (destinatário)

```
Destinatário abre ShopScreen
  └─ Botão "Resgatar código de presente" (topo da tela)
       └─ Navega para RedeemCodeScreen
            └─ Campo de texto + botão "Resgatar"
                 └─ GiftCodeRepository.redeemCode(code, userId)
                      └─ Firestore transaction:
                           1. Lê gift_codes/{code}
                           2. Valida regras (ver abaixo)
                           3. Escreve status="redeemed", redeemedBy, redeemedAt
                 ├─ Sucesso → iapDelivery entrega itens localmente
                 │            → bottom sheet de sucesso com itens recebidos
                 └─ Erro → mensagem inline no campo
```

### Regras de validação

| Condição | Mensagem ao usuário |
|---|---|
| Código não encontrado no Firestore | "Código não encontrado" |
| `status == redeemed` | "Este código já foi utilizado" |
| `createdAt` há mais de 30 dias | "Este código expirou" |
| `createdBy == userId` do resgatador | "Você não pode resgatar seu próprio presente" |
| Usuário não logado | Exibe prompt de login antes de tentar validar |
| Firestore offline | "Sem conexão. Tente novamente." |

### Componentes

| Arquivo | Ação |
|---|---|
| `lib/data/repositories/gift_code_repository.dart` | **Novo** — `writeToFirestore(ShareCode)` + `redeemCode(code, userId)` (transação Firestore) |
| `lib/presentation/screens/shop_screen.dart` | Chama `writeToFirestore` após compra; adiciona botão "Resgatar código" no topo |
| `lib/presentation/screens/redeem_code_screen.dart` | Implementa o stub — campo de texto, validação, feedback inline, sheet de sucesso |
| `lib/core/utils/iap_delivery.dart` | Reutilizado sem alteração para entregar recompensa |

---

## Seção 4 — Testes e Casos de Borda

### Casos de borda

| Cenário | Comportamento |
|---|---|
| Link clicado com usuário já logado | Ignora silenciosamente |
| Usuário cria conta depois de clicar o link | Ref salvo no Hive é registrado no próximo login (fluxo já existente) |
| Dois dispositivos resgatam mesmo código simultaneamente | Transação Firestore garante atomicidade; segundo recebe "Já utilizado" |
| Usuário sem conta tenta resgatar código | RedeemCodeScreen redireciona para login antes de validar |
| Comprador tenta resgatar próprio código | Bloqueado por regra `createdBy == userId` |

### Testes

- **Unitário:** `GiftCodeRepository` — lógica de validação (expirado, já usado, próprio código)
- **E2E (Tier 1):** fluxo completo no flavor `dev` — comprar item, copiar código DEV, resgatar, verificar inventário
- **Manual:** App Links — requer device físico com SHA-256 registrado no `assetlinks.json`

---

## Dependências de Infra (pré-requisitos antes do deploy em produção)

1. Gerar e registrar SHA-256 do keystore de produção no `assetlinks.json`
2. Fazer deploy do `assetlinks.json` no Firebase Hosting (`firebase deploy --only hosting`)
3. Aguardar verificação do Android (pode levar até 24h na primeira vez)
4. Regras Firestore: permitir leitura/escrita autenticada em `gift_codes`
