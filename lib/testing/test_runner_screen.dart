// lib/testing/test_runner_screen.dart
import 'package:flutter/material.dart';
import 'test_result.dart';
import 'share_results.dart';

class TestRunnerScreen extends StatefulWidget {
  final TestResultsStore store;
  final VoidCallback? onRunDemo;

  const TestRunnerScreen({
    super.key,
    required this.store,
    this.onRunDemo,
  });

  @override
  State<TestRunnerScreen> createState() => _TestRunnerScreenState();
}

class _TestRunnerScreenState extends State<TestRunnerScreen> {
  final _screenshotKey = GlobalKey();
  void _listener() => setState(() {});

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_listener);
  }

  @override
  void dispose() {
    widget.store.removeListener(_listener);
    super.dispose();
  }

  Color _statusColor(TestStatus s) => switch (s) {
        TestStatus.passed => Colors.green,
        TestStatus.failed => Colors.red,
        TestStatus.running => Colors.orange,
        TestStatus.skipped => Colors.grey,
        TestStatus.pending => Colors.grey.shade400,
      };

  String _statusIcon(TestStatus s) => switch (s) {
        TestStatus.passed => '✓',
        TestStatus.failed => '✗',
        TestStatus.running => '⟳',
        TestStatus.skipped => '⏭',
        TestStatus.pending => '○',
      };

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final categories = store.byCategory;

    return RepaintBoundary(
      key: _screenshotKey,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF16213E),
          title: const Text(
            'Bichim — Test Suite',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            if (store.isDone)
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                tooltip: 'Compartilhar resultados',
                onPressed: () => shareTestResults(
                  store: store,
                  screenshotKey: _screenshotKey,
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Totais
            Container(
              width: double.infinity,
              color: const Color(0xFF0F3460),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${store.passed}✓  ${store.failed}✗  ${store.skipped}⏭  ${store.pending}○  '
                '| total: ${store.total}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            // Lista por categoria
            Expanded(
              child: categories.isEmpty
                  ? const Center(
                      child: Text(
                        'Aguardando cenários...',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView(
                      children: categories.entries.map((entry) {
                        final cat = entry.key;
                        final results = entry.value;
                        final catPassed =
                            results.where((r) => r.status == TestStatus.passed).length;
                        final catFailed =
                            results.where((r) => r.status == TestStatus.failed).length;

                        return ExpansionTile(
                          initiallyExpanded: catFailed > 0,
                          collapsedBackgroundColor: const Color(0xFF16213E),
                          backgroundColor: const Color(0xFF1A1A2E),
                          title: Row(
                            children: [
                              Text(
                                cat,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text(
                                '✓$catPassed  ✗$catFailed',
                                style: TextStyle(
                                  color: catFailed > 0 ? Colors.red : Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          children: results.map((r) => _buildResultTile(r)).toList(),
                        );
                      }).toList(),
                    ),
            ),
            // Botões de ação
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: store.isDone
                            ? () => shareTestResults(
                                  store: store,
                                  screenshotKey: _screenshotKey,
                                )
                            : null,
                        icon: const Text('📤', style: TextStyle(fontSize: 16)),
                        label: const Text('Compartilhar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onRunDemo,
                        icon: const Text('🎬', style: TextStyle(fontSize: 16)),
                        label: const Text('Demo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber,
                          side: BorderSide(color: Colors.amber.withValues(alpha: 0.8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(TestResult r) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: r.errorMessage != null
          ? ExpansionTile(
              backgroundColor: const Color(0xFF1A1A2E),
              leading: Text(
                _statusIcon(r.status),
                style: TextStyle(
                    color: _statusColor(r.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              title: Text(
                r.id,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              subtitle: r.duration != null
                  ? Text('${r.duration!.inMilliseconds}ms',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 11))
                  : null,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SelectableText(
                    r.errorMessage ?? '',
                    style: const TextStyle(
                        color: Colors.red, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
                if (r.stackTrace != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: SelectableText(
                      r.stackTrace!,
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontFamily: 'monospace'),
                    ),
                  ),
              ],
            )
          : ListTile(
              dense: true,
              leading: Text(
                _statusIcon(r.status),
                style: TextStyle(
                    color: _statusColor(r.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              title: Text(
                r.id,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              trailing: r.duration != null
                  ? Text('${r.duration!.inMilliseconds}ms',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11))
                  : null,
            ),
    );
  }
}
