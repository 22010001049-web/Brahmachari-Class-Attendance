import 'package:flutter_test/flutter_test.dart';

import 'package:brahmachari_class_attendance/main.dart';

void main() {
  testWidgets('App renders home screen title', (WidgetTester tester) async {
    await tester.pumpWidget(const BrahmachariAttendanceApp());

    // Verify the home screen title is displayed.
    expect(find.text('Brahmachari Class Attendance'), findsOneWidget);
  });
}
