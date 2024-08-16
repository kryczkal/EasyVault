import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/components/media/ImageViewerScreen.dart';
import 'package:wed_pic_frontend/components/media/VideoThumbnail.dart';
import 'package:wed_pic_frontend/components/media/VideoViewerScreen.dart';
import 'package:wed_pic_frontend/models/Media.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MediaItem extends StatelessWidget {
  final Media media;

  const MediaItem({super.key, required this.media});

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
                // Navigate to the image viewer screen
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
                // Trigger your VideoTapped business logic here
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
                    media.size,
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
