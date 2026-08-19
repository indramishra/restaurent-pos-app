import 'package:flutter_test/flutter_test.dart';

import 'package:restorent_pos_system/main.dart';

void main() {
  testWidgets('Customer landing renders Browse Menu', (WidgetTester tester) async {
    await tester.pumpWidget(const CustomerApp());

    expect(find.text('Browse Menu'), findsOneWidget);
  });
}