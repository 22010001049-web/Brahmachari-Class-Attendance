import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/speaker_model.dart';
import '../models/brahmachari_model.dart';
import '../models/class_model.dart';
import '../models/attendance_model.dart';
import 'supabase_service.dart';
import 'file_helper.dart';

class BackupService {
  final SupabaseService _service = SupabaseService();

  Future<Uint8List> createBackup({
    required List<SpeakerModel> speakers,
    required List<BrahmachariModel> brahmacharis,
    required List<ClassModel> classes,
    required List<AttendanceModel> attendance,
  }) async {
    final excel = Excel.createExcel();
    _writeSpeakersSheet(excel, speakers);
    _writeBrahmacharisSheet(excel, brahmacharis);
    _writeClassesSheet(excel, classes);
    _writeAttendanceSheet(excel, attendance);

    final bytes = excel.save();
    if (bytes == null) throw Exception('Failed to generate backup file');
    return Uint8List.fromList(bytes);
  }

  Future<String> backupAllData() async {
    final results = await Future.wait([
      _service.getSpeakers(),
      _service.getBrahmacharis(),
      _service.getClasses(),
      _service.getAllAttendance(),
    ]);

    final speakers = results[0] as List<SpeakerModel>;
    final brahmacharis = results[1] as List<BrahmachariModel>;
    final classes = results[2] as List<ClassModel>;
    final attendance = results[3] as List<AttendanceModel>;

    final bytes = await createBackup(
      speakers: speakers,
      brahmacharis: brahmacharis,
      classes: classes,
      attendance: attendance,
    );

    final now = DateTime.now();
    final fileName =
        'backup_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}.xlsx';
    return saveBytesToFile(bytes, fileName);
  }

  void _writeSpeakersSheet(Excel excel, List<SpeakerModel> speakers) {
    final sheet = excel['Speakers'];
    _setCell(sheet, 0, 0, 'Name');
    _setCell(sheet, 1, 0, 'Created At');
    for (var i = 0; i < speakers.length; i++) {
      final r = i + 1;
      _setCell(sheet, 0, r, speakers[i].name);
      _setCell(sheet, 1, r, speakers[i].createdAt?.toIso8601String() ?? '');
    }
    sheet.setColumnWidth(0, 40);
    sheet.setColumnWidth(1, 30);
  }

  void _writeBrahmacharisSheet(Excel excel, List<BrahmachariModel> list) {
    final sheet = excel['Brahmacharis'];
    _setCell(sheet, 0, 0, 'Name');
    _setCell(sheet, 1, 0, 'Created At');
    for (var i = 0; i < list.length; i++) {
      final r = i + 1;
      _setCell(sheet, 0, r, list[i].name);
      _setCell(sheet, 1, r, list[i].createdAt?.toIso8601String() ?? '');
    }
    sheet.setColumnWidth(0, 40);
    sheet.setColumnWidth(1, 30);
  }

  void _writeClassesSheet(Excel excel, List<ClassModel> list) {
    final sheet = excel['Classes'];
    _setCell(sheet, 0, 0, 'Speaker Name');
    _setCell(sheet, 1, 0, 'Class Date');
    _setCell(sheet, 2, 0, 'Start Time');
    _setCell(sheet, 3, 0, 'Created At');
    for (var i = 0; i < list.length; i++) {
      final r = i + 1;
      _setCell(sheet, 0, r, list[i].speakerName);
      _setCell(sheet, 1, r, list[i].classDate);
      _setCell(sheet, 2, r, list[i].startTime);
      _setCell(sheet, 3, r, list[i].createdAt?.toIso8601String() ?? '');
    }
    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 30);
  }

  void _writeAttendanceSheet(Excel excel, List<AttendanceModel> list) {
    final sheet = excel['Attendance'];
    _setCell(sheet, 0, 0, 'Class ID');
    _setCell(sheet, 1, 0, 'Brahmachari ID');
    _setCell(sheet, 2, 0, 'Arrival Time');
    _setCell(sheet, 3, 0, 'Status');
    _setCell(sheet, 4, 0, 'Created At');
    for (var i = 0; i < list.length; i++) {
      final r = i + 1;
      _setCell(sheet, 0, r, list[i].classId);
      _setCell(sheet, 1, r, list[i].brahmachariId);
      _setCell(sheet, 2, r, list[i].arrivalTime ?? '');
      _setCell(sheet, 3, r, list[i].status);
      _setCell(sheet, 4, r, list[i].createdAt?.toIso8601String() ?? '');
    }
    sheet.setColumnWidth(0, 40);
    sheet.setColumnWidth(1, 40);
    sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 10);
    sheet.setColumnWidth(4, 30);
  }

  Future<void> restoreFromBackup(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);

    if (excel.sheets.containsKey('Speakers')) {
      final sheet = excel['Speakers'];
      final names = _readStringColumn(sheet, 0);
      for (final name in names) {
        try {
          await _service.createSpeaker(SpeakerModel(name: name));
        } catch (_) {}
      }
    }

    if (excel.sheets.containsKey('Brahmacharis')) {
      final sheet = excel['Brahmacharis'];
      final names = _readStringColumn(sheet, 0);
      for (final name in names) {
        try {
          await _service.createBrahmachari(BrahmachariModel(name: name));
        } catch (_) {}
      }
    }
  }

  List<String> _readStringColumn(Sheet sheet, int col) {
    final names = <String>[];
    final maxRows = sheet.maxRows;
    for (var row = 1; row < maxRows; row++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
      final value = cell.value?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        names.add(value);
      }
    }
    return names;
  }

  void _setCell(Sheet sheet, int col, int row, String value) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = TextCellValue(value);
  }
}
