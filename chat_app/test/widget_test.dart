// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ChatApp());
    expect(find.byType(ChatApp), findsOneWidget);
  });
}
