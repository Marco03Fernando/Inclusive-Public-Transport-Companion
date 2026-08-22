import 'package:flutter_test/flutter_test.dart';

import 'package:colombo_pal/app.dart';

void main() {
  testWidgets('App launches on the role-select screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ColomboPalApp());
    await tester.pumpAndSettle();

    expect(find.text('Colombo Pal'), findsOneWidget);
    expect(find.text('Passenger'), findsOneWidget);
    expect(find.text('Volunteer'), findsOneWidget);
  });

  testWidgets('Choosing a role opens the sign-up flow', (WidgetTester tester) async {
    await tester.pumpWidget(const ColomboPalApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Passenger').first);
    await tester.pumpAndSettle();

    expect(find.text('Your details'), findsOneWidget);
  });
}
