import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/widgets/media/gallery/list_item.dart';
import 'package:wed_pic_frontend/models/media.dart';

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
