import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/widgets/media/viewers/ImageViewer.dart';
import 'package:wed_pic_frontend/widgets/media/VideoThumbnail.dart';
import 'package:wed_pic_frontend/widgets/media/viewers/VideoViewer.dart';
import 'package:wed_pic_frontend/models/Media.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wed_pic_frontend/utils/Common.dart';

class MediaItem extends StatelessWidget {
  final Media media;

  const MediaItem({super.key, required this.media});

  // TODO: This should be broken down into smaller compontents
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (media.type == 'image')
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageViewerScreen(media: media),
                  ),
                );
              },
              child: CachedNetworkImage(
                imageUrl: media.url,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            )
          else if (media.type == 'video')
            VideoThumbnailDisplay(
              videoUrl: media.url,
              onVideoTapped: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoViewerScreen(media: media),
                  ),
                );
              },
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    media.name,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    Common.formatBytes(media.size),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
