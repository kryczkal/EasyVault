// lib/screens/media_viewer_screen.dart

import 'package:flutter/material.dart';
import 'package:easyvault/models/media.dart';
import 'package:easyvault/utils/common.dart';
import 'package:easyvault/widgets/media/viewers/image_viewer.dart';
import 'package:easyvault/widgets/media/viewers/other_file_viewer.dart';
import 'package:easyvault/widgets/media/viewers/video_viewer.dart';

class MediaViewerScreen extends StatelessWidget {
  final Media media;

  const MediaViewerScreen({super.key, required this.media});

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
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              Common.launchUrlWrapper(media.url);
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildMediaViewer(media),
        ),
      ),
    );
  }

  Widget _buildMediaViewer(Media media) {
    switch (media.type) {
      case 'image':
        return ImageViewer(media: media);
      case 'video':
        return VideoViewer(media: media);
      default:
        return OtherFileViewer(media: media);
    }
  }
}
