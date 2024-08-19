import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/components/media/gallery/GridItem.dart';
import 'package:wed_pic_frontend/models/Media.dart';

class MediaGridView extends StatelessWidget {
  final List<Media> mediaItems;

  const MediaGridView({super.key, required this.mediaItems});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: mediaItems.length,
            itemBuilder: (context, index) {
              return MediaItem(media: mediaItems[index]);
            },
          ),
        );
      },
    );
  }

  // TODO: Move this to a utility class
  int _getCrossAxisCount(double width) {
    return 1 + (width / 300).floor();
  }
}
