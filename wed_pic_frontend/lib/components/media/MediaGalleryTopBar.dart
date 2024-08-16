import 'package:flutter/material.dart';

class MediaGalleryTopBar extends StatelessWidget {
  final bool isGridView;
  final VoidCallback onViewToggle;

  const MediaGalleryTopBar({
    super.key,
    required this.isGridView,
    required this.onViewToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(isGridView ? Icons.list : Icons.grid_view),
            onPressed: onViewToggle,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Implement download functionality
              print('Download button pressed');
            },
          ),
        ],
      ),
    );
  }
}
