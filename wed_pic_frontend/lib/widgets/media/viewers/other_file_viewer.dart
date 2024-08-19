import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/models/media.dart';
import 'package:wed_pic_frontend/utils/common.dart';

class OtherFileViewer extends StatelessWidget {
  final Media media;

  const OtherFileViewer({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Unsupported file type',
          style: TextStyle(fontSize: 18.0),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Common.launchUrlWrapper(media.url);
          },
          child: const Text('Download File'),
        ),
      ],
    );
  }
}
