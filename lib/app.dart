import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/game/game_screen.dart';

class CapivaraApp extends StatelessWidget {
  const CapivaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capivara 2048',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const GameScreen(),
    );
  }
}
