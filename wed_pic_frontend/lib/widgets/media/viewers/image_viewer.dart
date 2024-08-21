// lib/widgets/image_viewer.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wed_pic_frontend/models/media.dart';

class ImageViewer extends StatelessWidget {
  final Media media;

  const ImageViewer({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      child: CachedNetworkImage(
        imageUrl: media.url,
        fit: BoxFit.contain,
      ),
    );
  }
}
