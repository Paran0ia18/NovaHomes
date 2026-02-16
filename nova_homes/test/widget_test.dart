import 'package:flutter_test/flutter_test.dart';
import 'package:nova_homes/main.dart';

void main() {
  testWidgets('Onboarding renders expected content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NovaHomesApp());
    expect(find.text('Get Started'), findsOneWidget);
  });
}
