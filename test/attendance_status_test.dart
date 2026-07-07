import 'package:flutter_test/flutter_test.dart';

int parseTimeToMinutes(String timeStr) {
  final parts = timeStr.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  return hour * 60 + minute;
}

bool checkIsGreen(String classStartTimeStr, String arrivalTimeStr) {
  final startMinutes = parseTimeToMinutes(classStartTimeStr);
  final arrivalMinutes = parseTimeToMinutes(arrivalTimeStr);
  return arrivalMinutes <= startMinutes + 15;
}

void main() {
  group('Attendance Status Rules Tests', () {
    test('On Time: arrival is exactly equal to class start time', () {
      expect(checkIsGreen('08:30:00', '08:30:00'), isTrue);
    });

    test('On Time: arrival is 10 minutes after class start time', () {
      expect(checkIsGreen('08:30:00', '08:40:00'), isTrue);
    });

    test('On Time: arrival is exactly 15 minutes after class start time', () {
      expect(checkIsGreen('08:30:00', '08:45:00'), isTrue);
    });

    test('Late: arrival is 16 minutes after class start time', () {
      expect(checkIsGreen('08:30:00', '08:46:00'), isFalse);
    });

    test('Late: arrival is 1 hour after class start time', () {
      expect(checkIsGreen('08:30:00', '09:30:00'), isFalse);
    });
  });
}
