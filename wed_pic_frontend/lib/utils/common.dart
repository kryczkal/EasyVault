import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wed_pic_frontend/models/media.dart';
import 'package:wed_pic_frontend/widgets/custom_error.dart';
import 'package:wed_pic_frontend/widgets/media/viewers/media_viewer_screen.dart';

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

  static String calcMediaSize(List<Media> mediaList) {
    int totalSize = 0;
    for (var media in mediaList) {
      totalSize += int.tryParse(media.size) ?? 0;
    }
    return formatBytes(totalSize.toString());
  }

  static void pushMediaViewerScreen(BuildContext context, Media media) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaViewerScreen(media: media),
      ),
    );
  }

  static Future<void> launchUrlWrapper(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  static void showErrorDialog(String message, BuildContext context,
      {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: CustomError(
            errorMessage: message,
            onRetry: () {
              Navigator.of(context).pop(); // Close the dialog
              if (onRetry != null) {
                onRetry(); // Call the retry function if provided
              }
            },
          ),
          actions: <Widget>[
            if (onRetry == null)
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }

  static Future<void> runWithErrorHandling(
      BuildContext context, Future<void> Function() func,
      {String errorMessage = "An unexpected error occurred.",
      VoidCallback? onRetry}) async {
    try {
      await func();
    } catch (error, stackTrace) {
      logger.e('Error occurred: $error', error: error, stackTrace: stackTrace);
      if (context.mounted) {
        showErrorDialog(errorMessage, context, onRetry: onRetry);
      }
    }
  }

  static Future<void> downloadAllMedia(
      BuildContext context, List<Media> mediaList) async {
    for (var media in mediaList) {
      await runWithErrorHandling(
        context,
        () => launchUrlWrapper(media.url),
        errorMessage: 'Failed to download media',
      );
    }
  }
}
