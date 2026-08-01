import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pennywise_ai/main.dart';

void main() {
  testWidgets('PennyWise app smoke test — renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PennyWiseApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
