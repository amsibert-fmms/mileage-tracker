import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mileage_tracker/main.dart';

void main() {
  testWidgets('user can log a personal trip with category selection',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MileageTrackerApp());

    expect(find.text('No trip in progress'), findsOneWidget);

    final personalChip =
        find.widgetWithText(ChoiceChip, 'Personal');
    await tester.tap(personalChip);
    await tester.pump();

    final chipWidget = tester.widget<ChoiceChip>(personalChip);
    expect(chipWidget.selected, isTrue);

    await tester.tap(find.text('Start Trip'));
    await tester.pump();

    expect(find.textContaining('Category: Personal'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Stop Trip'));
    await tester.pump();

    expect(find.text('Start Trip'), findsOneWidget);
    expect(find.text('Recent trips'), findsOneWidget);
    expect(find.textContaining('Trip from'), findsOneWidget);

    final listTile = tester.widget<ListTile>(find.byType(ListTile).first);
    final subtitle = listTile.subtitle as Text;
    expect(subtitle.data, isNotNull);
    expect(subtitle.data!, contains('Personal · Elapsed'));
  });
}
