import 'package:flutter_test/flutter_test.dart';
import 'package:colombopal/main.dart';

void main() {
  testWidgets('ColomboPal app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ColomboPalApp());

    // Allow the first screen to finish building.
    await tester.pumpAndSettle();

    // Check that the My Reports screen appears.
    expect(find.text('My Reports'), findsOneWidget);
  });
}