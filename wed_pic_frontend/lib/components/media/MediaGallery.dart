import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wed_pic_frontend/GeneralSettings.dart';
import 'package:wed_pic_frontend/components/media/MediaGalleryTopBar.dart';
import 'package:wed_pic_frontend/components/media/MediaGridView.dart';
import 'package:wed_pic_frontend/components/media/MediaListView.dart';
import 'package:wed_pic_frontend/components/media/MediaUploadButton.dart';
import 'package:wed_pic_frontend/components/media/QrCodeButton.dart';
import 'package:wed_pic_frontend/models/Media.dart';
import 'package:wed_pic_frontend/states/SessionManager.dart';
import 'package:provider/provider.dart';

class MediaGallery extends StatefulWidget {
  final Future<List<Media>> mediaItems;
  final VoidCallback refreshGallery;

  const MediaGallery(
      {super.key,
      required this.mediaItems,
      required void Function() refreshGallery})
      : refreshGallery = refreshGallery;

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
              refreshGallery: widget.refreshGallery,
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
        Positioned(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: QrCodeButton(),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: MediaUploadButton(),
              ),
            ],
          ),
          bottom: 16,
          right: 16,
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
