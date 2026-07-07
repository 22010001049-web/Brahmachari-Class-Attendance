import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/class_model.dart';
import '../models/brahmachari_model.dart';
import '../models/attendance_model.dart';

class MonthlyReportData {
  final int year;
  final int month;
  final int totalClasses;
  final int greenCount;
  final int lateCount;
  final int absentCount;
  final double attendancePercent;

  MonthlyReportData({
    required this.year,
    required this.month,
    required this.totalClasses,
    required this.greenCount,
    required this.lateCount,
    required this.absentCount,
    required this.attendancePercent,
  });
}

class PdfService {
  Future<Uint8List> generateMonthlyReport({
    required List<ClassModel> classes,
    required List<BrahmachariModel> brahmacharis,
    required List<AttendanceModel> allAttendance,
    required int year,
    required int month,
  }) async {
    final doc = pw.Document();

    final monthClasses = classes.where((c) {
      final parts = c.classDate.split('-');
      return int.parse(parts[0]) == year && int.parse(parts[1]) == month;
    }).toList();

    final totalBrahmacharis = brahmacharis.length;
    final totalClasses = monthClasses.length;
    final classIds = monthClasses.map((c) => c.id).toSet();
    final monthAttendance =
        allAttendance.where((a) => classIds.contains(a.classId)).toList();

    final greenCount =
        monthAttendance.where((a) => a.status == 'green').length;
    final lateCount =
        monthAttendance.where((a) => a.status == 'red').length;
    final totalPossible = totalClasses * totalBrahmacharis;
    final absentCount = totalPossible - monthAttendance.length;
    final attendancePercent = totalPossible > 0
        ? ((monthAttendance.length / totalPossible) * 100)
        : 0.0;

    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Monthly Attendance Report',
                style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Header(level: 1, child: pw.Text(monthName)),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _statBox('Total Classes', '$totalClasses'),
              _statBox('Total Brahmacharis', '$totalBrahmacharis'),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _statBox('Green (On Time)', '$greenCount',
                  color: PdfColor.fromInt(0xFF4CAF50)),
              _statBox('Late', '$lateCount',
                  color: PdfColor.fromInt(0xFFF44336)),
              _statBox('Absent', '$absentCount',
                  color: PdfColor.fromInt(0xFF9E9E9E)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE3F2FD),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Attendance Rate',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text(
                  '${attendancePercent.toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                    fontSize: 36,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1565C0),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '$greenCount on-time out of $totalPossible total entries',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Header(level: 2, child: pw.Text('Class-wise Attendance')),
          if (monthClasses.isEmpty)
            pw.Text('No classes in this month.')
          else
            ...monthClasses.map((c) {
              final cAttendance =
                  monthAttendance.where((a) => a.classId == c.id).toList();
              final cGreen =
                  cAttendance.where((a) => a.status == 'green').length;
              final cLate =
                  cAttendance.where((a) => a.status == 'red').length;
              final cAbsent = totalBrahmacharis - cAttendance.length;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                      color: PdfColor.fromInt(0xFFE0E0E0)),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${c.speakerName} - ${c.classDate}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                        'On Time: $cGreen  |  Late: $cLate  |  Absent: $cAbsent'),
                  ],
                ),
              );
            }),
          pw.SizedBox(height: 24),
          pw.Header(level: 2, child: pw.Text('Brahmachari-wise Report')),
          ...brahmacharis.map((b) {
            final bAttendance =
                monthAttendance.where((a) => a.brahmachariId == b.id).toList();
            final bGreen =
                bAttendance.where((a) => a.status == 'green').length;
            final bLate =
                bAttendance.where((a) => a.status == 'red').length;
            final bAbsent = totalClasses - bAttendance.length;
            final bPercent = totalClasses > 0
                ? ((bGreen / totalClasses) * 100).toStringAsFixed(0)
                : '0';
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                  '$b.name: $bGreen on-time, $bLate late, $bAbsent absent ($bPercent%)'),
            );
          }),
        ],
      ),
    );

    return await doc.save();
  }

  Future<Uint8List> generateFullReport({
    required List<ClassModel> classes,
    required List<BrahmachariModel> brahmacharis,
    required List<AttendanceModel> allAttendance,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final doc = pw.Document();

    final dateStr =
        '${DateFormat('dd MMM yyyy').format(fromDate)} - ${DateFormat('dd MMM yyyy').format(toDate)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Attendance Report',
                style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Header(level: 1, child: pw.Text(dateStr)),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _statBox('Total Classes', '${classes.length}'),
              _statBox('Total Brahmacharis', '${brahmacharis.length}'),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _statBox('Total Records', '${allAttendance.length}'),
              _statBox('On Time',
                  '${allAttendance.where((a) => a.status == 'green').length}',
                  color: PdfColor.fromInt(0xFF4CAF50)),
              _statBox('Late',
                  '${allAttendance.where((a) => a.status == 'red').length}',
                  color: PdfColor.fromInt(0xFFF44336)),
            ],
          ),
          pw.SizedBox(height: 24),
          ...classes.map((c) {
            final cAttendance =
                allAttendance.where((a) => a.classId == c.id).toList();
            final cGreen =
                cAttendance.where((a) => a.status == 'green').length;
            final cLate =
                cAttendance.where((a) => a.status == 'red').length;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: PdfColor.fromInt(0xFFE0E0E0)),
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${c.speakerName} - ${c.classDate} @ ${c.startTime}',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                      'Present: ${cAttendance.length}  |  On Time: $cGreen  |  Late: $cLate'),
                ],
              ),
            );
          }),
        ],
      ),
    );

    return await doc.save();
  }

  pw.Widget _statBox(String label, String value, {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0x1A2196F3),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: color ?? PdfColor.fromInt(0xFF2196F3))),
          pw.SizedBox(height: 4),
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
