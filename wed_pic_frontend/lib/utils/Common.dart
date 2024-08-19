import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

Logger logger = Logger();

class Common {
  static Future<List<XFile>> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );
    if (result != null) {
      logger.i('Files picked: ${result.xFiles.map((e) => e.name).toList()}');
      return result.xFiles;
    } else {
      logger.w('No valid files selected or FilePickerResult is null');
      return [];
    }
  }

  static String formatBytes(String bytes) {
    int bytesValue = int.tryParse(bytes) ?? 0;

    if (bytesValue <= 0) return "0 B";

    const List<String> suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = (log(bytesValue) / log(1000)).floor();
    double size = bytesValue / pow(1000, i);

    return "${size.toStringAsFixed(2)} ${suffixes[i]}";
  }
}
