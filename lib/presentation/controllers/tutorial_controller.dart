// lib/presentation/controllers/tutorial_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/sync/sync_engine.dart';
import 'auth_controller.dart';

class TutorialController extends Notifier<void> {
  @override
  void build() {}

  Future<bool> isCompleted() async {
    final profile = ref.read(authControllerProvider);
    if (profile != null) {
      return profile.tutorialCompleted;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tutorial_completed') ?? false;
  }

  Future<void> markCompleted() async {
    final profile = ref.read(authControllerProvider);
    if (profile != null) {
      await ref.read(syncEngineProvider).updateTutorialCompleted(true);
      ref.read(authControllerProvider.notifier).updateProfileTutorialFlag(true);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tutorial_completed', true);
    }
  }
}

final tutorialControllerProvider = NotifierProvider<TutorialController, void>(
  TutorialController.new,
);
