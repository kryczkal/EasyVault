import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/models/media.dart';

class DownloadAllMediaDialog extends StatelessWidget {
  const DownloadAllMediaDialog({
    super.key,
    required this.mediaItems,
    required this.totalSize,
  });

  final List<Media> mediaItems;
  final String totalSize;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Download Media'),
      content: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text:
                  'are you sure you want to download ${mediaItems.length} files of total size ',
            ),
            TextSpan(
              text: totalSize,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(
              text: '? This will download all the media files one by one, ',
            ),
            const TextSpan(
              text: 'uncompressed',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(
              text: '.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text('Download'),
        ),
      ],
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
    );
  }
}
