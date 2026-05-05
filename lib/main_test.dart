// lib/main_test.dart
//
// Entry point do flavor `tst` — usado pela Fase 3.6 do framework E2E.
//
// O APK Tier 2 é construído com:
//   flutter build apk \
//     --target=integration_test/tier2_runner.dart \
//     --flavor tst \
//     --release
//
// Este arquivo existe para documentar o entry point alternativo e pode ser
// usado no futuro para uma versão "demo-only" sem integration_test binding.
//
// Para o runner completo (com assertions), use integration_test/tier2_runner.dart.

void main() {
  // Redirecionar para integration_test/tier2_runner.dart via build command.
  // Ver docs/plans/2026-05-05-fase-3.6-tier2-apk-test-runner.md
}
