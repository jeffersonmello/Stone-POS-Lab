import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stone_pos_lab/catalog_page.dart';
import 'package:stone_pos_lab/lab_data.dart';

void main() {
  testWidgets('filtra o catálogo e cria a partir do perfil selecionado', (
    tester,
  ) async {
    final profiles = (await tester.runAsync(PosProfile.load))!;
    expect(profiles.length, greaterThanOrEqualTo(11));
    expect(
      profiles.map((profile) => profile.id).toSet(),
      hasLength(profiles.length),
    );
    tester.view.physicalSize = const Size(1000, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    PosProfile? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatalogPage(
            profiles: profiles,
            create: (profile) => selected = profile,
            openSource: (_) {},
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'L400');
    await tester.pumpAndSettle();
    expect(find.text('Ficha técnica'), findsOneWidget);
    expect(find.text('1 de ${profiles.length} perfis'), findsOneWidget);
    await tester.tap(find.text('Criar emulador'));
    expect(selected?.id, 'positivo-l400');
    expect(selected?.api, 30);
  });
}
