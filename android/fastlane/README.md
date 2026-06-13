fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android deploy

```sh
[bundle exec] fastlane android deploy
```

Build AAB de produção e envia para o Google Play (track interno)

### android upload_metadata

```sh
[bundle exec] fastlane android upload_metadata
```

Faz upload apenas de metadata e screenshots (sem novo build)

### android validate_metadata

```sh
[bundle exec] fastlane android validate_metadata
```

Valida metadata sem commitar (diagnóstico)

### android promote_to_production

```sh
[bundle exec] fastlane android promote_to_production
```

Promove build do track interno para produção (opções: version_code:NN status:draft|completed)

status:draft é obrigatório na primeira publicação (app ainda em rascunho no Console)

### android set_production_countries

```sh
[bundle exec] fastlane android set_production_countries
```

Define os países/regiões da faixa de produção via Android Publisher API

Opção: countries:BR,PT (padrão: BR). Resolve 'Nenhum país selecionado para esta faixa'

### android create_iap_products

```sh
[bundle exec] fastlane android create_iap_products
```

Cria/atualiza os produtos in-app no Google Play via Android Publisher API (conforme IAP.md)

Opções: only:p1,u_bomb3 (subconjunto)  |  dry_run:true (só lista, não envia)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
