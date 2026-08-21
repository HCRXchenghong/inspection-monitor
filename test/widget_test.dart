import 'package:flutter_test/flutter_test.dart';
import 'package:room_guard/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RoomGuardApp());
    expect(find.text('RoomGuard'), findsOneWidget);
  });
}
