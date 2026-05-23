import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dong_neu/main.dart';

void main() {
  testWidgets('renders DongNeu home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DongNeuApp());

    expect(find.text('충남대 궁동'), findsOneWidget);
    expect(find.text('AI 맞춤 추천'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('오늘의 동네픽'), findsOneWidget);
    expect(find.text('궁동 칼국수'), findsOneWidget);
  });
}
