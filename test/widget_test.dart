import 'package:flutter_test/flutter_test.dart';
import 'package:uniride/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const UniRideApp());
    expect(find.text('UniRide'), findsOneWidget);
  });
}
