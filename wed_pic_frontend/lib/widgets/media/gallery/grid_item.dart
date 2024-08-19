
import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/widgets/media/gallery/grid_item_footer.dart';
import 'package:wed_pic_frontend/widgets/media/gallery/media_box.dart';
import 'package:wed_pic_frontend/models/media.dart';
import 'package:wed_pic_frontend/utils/common.dart';

class GridItem extends StatelessWidget {
  final Media media;

  const GridItem({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: GridTile(
        footer: GridItemFooter(media: media),
        child: MediaBox(
          media: media,
        ),
      ),
      onTap: () => {Common.pushMediaViewerScreen(context, media)},
    );
  }
}
