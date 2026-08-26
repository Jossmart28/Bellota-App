import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bellotadevelopment/main.dart';

void main() {
  testWidgets('BellotaApp smoke test', (WidgetTester tester) async {
    // Construir la app y verificar que inicia correctamente
    await tester.pumpWidget(const BellotaApp());
    // Verificar que el widget SplashScreen se renderiza
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
