import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/performance/performance_settings.dart';

void main() {
  group('PerformanceSettings', () {
    test('defaults: disabled, full quality, blur on, animations on, autoDetect on', () {
      const s = PerformanceSettings();
      expect(s.enabled, false);
      expect(s.tileQuality, TileQuality.full);
      expect(s.blurEffectsEnabled, true);
      expect(s.animationsEnabled, true);
      expect(s.autoDetectEnabled, true);
      expect(s.hasShownSuggestionDialog, false);
    });

    test('copyWith altera apenas o campo especificado', () {
      const s = PerformanceSettings();
      final s2 = s.copyWith(enabled: true, tileQuality: TileQuality.simple);
      expect(s2.enabled, true);
      expect(s2.tileQuality, TileQuality.simple);
      expect(s2.blurEffectsEnabled, true);
      expect(s2.animationsEnabled, true);
    });

    test('toJson / fromJson round-trip', () {
      const s = PerformanceSettings(
        enabled: true,
        tileQuality: TileQuality.fullOpacity,
        blurEffectsEnabled: false,
        animationsEnabled: false,
        autoDetectEnabled: false,
        hasShownSuggestionDialog: true,
      );
      final s2 = PerformanceSettings.fromJson(s.toJson());
      expect(s2.enabled, true);
      expect(s2.tileQuality, TileQuality.fullOpacity);
      expect(s2.blurEffectsEnabled, false);
      expect(s2.animationsEnabled, false);
      expect(s2.autoDetectEnabled, false);
      expect(s2.hasShownSuggestionDialog, true);
    });

    test('fromJson com chave ausente usa defaults em todos os campos', () {
      final s = PerformanceSettings.fromJson({});
      expect(s.enabled, false);
      expect(s.tileQuality, TileQuality.full);
      expect(s.blurEffectsEnabled, true);
      expect(s.animationsEnabled, true);
      expect(s.autoDetectEnabled, true);
      expect(s.hasShownSuggestionDialog, false);
    });

    test('fromJson com tileQuality fora do range usa full', () {
      final s = PerformanceSettings.fromJson({'tileQuality': 99});
      expect(s.tileQuality, TileQuality.full);
    });

    test('== e hashCode baseados em campos', () {
      const a = PerformanceSettings(enabled: true);
      const b = PerformanceSettings(enabled: true);
      const c = PerformanceSettings(enabled: false);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });
}
