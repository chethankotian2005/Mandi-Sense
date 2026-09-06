import 'package:flutter_test/flutter_test.dart';

import 'package:mandisense_app/main.dart';

void main() {
  testWidgets('App launches correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MandiSenseApp());

    // Verify the app title is present
    expect(find.text('MandiSense'), findsOneWidget);
  });
}
