import 'package:flutter/material.dart';
import 'package:easyvault/widgets/media/gallery/media_box.dart';
import 'package:easyvault/models/media.dart';
import 'package:easyvault/utils/common.dart';

class MediaListItem extends StatelessWidget {
  final Media media;

  const MediaListItem({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5),
        ),
        child: MediaBox(
          media: media,
          size: 50,
        ),
      ),
      title: Text(media.name),
      subtitle: Text(Common.formatBytes(media.size)),
      onTap: () {
        Common.pushMediaViewerScreen(context, media);
      },
    );
  }
}
