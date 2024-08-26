// lib/widgets/image_viewer.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easyvault/models/media.dart';

class ImageViewer extends StatelessWidget {
  final Media media;

  const ImageViewer({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      child: Image.network(
        media.url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
