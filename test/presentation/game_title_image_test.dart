// test/presentation/game_title_image_test.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/widgets/game_title_image.dart';

void main() {
  const orange = 'assets/images/title/title_orange.png';
  const brown = 'assets/images/title/title_brown.png';
  const validAssets = {orange, brown};

  group('GameTitleImage.pickAsset', () {
    test('Random(0) retorna title_orange.png', () {
      final result = GameTitleImage.pickAsset(random: Random(0));
      expect(result, orange);
    });

    test('Random(1) retorna title_brown.png', () {
      final result = GameTitleImage.pickAsset(random: Random(1));
      expect(result, brown);
    });

    test('sem random injetado retorna um asset válido', () {
      final result = GameTitleImage.pickAsset();
      expect(validAssets, contains(result));
    });
  });

  group('GameTitleImage widget', () {
    testWidgets('renderiza Image.asset com path correto (orange)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameTitleImage(asset: orange, height: 220),
          ),
        ),
      );
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      final provider = image.image as AssetImage;
      expect(provider.assetName, orange);
    });

    testWidgets('renderiza Image.asset com path correto (brown)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameTitleImage(asset: brown, height: 220),
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as AssetImage;
      expect(provider.assetName, brown);
    });

    testWidgets('semanticLabel é "Olha o Bichim!"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameTitleImage(asset: orange),
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.semanticLabel, 'Olha o Bichim!');
    });
  });
}
