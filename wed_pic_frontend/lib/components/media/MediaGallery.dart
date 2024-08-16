import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/components/media/MediaGalleryTopBar.dart';
import 'package:wed_pic_frontend/components/media/MediaGridView.dart';
import 'package:wed_pic_frontend/components/media/MediaListView.dart';
import 'package:wed_pic_frontend/components/media/MediaUploadButton.dart';
import 'package:wed_pic_frontend/models/Media.dart';

class MediaGallery extends StatefulWidget {
  final Future<List<Media>> mediaItems;

  const MediaGallery({super.key, required this.mediaItems});

  @override
  _MediaGalleryState createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<MediaGallery> {
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
            ),
            Expanded(
              child: FutureBuilder<List<Media>>(
                future: widget.mediaItems,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
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
        const MediaUploadButton(),
      ],
    );
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }
}
