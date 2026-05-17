# Performance Mode — Design Spec

**Data:** 2026-05-17  
**Fase:** 5 (polimento visual)  
**Motivação:** Dispositivos mid-range como Redmi Note 9s (Snapdragon 720G, 4GB RAM, Android 12) apresentam lag visível ao mover tiles e falha na detecção de swipes, tornando o jogo injogável.

---

## Problema

Dois problemas distintos causam a má experiência em dispositivos menos potentes:

1. **Input lag (swipe não detectado):** threshold de velocidade `100.0 px/s` em `game_screen.dart:210` é alto demais — swipes lentos ou curtos não são registrados, forçando o usuário a repetir o gesto.
2. **Render lag (rebuild lento):** cada move recria 16 `TileWidget`s com imagens em 27% de opacidade. Em dispositivos com GPU limitada, o composite acumula e causa frame drops.

---

## Solução

**Abordagem B:** seção "Performance" granular nas Configurações + auto-detecção (heurística no launch + monitor de FPS em runtime) + fix independente do swipe.

---

## Arquitetura

### Novos arquivos

```
lib/
├── domain/
│   └── performance/
│       ├── performance_settings.dart          # modelo imutável
│       └── device_capability_detector.dart   # heurística de specs
├── presentation/
│   ├── controllers/
│   │   ├── performance_settings_notifier.dart # Riverpod NotifierProvider
│   │   └── fps_monitor_notifier.dart          # SchedulerBinding FPS listener
│   └── widgets/
│       └── performance_suggestion_dialog.dart # dialog estilo CannotUseItem
```

### Arquivos modificados

| Arquivo | Mudança |
|---------|---------|
| `game_screen.dart` | threshold `100.0` → `50.0`; integra `FpsMonitorNotifier` |
| `tile_widget.dart` | lê `TileQuality` e renderiza variante adequada |
| `pause_overlay.dart` | troca `reduceEffectsProvider` por `performanceSettingsProvider` |
| `settings_screen.dart` | adiciona seção Performance; remove toggle "Reduzir efeitos visuais" |
| `app.dart` | chama `DeviceCapabilityDetector` no primeiro frame |

---

## Modelo de dados

```dart
enum TileQuality { full, fullOpacity, simple }

class PerformanceSettings {
  final bool enabled;
  final TileQuality tileQuality;
  final bool blurEffectsEnabled;
  final bool animationsEnabled;
  final bool autoDetectEnabled;
  final bool hasShownSuggestionDialog;
}
```

**Persistência:** SharedPreferences, chave `'performance_settings'`, JSON. Mesma camada usada por `hapticEnabled` — sem dependência nova.

**`reduceEffectsProvider` removido:** substituído por `performanceSettingsProvider.select((s) => !s.blurEffectsEnabled)`. Consumidores a atualizar: `pause_overlay.dart` (leitura do valor), `settings_screen.dart` (toggle), `main.dart` (load no startup → substituir pelo load do `PerformanceSettingsNotifier`). Arquivo `lib/core/providers/reduce_effects_provider.dart` é deletado.

---

## Auto-detecção

### Heurística no launch (`DeviceCapabilityDetector`)

- Usa `device_info_plus` — **nova dependência**, adicionar ao `pubspec.yaml`.
- Android: lê modelo + SDK via `AndroidDeviceInfo`. Dispositivos com RAM ≤ 4GB inferida por modelo (Redmi/Poco/Samsung A-series) e `sdkInt < 34` são marcados como candidatos.
- Executa uma vez por instalação: se `hasShownSuggestionDialog = false` e dispositivo candidato → agenda dialog após primeiro frame da `HomeScreen`.

### Monitor de FPS em runtime (`FpsMonitorNotifier`)

- Usa `SchedulerBinding.instance.addTimingsCallback`.
- Ativo apenas quando `GameScreen` está em cena e `performanceModeEnabled = false`.
- Acumula os últimos 30 frames. Se média de `buildDuration + rasterDuration > 22ms` (≈ 45fps) por 5s → emite evento.
- Dispara o dialog **no máximo uma vez por sessão**.
- Lifecycle: inicia no mount de `GameScreen`, para no dispose ou quando performance mode é ativado.

---

## Dialog de sugestão (`PerformanceSuggestionDialog`)

Segue exatamente o estilo de `_CannotUseItemDialog`:

- `AlertDialog` com `RoundedRectangleBorder(borderRadius: 20, side: BorderSide(Color(0xFFFF9800), width: 3))`
- Título: `GoogleFonts.fredoka(fontSize: 22, color: Color(0xFFE65100))` — texto: "Modo de Performance 🐢"
- Corpo: `GoogleFonts.nunito(fontSize: 16)`, centralizado — texto: "Detectamos que seu dispositivo pode estar com dificuldades para rodar o jogo suavemente. Quer ativar o Modo de Performance?"
- Dois botões centralizados:
  - **"Ativar"** — `ElevatedButton` laranja (mesmo estilo do "Entendi!") → `performanceSettingsProvider.enable()` + `hasShownSuggestionDialog = true`
  - **"Agora não"** — `TextButton` laranja → fecha o dialog; `hasShownSuggestionDialog` **não** muda (volta na próxima sessão se FPS cair novamente)

---

## Sistema de qualidade dos tiles

`TileWidget` lê `performanceSettingsProvider.select((s) => s.tileQuality)` e renderiza um de três sub-widgets:

| `TileQuality` | Visual | Impacto |
|---------------|--------|---------|
| `full` | Imagem do animal a 27% opacidade sobre fundo colorido | Comportamento atual |
| `fullOpacity` | Imagem do animal a 100% opacidade | Elimina composite de alpha — render mais rápido |
| `simple` | Fundo colorido sólido + nome abreviado do animal (`GoogleFonts.fredoka`) | Sem asset — rebuild mínimo, máxima performance |

Cada variante é um `StatelessWidget` separado (`_FilledTileFull`, `_FilledTileFullOpacity`, `_FilledTileSimple`) — sem `if/else` no `build`, cada um é `const` onde possível.

`_FilledTileSimple` usa a cor de fundo do nível já mapeada no código existente + nome do animal de `Animal.name` — zero I/O de imagem.

---

## Tela de Configurações — seção Performance

Adicionada abaixo das seções existentes, mesmo padrão visual de "Gameplay" e "Áudio":

```
─── Performance ──────────────────────────────────
  Modo de Performance               [Switch]
  Detecção automática               [Switch]

  (apenas quando modo ativo — opacity 0.4 se desativado)
  Qualidade dos tiles:
    [Completo] [Sem opacidade] [Simples]   ← SegmentedButton Material 3

  Efeitos de blur                   [Switch]
  Animações                         [Switch]
```

`animationsEnabled = false` desativa: mascot bob (`capivara_mascot.dart`), pulse do tile do dia (`daily_reward_day_tile.dart`), sparkles de recompensa (`daily_reward_day_tile.dart`), e scale/fade do claim de recompensa diária. Animações de UI críticas (game over, milestone dialog) **não** são afetadas — só as decorativas/idle.

- Toggle "Reduzir efeitos visuais" existente é **removido**.
- Quando `enabled = false`, os controles de detalhe ficam visíveis mas com `opacity: 0.4` e `IgnorePointer` — o usuário vê o estado sem poder alterar.

---

## Fix do swipe (independente do performance mode)

`game_screen.dart:210`:
```dart
// antes
const threshold = 100.0;
// depois
const threshold = 50.0;
```

Aplicado sempre, sem feature flag. Corrige swipes lentos/curtos que não eram detectados.

---

## Critérios de sucesso

1. Redmi Note 9s consegue jogar uma partida completa sem frame drops visíveis com `TileQuality.simple` ativo.
2. Dialog de sugestão aparece automaticamente na primeira sessão com FPS < 45 sustentado.
3. Usuário pode reativar imagens completas em Configurações sem reiniciar o app.
4. `reduceEffectsProvider` removido sem regressão no `pause_overlay.dart`.
5. Swipe registrado com velocidade ≥ 50px/s (antes: ≥ 100px/s).
6. Testes unitários para `PerformanceSettingsNotifier` (enable/disable, persistência, TileQuality).
