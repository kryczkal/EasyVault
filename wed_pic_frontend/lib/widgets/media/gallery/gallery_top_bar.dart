import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/models/media.dart';
import 'package:wed_pic_frontend/utils/common.dart';
import 'package:wed_pic_frontend/widgets/dialogs/download_all_media_dialog.dart';

class MediaGalleryTopBar extends StatefulWidget {
  final bool isGridView;
  final VoidCallback onViewToggle;
  final VoidCallback refreshGallery;
  final Future<List<Media>> mediaItems;

  const MediaGalleryTopBar({
    super.key,
    required this.isGridView,
    required this.onViewToggle,
    required this.refreshGallery,
    required this.mediaItems,
  });

  @override
  State<MediaGalleryTopBar> createState() => _MediaGalleryTopBarState();
}

class _MediaGalleryTopBarState extends State<MediaGalleryTopBar> {
  Future<void> _downloadAllMedia(BuildContext context) async {
    final mediaItems = await widget.mediaItems;
    final totalSize = Common.calcMediaSize(mediaItems);

    if (!mounted) return;
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return DownloadAllMediaDialog(
            mediaItems: mediaItems, totalSize: totalSize);
      },
    );

    if (result != null && result && mounted) {
      Common.downloadAllMedia(context, mediaItems);
    }
  }

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
              // TODO: Implement download all media
              // IconButton(
              //   icon: const Icon(Icons.download),
              //   onPressed: () async {
              //     await _downloadAllMedia(context);
              //   },
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
