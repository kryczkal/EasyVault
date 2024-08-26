import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:easyvault/models/media.dart';

class MediaBox extends StatefulWidget {
  final double? size;
  final Media media;
  final FilterQuality filterQuality;

  const MediaBox({
    super.key,
    required this.media,
    this.size,
    this.filterQuality = FilterQuality.high,
  });

  @override
  _MediaBoxState createState() => _MediaBoxState();
}

class _MediaBoxState extends State<MediaBox> {
  bool _loadImage = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key ?? Key(widget.media.url),
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction > 0 && !_loadImage) {
          setState(() {
            _loadImage = true;
          });
        }
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5),
        ),
        child: _getContentBasedOnType(),
      ),
    );
  }

  Widget _getContentBasedOnType() {
    if (widget.media.type == 'image' && _loadImage) {
      return Image.network(
        widget.media.url,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        filterQuality: widget.filterQuality,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
    } else if (widget.media.type == 'video') {
      return Icon(
        Icons.play_circle_outline,
        size: widget.size != null ? widget.size! * 0.9 : null,
      );
    } else {
      return Icon(
        Icons.insert_drive_file,
        size: widget.size != null ? widget.size! * 0.5 : null,
      );
    }
  }
}
