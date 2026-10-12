import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_ai_scheduler/screens/create_post_screen.dart';
import 'package:social_ai_scheduler/screens/scheduler_screen.dart';

void main() {
  Future<void> pump(WidgetTester t) => t.pumpWidget(MaterialApp(
        home: const CreatePostScreen(),
        routes: {'/schedule': (_) => const SchedulerScreen()},
      ));

  ElevatedButton scheduleButton(WidgetTester t) =>
      t.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Schedule'));

  testWidgets('Schedule is disabled until the caption is valid', (t) async {
    await pump(t);
    expect(find.text('Caption is empty.'), findsOneWidget);
    expect(scheduleButton(t).onPressed, isNull);

    await t.enterText(find.widgetWithText(TextField, 'Caption'), 'Night shift');
    await t.enterText(
        find.widgetWithText(TextField, 'Hashtags (space or comma separated)'),
        '#icu #health #care');
    await t.pump();
    expect(scheduleButton(t).onPressed, isNotNull);
  });

  testWidgets('Apply fixes removes duplicates, then schedule shows the post',
      (t) async {
    await pump(t);
    await t.enterText(find.widgetWithText(TextField, 'Caption'), 'Night shift');
    await t.enterText(
        find.widgetWithText(TextField, 'Hashtags (space or comma separated)'),
        'icu, #ICU health care');
    await t.pump();
    expect(find.text('#ICU is duplicated.'), findsOneWidget);

    await t.tap(find.text('Apply fixes'));
    await t.pump();
    expect(find.text('#ICU is duplicated.'), findsNothing);

    await t.tap(find.text('Schedule'));
    await t.pumpAndSettle();
    expect(find.text('#icu #health #care'), findsOneWidget);
  });
}
