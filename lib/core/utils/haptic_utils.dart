import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/controllers/settings_notifier.dart';

void maybeHaptic(WidgetRef ref) {
  if (ref.read(settingsProvider).hapticEnabled) {
    HapticFeedback.lightImpact();
  }
}
