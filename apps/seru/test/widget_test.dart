import 'package:flutter_test/flutter_test.dart';
import 'package:seru/main.dart';

void main() {
  testWidgets('Seru shows login branding', (tester) async {
    await tester.pumpWidget(const SeruApp());
    await tester.pump(); // allow restore future to schedule
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Seru'), findsWidgets);
  });
}
