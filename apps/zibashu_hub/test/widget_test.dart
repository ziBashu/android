import 'package:flutter_test/flutter_test.dart';
import 'package:zibashu_hub/main.dart';

void main() {
  testWidgets('Hub shows family title', (tester) async {
    await tester.pumpWidget(const HubApp());
    expect(find.textContaining('ziBashu'), findsWidgets);
  });
}
