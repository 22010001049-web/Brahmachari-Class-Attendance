import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/class_model.dart';
import '../models/brahmachari_model.dart';
import '../models/attendance_model.dart';
import 'file_helper.dart';

class ExcelService {
  Future<String> generateAndSaveReport({
    required List<ClassModel> classes,
    required List<BrahmachariModel> brahmacharis,
    required List<AttendanceModel> allAttendance,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    if (classes.isEmpty) {
      throw Exception('No records found for selected dates.');
    }

    final excel = _buildExcel(classes, brahmacharis, allAttendance);
    final bytes = excel.save();
    if (bytes == null) throw Exception('Failed to generate Excel file');

    final fileName =
        'attendance_${_fmt(fromDate)}_to_${_fmt(toDate)}.xlsx';
    return saveBytesToFile(Uint8List.fromList(bytes), fileName);
  }

  String _fmt(DateTime d) =>
      '${d.year}_${d.month.toString().padLeft(2, '0')}_${d.day.toString().padLeft(2, '0')}';

  Excel _buildExcel(
    List<ClassModel> classes,
    List<BrahmachariModel> brahmacharis,
    List<AttendanceModel> allAttendance,
  ) {
    final excel = Excel.createExcel();
    final sheet = excel['Attendance'];

    final totalClasses = classes.length;
    final greenBg = ExcelColor.fromHexString('FFC6EFCE');
    final redBg = ExcelColor.fromHexString('FFFFC7CE');
    final headerBg = ExcelColor.fromHexString('FF4472C4');
    final headerFg = ExcelColor.fromHexString('FFFFFFFF');

    final Map<String, Map<String, AttendanceModel>> attendanceMap = {};
    for (final att in allAttendance) {
      attendanceMap.putIfAbsent(att.brahmachariId, () => {});
      attendanceMap[att.brahmachariId]![att.classId] = att;
    }

    int totalGreen = 0;
    int totalLate = 0;
    for (final att in allAttendance) {
      if (att.status == 'green') totalGreen++;
      if (att.status == 'red') totalLate++;
    }

    final headerStyle = CellStyle(
      backgroundColorHex: headerBg,
      fontColorHex: headerFg,
      bold: true,
    );
    final greenStyle = CellStyle(backgroundColorHex: greenBg);
    final redStyle = CellStyle(backgroundColorHex: redBg);
    final percentageStyle = CellStyle(bold: true);
    final summaryStyle = CellStyle(bold: true, fontSize: 12);

    const summaryOffset = 4;

    _setCell(sheet, 0, 0, TextCellValue('Total Classes: $totalClasses'), summaryStyle);
    _setCell(sheet, 0, 1, TextCellValue('Total Green Count: $totalGreen'), summaryStyle);
    _setCell(sheet, 0, 2, TextCellValue('Total Late Count: $totalLate'), summaryStyle);

    _setCell(sheet, 0, summaryOffset, TextCellValue('Name'), headerStyle);

    for (var ci = 0; ci < totalClasses; ci++) {
      final classModel = classes[ci];
      final dateParts = classModel.classDate.split('-');
      final month = _monthAbbr(int.parse(dateParts[1]));
      final day = int.parse(dateParts[2]);
      _setCell(sheet, ci + 1, summaryOffset, TextCellValue('$day $month'), headerStyle);
    }

    final presentCol = totalClasses + 1;
    _setCell(sheet, presentCol, summaryOffset, TextCellValue('Present %'), headerStyle);

    for (var ri = 0; ri < brahmacharis.length; ri++) {
      final brahmachari = brahmacharis[ri];
      final row = ri + 1 + summaryOffset;
      final bAttendances = attendanceMap[brahmachari.id] ?? {};

      _setCell(sheet, 0, row, TextCellValue(brahmachari.name), null);

      var greenCount = 0;

      for (var ci = 0; ci < totalClasses; ci++) {
        final classModel = classes[ci];
        final att = bAttendances[classModel.id];

        if (att != null) {
          final style =
              att.status == 'green' ? greenStyle : (att.status == 'red' ? redStyle : null);
          _setCell(sheet, ci + 1, row, TextCellValue(att.arrivalTime ?? ''), style);
          if (att.status == 'green') greenCount++;
        }
      }

      final percentage = totalClasses > 0
          ? ((greenCount / totalClasses) * 100).toStringAsFixed(0)
          : '0';
      _setCell(sheet, presentCol, row, TextCellValue('$percentage%'), percentageStyle);
    }

    sheet.setColumnWidth(0, 30);
    for (var ci = 0; ci < totalClasses; ci++) {
      sheet.setColumnWidth(ci + 1, 12);
    }
    sheet.setColumnWidth(presentCol, 14);

    return excel;
  }

  void _setCell(Sheet sheet, int col, int row, CellValue value, CellStyle? style) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = value;
    if (style != null) cell.cellStyle = style;
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}
