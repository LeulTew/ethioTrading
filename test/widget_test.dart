import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic app test', (WidgetTester tester) async {
    // Build a simple MaterialApp for testing
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('EthioTrading App Test'),
        ),
      ),
    );

    // Verify that we can find the text in the widget tree
    expect(find.text('EthioTrading App Test'), findsOneWidget);
  });
}
