import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:utms_mobile/main.dart';

void main() {
  testWidgets('UTMS app launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: UTMSApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}