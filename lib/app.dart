import 'package:flutter/material.dart';
import 'presentation/screens/game/game_screen.dart';

class CapivaraApp extends StatelessWidget {
  const CapivaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Capivara 2048',
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    );
  }
}
