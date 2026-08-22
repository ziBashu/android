import 'package:flutter_test/flutter_test.dart';
import 'package:unfold/core/recents.dart';
import 'package:unfold/main.dart';

void main() {
  testWidgets('Unfold boots with tagline and from ziBashu', (tester) async {
    await tester.pumpWidget(UnfoldApp(recents: MemoryRecents()));
    await tester.pump();
    expect(find.textContaining('Unfold'), findsWidgets);
    expect(find.text('Open. Read. Edit.'), findsOneWidget);
    expect(find.textContaining('from ziBashu'), findsWidgets);
    expect(find.text('Open a file'), findsOneWidget);
  });
}
