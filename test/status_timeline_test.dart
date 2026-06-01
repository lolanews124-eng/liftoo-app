import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftoo_mobile/shared/widgets/status_timeline.dart';

void main() {
  testWidgets('StatusTimeline renders steps', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusTimeline(currentStatus: 'assigned')),
      ),
    );

    expect(find.text('Assigned'), findsOneWidget);
    expect(find.text('Searching'), findsOneWidget);
  });
}
