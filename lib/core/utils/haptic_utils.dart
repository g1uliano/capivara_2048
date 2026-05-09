// lib/core/utils/haptic_utils.dart
import 'package:flutter/services.dart';

enum HapticIntensity { light, medium, heavy }

/// Fires haptic feedback if [isEnabled] returns true.
///
/// Pass a closure that reads the haptic setting:
/// ```dart
/// maybeHaptic(() => ref.read(settingsProvider).hapticEnabled,
///     intensity: HapticIntensity.heavy);
/// ```
void maybeHaptic(
  bool Function() isEnabled, {
  HapticIntensity intensity = HapticIntensity.light,
}) {
  if (!isEnabled()) return;
  switch (intensity) {
    case HapticIntensity.light:
      HapticFeedback.lightImpact();
    case HapticIntensity.medium:
      HapticFeedback.mediumImpact();
    case HapticIntensity.heavy:
      HapticFeedback.heavyImpact();
  }
}
