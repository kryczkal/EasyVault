import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/widgets/media/gallery/gallery_top_bar.dart';
import 'package:wed_pic_frontend/widgets/media/gallery/grid_view.dart';
import 'package:wed_pic_frontend/widgets/media/gallery/list_view.dart';
import 'package:wed_pic_frontend/widgets/upload_button.dart';
import 'package:wed_pic_frontend/widgets/qr_code_button.dart';
import 'package:wed_pic_frontend/models/media.dart';

class MediaGallery extends StatefulWidget {
  final Future<List<Media>> mediaItems;
  final VoidCallback refreshGallery;

  const MediaGallery(
      {super.key, required this.mediaItems, required this.refreshGallery});

  @override
  MediaGalleryState createState() => MediaGalleryState();
}

class MediaGalleryState extends State<MediaGallery> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            MediaGalleryTopBar(
              isGridView: _isGridView,
              onViewToggle: _toggleView,
              refreshGallery: widget.refreshGallery,
            ),
            Expanded(
              child: FutureBuilder<List<Media>>(
                future: widget.mediaItems,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    // TODO: Create a custom error widget
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No media found.'));
                  }

                  final mediaItems = snapshot.data!;
                  return _isGridView
                      ? MediaGridView(mediaItems: mediaItems)
                      : MediaListView(mediaItems: mediaItems);
                },
              ),
            ),
          ],
        ),
        // TODO: Move these buttons to a separate class
        const Positioned(
          bottom: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: QrCodeButton(),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: MediaUploadButton(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }
}
