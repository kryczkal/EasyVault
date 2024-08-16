import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/models/Media.dart';

class ImageViewerScreen extends StatelessWidget {
  final Media media;

  const ImageViewerScreen({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(media.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InteractiveViewer(
            child: Image.network(
              media.url,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
