// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:axionym_guard/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AxionymApp());

    // Verify that our app title is present.
    // The title is split into two TextSpans, so we look for the RichText or just partial text if possible,
    // but 'AXIONYM' is a distinct text span.
    expect(find.text('AXIONYM'), findsOneWidget);
    expect(find.text('.GUARD'), findsOneWidget);

    // Verify that the QUIZ tab is selected by default
    expect(find.text('ASSESSMENT SEQUENCE'), findsOneWidget);
  });
}
