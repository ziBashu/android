import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seru/main.dart';
import 'package:seru/screens/shell.dart';

void main() {
  testWidgets('Seru shell shows Chat Friends Thread Me tabs', (tester) async {
    await tester.pumpWidget(const SeruApp(demoShell: true));
    await tester.pumpAndSettle();

    expect(find.text('Chat'), findsWidgets);
    expect(find.text('Friends'), findsWidgets);
    expect(find.text('Thread'), findsWidgets);
    expect(find.text('Me'), findsWidgets);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(seruTabLabels, ['Chat', 'Friends', 'Thread', 'Me']);
  });

  testWidgets('Seru shell is not a WebView', (tester) async {
    await tester.pumpWidget(const SeruApp(demoShell: true));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    final webViewTypes = [
      'WebViewWidget',
      'WebView',
      'InAppWebView',
    ];
    for (final name in webViewTypes) {
      expect(find.byWidgetPredicate((w) => w.runtimeType.toString() == name), findsNothing);
    }
  });
}
