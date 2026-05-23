import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dong_neu/main.dart';

void main() {
  testWidgets('renders DongNeu email auth screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const DongNeuApp());

    expect(find.text('반가워U, 동네유!'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    expect(
      find.text('Supabase URL과 anon key를 --dart-define으로 넣어야 해요.'),
      findsOneWidget,
    );
  });
}
