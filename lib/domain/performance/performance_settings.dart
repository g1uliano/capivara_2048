enum TileQuality { full, fullOpacity, simple }

class PerformanceSettings {
  const PerformanceSettings({
    this.enabled = false,
    this.tileQuality = TileQuality.full,
    this.blurEffectsEnabled = true,
    this.animationsEnabled = true,
    this.autoDetectEnabled = true,
    this.hasShownSuggestionDialog = false,
  });

  final bool enabled;
  final TileQuality tileQuality;
  final bool blurEffectsEnabled;
  final bool animationsEnabled;
  final bool autoDetectEnabled;
  final bool hasShownSuggestionDialog;

  PerformanceSettings copyWith({
    bool? enabled,
    TileQuality? tileQuality,
    bool? blurEffectsEnabled,
    bool? animationsEnabled,
    bool? autoDetectEnabled,
    bool? hasShownSuggestionDialog,
  }) {
    return PerformanceSettings(
      enabled: enabled ?? this.enabled,
      tileQuality: tileQuality ?? this.tileQuality,
      blurEffectsEnabled: blurEffectsEnabled ?? this.blurEffectsEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      autoDetectEnabled: autoDetectEnabled ?? this.autoDetectEnabled,
      hasShownSuggestionDialog:
          hasShownSuggestionDialog ?? this.hasShownSuggestionDialog,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'tileQuality': tileQuality.index,
        'blurEffectsEnabled': blurEffectsEnabled,
        'animationsEnabled': animationsEnabled,
        'autoDetectEnabled': autoDetectEnabled,
        'hasShownSuggestionDialog': hasShownSuggestionDialog,
      };

  factory PerformanceSettings.fromJson(Map<String, dynamic> json) =>
      PerformanceSettings(
        enabled: json['enabled'] as bool? ?? false,
        tileQuality: TileQuality.values[json['tileQuality'] as int? ?? 0],
        blurEffectsEnabled: json['blurEffectsEnabled'] as bool? ?? true,
        animationsEnabled: json['animationsEnabled'] as bool? ?? true,
        autoDetectEnabled: json['autoDetectEnabled'] as bool? ?? true,
        hasShownSuggestionDialog:
            json['hasShownSuggestionDialog'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceSettings &&
          enabled == other.enabled &&
          tileQuality == other.tileQuality &&
          blurEffectsEnabled == other.blurEffectsEnabled &&
          animationsEnabled == other.animationsEnabled &&
          autoDetectEnabled == other.autoDetectEnabled &&
          hasShownSuggestionDialog == other.hasShownSuggestionDialog;

  @override
  int get hashCode => Object.hash(
        enabled,
        tileQuality,
        blurEffectsEnabled,
        animationsEnabled,
        autoDetectEnabled,
        hasShownSuggestionDialog,
      );
}
