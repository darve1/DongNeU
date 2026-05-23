import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dong_neu/main.dart';

void main() {
  testWidgets('renders DongNeu onboarding to home flow', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const DongNeuApp());

    expect(find.text('반가워U, 동네유!'), findsOneWidget);

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('손님으로 시작하기'), findsOneWidget);

    await tester.tap(find.text('추천 받으러 가기'));
    await tester.pumpAndSettle();

    expect(find.text('내 동네 설정'), findsOneWidget);

    await tester.tap(find.text('이 위치로 설정'));
    await tester.pumpAndSettle();

    expect(find.text('충남대 궁동'), findsOneWidget);
    expect(find.text('AI 맞춤 추천'), findsOneWidget);
  });
}
