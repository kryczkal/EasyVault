import 'package:flutter/material.dart';
import 'package:easyvault/widgets/media/gallery/list_item.dart';
import 'package:easyvault/models/media.dart';

class MediaListView extends StatelessWidget {
  final List<Media> mediaItems;

  const MediaListView({super.key, required this.mediaItems});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        return MediaListItem(media: mediaItems[index]);
      },
    );
  }
}
