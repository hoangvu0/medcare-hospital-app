import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bt2_2324801030077/main.dart';

void main() {
  testWidgets('người dùng đi qua onboarding và đăng nhập', (tester) async {
    await tester.pumpWidget(const HospitalApp());
    expect(find.text('MedCare Hospital'), findsOneWidget);

    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'vu@example.com');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Xin chào 👋'), findsOneWidget);
    expect(find.text('Nguyễn Hoàng Vũ'), findsOneWidget);
  });
}
