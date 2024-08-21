import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/models/media.dart';

class MediaBox extends StatelessWidget {
  final double? size;
  final Media media;

  const MediaBox({
    super.key,
    required this.media,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5),
      ),
      child: media.type == 'image'
          ? CachedNetworkImage(
              imageUrl: media.url,
              fit: BoxFit.cover,
              width: size,
              height: size,
            )
          : media.type == 'video'
              ? Icon(
                  Icons.play_circle_outline,
                  size: size != null
                      ? size! * 0.9
                      : null, // Adjust icon size if size is given
                )
              : Icon(
                  Icons.insert_drive_file,
                  size: size != null
                      ? size! * 0.5
                      : null, // Adjust icon size if size is given
                ),
    );
  }
}
