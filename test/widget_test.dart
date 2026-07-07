import 'package:flutter_test/flutter_test.dart';

import 'package:panchang_calendar/main.dart';

void main() {
  testWidgets('Panchang Calendar smoke test', (tester) async {
    await tester.pumpWidget(const PanchangCalendarApp());
    await tester.pump();

    expect(find.text('PANCHANG CALENDAR'), findsOneWidget);
    expect(find.text('Enter'), findsOneWidget);
    expect(find.text('VIKRAM SAMVAT 2080'), findsNothing);
  });
}
