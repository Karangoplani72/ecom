import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

class CsvExportHelper {
  static Future<void> exportToCsv({
    required String fileName,
    required List<List<dynamic>> rows,
  }) async {
    final csvString = Csv().encode(rows);
    final bytes = Uint8List.fromList(utf8.encode(csvString));
    await FilePicker.saveFile(
      dialogTitle: 'Save CSV Export',
      fileName: fileName,
      bytes: bytes,
    );
  }
}
