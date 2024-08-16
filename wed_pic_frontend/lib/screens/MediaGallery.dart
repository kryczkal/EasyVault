import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
            _buildTopBar(),
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
                      ? _buildGridView(mediaItems)
                      : _buildListView(mediaItems);
                },
              ),
            ),
          ],
        ),
        _buildUploadButton(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
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

  Widget _buildUploadButton() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton(
        onPressed: () {
          // TODO: Implement upload functionality
          print('Upload button pressed');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGridView(List<Media> mediaItems) {
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
              return _buildMediaItem(mediaItems[index]);
            },
          ),
        );
      },
    );
  }

  int _getCrossAxisCount(double width) {
    if (width < 600) return 2;
    if (width < 900) return 3;
    return 4;
  }

  Widget _buildMediaItem(Media media) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          media.type == 'image'
              ? CachedNetworkImage(
                  imageUrl: media.url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )
              : Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.play_circle_outline,
                      size: 48, color: Colors.grey),
                ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    media.name,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    media.size,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<Media> mediaItems) {
    return ListView.builder(
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        return _buildListItem(mediaItems[index]);
      },
    );
  }

  Widget _buildListItem(Media media) {
    return ListTile(
      leading: media.type == 'image'
          ? CachedNetworkImage(
              imageUrl: media.url,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            )
          : const Icon(Icons.play_circle_outline, size: 50),
      title: Text(media.name),
      subtitle: Text(media.size),
      onTap: () {
        // TODO: Implement onTap functionality
        print('List item tapped: ${media.name}');
      },
    );
  }
}
