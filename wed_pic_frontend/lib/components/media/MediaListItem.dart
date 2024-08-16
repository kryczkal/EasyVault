import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/models/Media.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
      subtitle: Text(media.size),
      onTap: () {
        // TODO: Implement onTap functionality
        print('List item tapped: ${media.name}');
      },
    );
  }
}
