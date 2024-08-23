import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/widgets/custom_error.dart';
import 'package:wed_pic_frontend/widgets/media/gallery/corner_buttons.dart';
import 'package:wed_pic_frontend/widgets/media/gallery/gallery_top_bar.dart';
import 'package:wed_pic_frontend/widgets/media/gallery/grid_view.dart';
import 'package:wed_pic_frontend/widgets/media/gallery/list_view.dart';
import 'package:wed_pic_frontend/models/media.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
              mediaItems: widget.mediaItems,
            ),
            Expanded(
              child: FutureBuilder<List<Media>>(
                future: widget.mediaItems,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return CustomError(
                      errorMessage: 'Error: ${snapshot.error}',
                      onRetry: widget.refreshGallery,
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                        child: Text(
                      AppLocalizations.of(context)!.galleryEmptyText,
                    ));
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
        CornerButtons(
          refreshGallery: widget.refreshGallery,
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
