// lib/testing/test_result.dart
import 'package:flutter/foundation.dart';

enum TestStatus { pending, running, passed, failed, skipped }

class TestResult {
  final String id;
  final String title;
  final String category; // ex: "flow", "engine", "nav"
  final TestStatus status;
  final Duration? duration;
  final String? errorMessage;
  final String? stackTrace;

  const TestResult({
    required this.id,
    required this.title,
    required this.category,
    this.status = TestStatus.pending,
    this.duration,
    this.errorMessage,
    this.stackTrace,
  });

  TestResult copyWith({
    TestStatus? status,
    Duration? duration,
    String? errorMessage,
    String? stackTrace,
  }) {
    return TestResult(
      id: id,
      title: title,
      category: category,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.name,
        'ms': duration?.inMilliseconds,
        if (errorMessage != null) 'error': errorMessage,
        if (stackTrace != null) 'stack': stackTrace,
      };
}

/// ValueNotifier que o tier2_runner popula e o TestRunnerScreen consome.
class TestResultsStore extends ValueNotifier<List<TestResult>> {
  TestResultsStore() : super([]);

  void initWith(List<TestResult> results) {
    value = List.unmodifiable(results);
  }

  void update(String id, TestResult updated) {
    value = List.unmodifiable(
      value.map((r) => r.id == id ? updated : r).toList(),
    );
  }

  int get passed => value.where((r) => r.status == TestStatus.passed).length;
  int get failed => value.where((r) => r.status == TestStatus.failed).length;
  int get skipped => value.where((r) => r.status == TestStatus.skipped).length;
  int get running => value.where((r) => r.status == TestStatus.running).length;
  int get pending => value.where((r) => r.status == TestStatus.pending).length;
  int get total => value.length;

  bool get isDone => pending == 0 && running == 0;

  Map<String, List<TestResult>> get byCategory {
    final map = <String, List<TestResult>>{};
    for (final r in value) {
      (map[r.category] ??= []).add(r);
    }
    return map;
  }
}

/// Singleton global para comunicação entre integration_test e lib/testing.
final testResultsStore = TestResultsStore();
