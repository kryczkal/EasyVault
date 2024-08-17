import 'dart:math';

String formatBytes(String bytes) {
  int bytesValue = int.tryParse(bytes) ?? 0;

  if (bytesValue <= 0) return "0 B";

  const List<String> suffixes = ["B", "KB", "MB", "GB", "TB"];
  int i = (log(bytesValue) / log(1000)).floor();
  double size = bytesValue / pow(1000, i);

  return "${size.toStringAsFixed(2)} ${suffixes[i]}";
}
