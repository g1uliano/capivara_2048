// lib/testing/share_results.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'test_result.dart';

/// Exporta resultados como JSON + PNG e abre o share sheet.
Future<void> shareTestResults({
  required TestResultsStore store,
  required GlobalKey screenshotKey,
}) async {
  final packageInfo = await PackageInfo.fromPlatform();
  final tmpDir = await getTemporaryDirectory();

  // JSON
  final json = jsonEncode({
    'build': '${packageInfo.version}+${packageInfo.buildNumber}',
    'totals': {
      'passed': store.passed,
      'failed': store.failed,
      'skipped': store.skipped,
      'total': store.total,
    },
    'results': store.value.map((r) => r.toJson()).toList(),
  });
  final jsonFile = File('${tmpDir.path}/test_results.json');
  await jsonFile.writeAsString(json);

  // PNG screenshot do widget marcado com screenshotKey
  final boundary = screenshotKey.currentContext
      ?.findRenderObject() as RenderRepaintBoundary?;
  final files = <XFile>[XFile(jsonFile.path, mimeType: 'application/json')];

  if (boundary != null) {
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      final pngFile = File('${tmpDir.path}/test_results.png');
      await pngFile.writeAsBytes(byteData.buffer.asUint8List());
      files.add(XFile(pngFile.path, mimeType: 'image/png'));
    }
  }

  await Share.shareXFiles(
    files,
    text:
        '🐾 Bichim TEST — ${store.passed}✓ ${store.failed}✗ de ${store.total}',
  );
}
