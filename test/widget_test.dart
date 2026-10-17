import 'package:flutter_test/flutter_test.dart';
import 'package:easy_swipe/main.dart';

void main() {
  testWidgets('EasySwipeApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EasySwipeApp());
    expect(find.text('EasySwipe'), findsOneWidget);
  });
}
