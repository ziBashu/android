import 'package:flutter_test/flutter_test.dart';
import 'package:keyline/main.dart';

void main() {
  testWidgets('KEYLINE setup screen states privacy and enable path', (tester) async {
    await tester.pumpWidget(const KEYLINEApp());
    expect(find.textContaining('KEYLINE'), findsWidgets);
    expect(
      find.textContaining('never sends what you type to a server'),
      findsOneWidget,
    );
    expect(find.textContaining('from ziBashu'), findsWidgets);
    expect(find.text('Open keyboard settings'), findsOneWidget);
    expect(find.text('KEYLINE settings'), findsOneWidget);
  });
}
