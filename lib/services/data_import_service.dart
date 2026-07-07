import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/brahmachari_model.dart';
import '../models/speaker_model.dart';
import 'file_helper.dart';

class ImportResult {
  final int imported;
  final int skipped;
  final int failed;

  ImportResult({
    required this.imported,
    required this.skipped,
    required this.failed,
  });
}

class DataImportService {
  ImportResult parseBrahmacharisFromBytes(
    Uint8List bytes,
    List<BrahmachariModel> existing,
  ) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.sheets.values.firstOrNull;
    if (sheet == null) {
      return ImportResult(imported: 0, skipped: 0, failed: 1);
    }

    final existingNames =
        existing.map((b) => b.name.trim().toLowerCase()).toSet();
    final newNames = <String>{};
    int skipped = 0;
    int failed = 0;
    int imported = 0;

    final maxRows = sheet.maxRows;

    for (var row = 0; row < maxRows; row++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: row,
      ));
      final value = cell.value?.toString().trim() ?? '';
      if (value.isEmpty || value == 'Name' || value == 'name') continue;

      final lower = value.toLowerCase();
      if (existingNames.contains(lower) || newNames.contains(lower)) {
        skipped++;
      } else {
        newNames.add(lower);
        imported++;
      }
    }

    return ImportResult(imported: imported, skipped: skipped, failed: failed);
  }

  List<String> extractNamesFromExcel(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.sheets.values.firstOrNull;
    if (sheet == null) return [];

    final names = <String>[];
    final maxRows = sheet.maxRows;

    for (var row = 0; row < maxRows; row++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: row,
      ));
      final value = cell.value?.toString().trim() ?? '';
      if (value.isEmpty || value == 'Name' || value == 'name') continue;
      names.add(value);
    }

    return names;
  }

  Future<String> exportBrahmacharisToExcel(
    List<BrahmachariModel> brahmacharis,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Brahmacharis'];

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = TextCellValue('Name');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
        .value = TextCellValue('Created At');

    for (var i = 0; i < brahmacharis.length; i++) {
      final row = i + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(brahmacharis[i].name);
      if (brahmacharis[i].createdAt != null) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(
                brahmacharis[i].createdAt!.toIso8601String());
      }
    }

    sheet.setColumnWidth(0, 40);
    sheet.setColumnWidth(1, 30);

    final bytes = excel.save();
    if (bytes == null) throw Exception('Failed to generate Excel file');

    final fileName =
        'brahmacharis_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    return saveBytesToFile(Uint8List.fromList(bytes), fileName);
  }

  ImportResult parseSpeakersFromBytes(
    Uint8List bytes,
    List<SpeakerModel> existing,
  ) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.sheets.values.firstOrNull;
    if (sheet == null) {
      return ImportResult(imported: 0, skipped: 0, failed: 1);
    }

    final existingNames =
        existing.map((b) => b.name.trim().toLowerCase()).toSet();
    final newNames = <String>{};
    int skipped = 0;
    int failed = 0;
    int imported = 0;

    final maxRows = sheet.maxRows;

    for (var row = 0; row < maxRows; row++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: row,
      ));
      final value = cell.value?.toString().trim() ?? '';
      if (value.isEmpty || value == 'Name' || value == 'name') continue;

      final lower = value.toLowerCase();
      if (existingNames.contains(lower) || newNames.contains(lower)) {
        skipped++;
      } else {
        newNames.add(lower);
        imported++;
      }
    }

    return ImportResult(imported: imported, skipped: skipped, failed: failed);
  }

  Future<String> exportSpeakersToExcel(
    List<SpeakerModel> speakers,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Speakers'];

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = TextCellValue('Name');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
        .value = TextCellValue('Created At');

    for (var i = 0; i < speakers.length; i++) {
      final row = i + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(speakers[i].name);
      if (speakers[i].createdAt != null) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(
                speakers[i].createdAt!.toIso8601String());
      }
    }

    sheet.setColumnWidth(0, 40);
    sheet.setColumnWidth(1, 30);

    final bytes = excel.save();
    if (bytes == null) throw Exception('Failed to generate Excel file');

    final fileName =
        'speakers_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    return saveBytesToFile(Uint8List.fromList(bytes), fileName);
  }
}
