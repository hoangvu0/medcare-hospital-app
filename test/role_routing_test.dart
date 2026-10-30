import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bt2_2324801030077/main.dart';

void main() {
  Future<void> signIn(
    WidgetTester tester, {
    required String identifier,
    required String password,
  }) async {
    await tester.pumpWidget(const HospitalApp());
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), identifier);
    await tester.enterText(find.byType(TextField).at(1), password);
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
  }

  testWidgets('doctor account lands in EMR workstation', (tester) async {
    await signIn(tester, identifier: 'doctor@medcare.vn', password: '123456');

    expect(find.textContaining('EMR Workstation'), findsOneWidget);
  });

  testWidgets('admin account lands in slot administration', (tester) async {
    await signIn(tester, identifier: 'admin@medcare.vn', password: 'admin123');

    expect(find.textContaining('Slot'), findsWidgets);
    expect(find.textContaining('Admin'), findsWidgets);
  });
}
