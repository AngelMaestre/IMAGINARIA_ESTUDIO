// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:imaginaria_estudio/screens/home_screen.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our HomeScreen envuelto en un MaterialApp
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    // Como ya no tienes contador, puedes dejar esto en blanco
    // o cambiar el test a algo que tenga sentido para tu app:
    expect(find.text('Blog · LaVidaEnLetras'), findsOneWidget);
  });
}
