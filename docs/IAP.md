# Configuração de Produtos IAP — Olha o Bichim!

Este documento descreve todos os produtos in-app purchase (consumíveis) do app,
e como configurá-los nas lojas antes do lançamento.

---

## Produtos registrados

| ID do produto | Tipo       | Preço (BRL) | Conteúdo                    |
|---------------|------------|-------------|-----------------------------|
| `p1`          | Consumível | R$ 3,99     | 4× Bomba 3                  |
| `p2`          | Consumível | R$ 1,99     | 4× Desfazer 3               |
| `p3`          | Consumível | R$ 2,49     | 6 Vidas                     |
| `p4`          | Consumível | R$ 4,99     | 10 Vidas                    |
| `p5`          | Consumível | R$ 4,99     | Combo Mata Atlântica        |
| `p6`          | Consumível | R$ 9,99     | Combo Floresta Amazônica    |
| `u_bomb3`     | Consumível | R$ 1,99     | 1× Bomba 3                  |
| `u_undo3`     | Consumível | R$ 0,99     | 1× Desfazer 3               |
| `u_bomb2`     | Consumível | R$ 1,19     | 1× Bomba 2                  |
| `u_undo1`     | Consumível | R$ 0,49     | 1× Desfazer 1               |

Todos são **consumíveis** (o jogador pode comprar múltiplas vezes).

---

## Google Play Console

1. Acesse **Monetização → Produtos in-app → Produtos gerenciados**
2. Para cada ID da tabela acima:
   - Clique em **Criar produto**
   - Tipo: **Consumível**
   - ID do produto: exatamente como na tabela (ex: `u_bomb3`)
   - Nome e descrição em PT-BR conforme a tabela
   - Preço: conforme tabela (ajustar para a faixa de preço mais próxima disponível no BR)
   - Status: **Ativo**
3. Salvar
4. Publicar (produtos só ficam disponíveis após o app estar publicado, ao menos em **Teste Interno**)

---

## App Store Connect

1. Acesse o app → **Recursos → Compras no app**
2. Para cada ID:
   - Clique em **+** → **Consumível**
   - ID de referência: exatamente como na tabela
   - Nome de referência: nome interno (ex: "Bomba 3 unitária")
   - Localização: adicionar PT-BR com nome e descrição
   - Preço: escolher faixa equivalente
   - Screenshot de revisão: captura do item sendo usado no jogo
3. Salvar e submeter junto com a próxima versão do app

---

## Testando em sandbox

### Android (flavor `dev`)

O flavor `dev` usa `IAPServiceImpl` (sandbox do Google Play).

1. Configure uma conta de teste licenciada no Play Console:
   - **Configuração → Licenciamento e testes in-app → Testadores de licença**
   - Adicionar o e-mail da conta Google de teste
2. No dispositivo de teste, faça login com a conta de testes
3. Execute o app com `flutter run --dart-define=FLAVOR=dev`
4. Compras no sandbox não cobram valor real

### iOS (flavor `dev`)

1. Crie um **Sandbox Tester** em App Store Connect → **Usuários e acesso → Sandbox**
2. No dispositivo de teste, saia do iCloud e entre com o Sandbox Tester
3. Execute com `flutter run --dart-define=FLAVOR=dev`

---

## Flavor `tst` (testes automatizados)

O flavor `tst` usa `FakeIAPService` — sempre retorna sucesso instantaneamente, sem
chamadas de rede. Ideal para testes unitários e de widget.

Para testar com IAP real em `tst` (smoke test):
```bash
flutter run --dart-define=FLAVOR=tst --dart-define=USE_REAL_IAP=true
```

---

## Código-fonte relacionado

| Arquivo | Responsabilidade |
|---------|-----------------|
| `lib/domain/shop/iap_service.dart` | Interface `IAPService` + `FakeIAPService` + provider |
| `lib/data/repositories/iap_service_impl.dart` | Implementação real com `in_app_purchase` |
| `lib/data/repositories/iap_startup_service.dart` | Inicialização da store na startup do app |
| `lib/data/shop_data.dart` | Definições de todos os produtos (`kShopPackages`, `kShopUnitPackages`) |
| `lib/core/utils/iap_delivery.dart` | Helper para entrega local de itens pós-compra |
