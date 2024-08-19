import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/widgets/media/viewers/ImageViewer.dart';
import 'package:wed_pic_frontend/widgets/media/viewers/VideoViewer.dart';
import 'package:wed_pic_frontend/models/Media.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wed_pic_frontend/utils/Common.dart';

class MediaListItem extends StatelessWidget {
  final Media media;

  const MediaListItem({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: media.type == 'image'
          ? CachedNetworkImage(
              imageUrl: media.url,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            )
          : const Icon(Icons.play_circle_outline, size: 50),
      title: Text(media.name),
      subtitle: Text(Common.formatBytes(media.size)),
      onTap: () {
        // TODO: Media Viewer should be a separate universal component
        // That can handle both image and video, and miscellaneous media types
        if (media.type == 'image') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageViewerScreen(media: media),
            ),
          );
        } else if (media.type == 'video') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoViewerScreen(media: media),
            ),
          );
        }
      },
    );
  }
}
