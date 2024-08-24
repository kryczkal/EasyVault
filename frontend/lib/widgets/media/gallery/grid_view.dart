import 'package:flutter/material.dart';
import 'package:easyvault/widgets/media/gallery/grid_item.dart';
import 'package:easyvault/models/media.dart';
import 'package:easyvault/utils/responsiveness.dart';

class MediaGridView extends StatelessWidget {
  final List<Media> mediaItems;

  const MediaGridView({super.key, required this.mediaItems});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount =
            Responsiveness.getCrossAxisCount(constraints.maxWidth, 300);
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
              return GridItem(media: mediaItems[index]);
            },
          ),
        );
      },
    );
  }
}
