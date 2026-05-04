import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'tester_extensions.dart';

void main() {
  testWidgets('tapByKey: taps widget by string Key and settles', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          key: const Key('my_btn'),
          onPressed: () => tapped = true,
          child: const Text('x'),
        ),
      ),
    ));
    await tester.tapByKey('my_btn');
    expect(tapped, isTrue);
  });
}
