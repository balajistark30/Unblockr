import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unblockr/main.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {

    await tester.pumpWidget(const UnblockrApp());

    // Check if splash text appears
    expect(find.text('Unblockr'), findsOneWidget);
    expect(find.text('Parking, solved.'), findsOneWidget);

  });
}