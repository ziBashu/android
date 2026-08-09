import 'package:flutter_test/flutter_test.dart';
import 'package:flux/main.dart';

void main() {
  testWidgets('Flux boots', (tester) async {
    await tester.pumpWidget(const FluxApp());
    await tester.pump();
    expect(find.textContaining('Flux'), findsWidgets);
  });
}
