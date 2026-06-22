# Firebase App Check — configuração e enforce (`bichim-prd`)

Guia operacional para registrar o App Check, monitorar e, depois, ligar o **enforce**
no Firestore de produção. As etapas de console são feitas manualmente no
[Firebase Console](https://console.firebase.google.com/) — não há como automatizá-las pela CLI.

## Por que App Check

A auditoria de segurança apontou que, sem App Check, **qualquer cliente** com um token de
autenticação válido fala direto com o Firestore (não só o app oficial). Isso torna triviais
a fraude de compra, a duplicação de gift codes e a manipulação de ranking, porque um script
pode escrever direto nas coleções.

O App Check exige que cada requisição traga um token de atestação que prova que ela veio do
app oficial e íntegro, rodando num aparelho legítimo. No Android isso é feito pelo
**Play Integrity**.

Para o App Check funcionar são necessárias **duas partes**: a integração no cliente (o app
precisa enviar os tokens) e a configuração de console (registrar o provider e ligar o
enforce). Este guia cobre a parte de console — a integração no cliente é um **pré-requisito**
(ver abaixo).

## Rollout em duas fases (importante)

> ⚠️ **Nunca ligue o enforce antes de ter uma versão publicada e adotada com App Check.**
> Se o enforce for ligado cedo demais, **todos os usuários já instalados** (que ainda não
> atualizaram para a versão com App Check) são bloqueados — o Firestore para de responder a
> eles. Por isso o rollout é fásico: primeiro **monitorar**, só depois **impor**.

---

## Pré-requisitos

- **Integração de App Check no cliente já publicada.** A versão do app que estiver em produção
  (ou na faixa de testes monitorada) precisa conter a dependência `firebase_app_check` e a
  ativação em `lib/main.dart` (`AndroidProvider.playIntegrity` em `prd`, `debug` nos demais,
  pulada sob emulador). Sem isso, o app não envia token nenhum: a Fase 1 mostraria 100% de
  requisições **"não verificadas"** e ligar o enforce bloquearia **todos** os usuários.
  Confirme que o build publicado realmente inclui essa integração antes de prosseguir.
- App Android registrado em `bichim-prd`:
  `1:957303334019:android:dfec2109cc1c2f631d27b6`.
- **SHA-256** das chaves de assinatura (Play App Signing **e** upload key) cadastrados em
  **Configurações do projeto → Seus apps → app Android → Impressões digitais do certificado**.
  O Play Integrity depende deles. (Ver nota interna `play-app-signing-sha`.)
- API **Play Integrity** habilitada para o projeto (o console oferece habilitar ao registrar
  o provider).

---

## Fase 1 — registrar e monitorar (SEM enforce)

Feito **junto com o release** que contém o App Check no código.

1. Console → projeto **`bichim-prd`** → seção **Compilação (Build)** no menu lateral →
   **App Check**. (O Firebase reorganiza esse item periodicamente; se não estiver em
   "Compilação", procure "App Check" na busca do console.)
2. Aba **Apps** → selecione o app **Android** → **Registrar**.
3. Como provedor, escolha **Play Integrity** e salve. Se pedir, habilite a Play Integrity API.
4. Confirme os **SHA-256** em Configurações do projeto (ver pré-requisitos).
5. Aba **APIs** → **Cloud Firestore** → deixe em **"Não imposto"** (modo monitorar).
   **Não** clique em Impor agora.
6. Publique o build `prd` na Play Store (ou faixa de testes).
7. Acompanhe por alguns dias a aba **App Check** → as métricas mostram **solicitações
   verificadas vs. não verificadas**. A fração de verificadas sobe conforme os usuários
   atualizam.

**Critério para avançar:** a grande maioria das requisições do Firestore aparecendo como
**verificadas** (poucas "não verificadas" — essas seriam usuários ainda na versão antiga).

---

## Fase 2 — ligar o enforce (manual, posterior)

Só depois que a Fase 1 mostrar adoção alta.

1. Console → `bichim-prd` → **App Check** → aba **APIs** → **Cloud Firestore**.
2. Clique em **Impor (Enforce)** e confirme.
3. A partir daí, requisições sem um token válido de App Check são **rejeitadas** pelo Firestore.
4. **Vigie a taxa de erro** logo após ligar: na aba App Check e no Firestore. Um pico de
   erros/"não verificadas" indica que muitos usuários ainda estão sem App Check.

### Reverter (se necessário)

Se o enforce causar bloqueios indevidos, **desligue o toggle** em
**App Check → APIs → Cloud Firestore → Impor**. O efeito é praticamente imediato e
volta ao modo monitorar, sem necessidade de novo release.

---

## Dev e CI

- O projeto **`olha-o-bichim-dev` nunca entra em enforce** — mantenha o Firestore dele em
  "Não imposto". Assim, builds `dev`/`tst`, testes de integração e CI continuam funcionando.
- Builds não-`prd` usam o **provider de debug** do App Check. Como o projeto dev fica não
  imposto, **não é obrigatório** registrar tokens de debug.
- Se quiser testar o comportamento de enforce em dev: rode um build debug, copie o **token de
  debug** impresso no logcat (procure por uma linha do App Check contendo `debug secret` /
  `debug token`) e cadastre em
  **App Check → Apps → app Android → menu ⋮ → Gerenciar tokens de depuração**.

---

## Verificação

- **App Check → métricas:** as solicitações do Firestore vindas do app `prd` aparecem como
  **verificadas**.
- Em um aparelho com o build `prd`: o jogo lê/escreve no Firestore normalmente (ranking,
  inventário, compras) — nenhuma regressão.
- Build `dev` e emulador: continuam funcionando (dev não imposto; emulador ignora App Check).

---

## iOS (pendente)

Adiado até a conta **Apple Developer** estar ativa (ver nota interna
`ios-universal-links-pendente`). Quando for o caso:

1. Registrar o app **iOS** (`1:957303334019:ios:294946babe4c24ea1d27b6`) em App Check com
   **DeviceCheck** (ou **App Attest**, iOS 14+), o que exige uma chave gerada no
   portal da Apple.
2. No `lib/main.dart`, adicionar o parâmetro `appleProvider:` na chamada
   `FirebaseAppCheck.instance.activate(...)` (ex.: `AppleProvider.deviceCheck` em prd,
   `AppleProvider.debug` nos demais).
3. Repetir o rollout fásico (monitorar → impor) também para o tráfego iOS.
