// test/presentation/shop_screen_test.dart

import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/data/repositories/lives_repository.dart';
import 'package:capivara_2048/data/repositories/share_codes_repository.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/domain/shop/share_codes_notifier.dart';
import 'package:capivara_2048/presentation/screens/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

late Directory _tempDir;

Future<void> _initHive() async {
  _tempDir = await Directory.systemTemp.createTemp('shop_test');
  Hive.init(_tempDir.path);
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LivesStateAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
}

Future<void> _teardownHive() async {
  await Hive.close();
  await _tempDir.delete(recursive: true);
}

Widget _buildShop() {
  return ProviderScope(
    overrides: [
      inventoryRepositoryProvider.overrideWithValue(InventoryRepository()),
      livesRepositoryProvider.overrideWithValue(LivesRepository()),
      shareCodesRepositoryProvider.overrideWithValue(ShareCodesRepository()),
    ],
    child: const MaterialApp(home: ShopScreen()),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _initHive();
  });

  tearDown(_teardownHive);

  testWidgets('6 cards de pacotes presentes no widget tree', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();

    expect(find.text('4× Bomba 3'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Combo Floresta Amazônica'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.text('Combo Floresta Amazônica'), findsOneWidget);
  });

  testWidgets('badges 75% presentes (p3 e p4)', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();
    expect(find.text('75%'), findsWidgets);
  });

  testWidgets('badges 50% presentes (p1, p2, p5, p6)', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();
    expect(find.text('50%'), findsWidgets);
  });

  testWidgets('tap Comprar → AlertDialog de confirmação aparece', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Comprar').first);
    await tester.pumpAndSettle();

    expect(find.text('Confirmar compra'), findsOneWidget);
  });

  testWidgets('cancelar AlertDialog → sem sheet aberto', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Comprar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Presente gerado!'), findsNothing);
  });

  testWidgets('confirmar compra p1 → GiftCodeSheet aparece após confirmação', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Comprar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Presente gerado!'), findsOneWidget);
  });

  testWidgets('_GiftCodeSheet → código em formato xxxx-xxxx-xxxx', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Comprar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();

    final codePattern = RegExp(r'^[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}$');
    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    final codeText = textWidgets
        .map((t) => t.data ?? '')
        .where((s) => codePattern.hasMatch(s))
        .firstOrNull;
    expect(codeText, isNotNull);
  });

  testWidgets('botão Copiar → snackbar "Copiado!" aparece', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Comprar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.copy_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Copiado!'), findsOneWidget);
  });

  testWidgets('seção Itens avulsos presente abaixo dos pacotes', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Itens avulsos'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.text('Itens avulsos'), findsOneWidget);
  });

  testWidgets('4 cards de itens avulsos com preços corretos', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('R\$ 1,99'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.dragUntilVisible(
      find.text('R\$ 0,99'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.text('R\$ 1,99'), findsOneWidget);
    expect(find.text('R\$ 0,99'), findsOneWidget);
    expect(find.text('R\$ 1,19'), findsOneWidget);
    expect(find.text('R\$ 0,49'), findsOneWidget);
  });

  testWidgets('tap Comprar item avulso → AlertDialog com preço', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('R\$ 1,99'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('R\$ 1,99').first);
    await tester.pumpAndSettle();
    expect(find.text('Confirmar compra'), findsOneWidget);
    expect(find.textContaining('Bomba 3'), findsWidgets);
  });
}
