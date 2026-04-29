import 'package:flutter_test/flutter_test.dart';

import 'package:trade_mate/app/trade_mate_app.dart';

void main() {
  testWidgets('Login page renders expected fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TradeMateApp());
    await tester.pumpAndSettle();

    expect(find.text('Management Portal'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('EMPLOYEE ID / EMAIL'), findsOneWidget);
    expect(find.text('SECURE PASSWORD'), findsOneWidget);
    expect(find.text('Forgot?'), findsOneWidget);
    expect(find.text('Sign In to Dashboard'), findsOneWidget);
    expect(find.text("Don't have an account? Register"), findsOneWidget);
  });
}
