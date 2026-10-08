import 'package:flutter_test/flutter_test.dart';
import 'package:weft_mobile/main.dart';

void main() {
  testWidgets('WeftApp smoke test — splash renders', (WidgetTester tester) async {
    // Verify the app builds and shows the splash screen.
    await tester.pumpWidget(const WeftApp());

    expect(find.text('Weft'), findsOneWidget);
    expect(find.text('Report. Track. Resolve.'), findsOneWidget);

    // Pump through the 2-second splash delay to avoid pending timer assertion
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
