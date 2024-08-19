import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/utils/common.dart';

class MediaGalleryTopBar extends StatefulWidget {
  final bool isGridView;
  final VoidCallback onViewToggle;
  final VoidCallback refreshGallery;

  const MediaGalleryTopBar({
    super.key,
    required this.isGridView,
    required this.onViewToggle,
    required this.refreshGallery,
  });

  @override
  State<MediaGalleryTopBar> createState() => _MediaGalleryTopBarState();
}

class _MediaGalleryTopBarState extends State<MediaGalleryTopBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: widget.refreshGallery,
              ),
              IconButton(
                icon: Icon(widget.isGridView ? Icons.list : Icons.grid_view),
                onPressed: widget.onViewToggle,
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  // TODO: Implement download functionality
                  logger.d('Download button pressed');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
