// lib/testing/test_runner_app.dart
import 'package:flutter/material.dart';
import 'test_result.dart';
import 'test_runner_screen.dart';

class TestRunnerApp extends StatelessWidget {
  final TestResultsStore store;
  final VoidCallback? onRunDemo;

  const TestRunnerApp({
    super.key,
    required this.store,
    this.onRunDemo,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bichim TEST',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: TestRunnerScreen(
        store: store,
        onRunDemo: onRunDemo,
      ),
    );
  }
}
