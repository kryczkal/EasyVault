import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:js' as js;

class VideoThumbnailDisplay extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onVideoTapped;
  final double width;
  final double height;

  const VideoThumbnailDisplay({
    super.key,
    required this.videoUrl,
    required this.onVideoTapped,
    this.width = 200.0,
    this.height = 200.0,
  });

  @override
  _VideoThumbnailDisplayState createState() => _VideoThumbnailDisplayState();
}

class _VideoThumbnailDisplayState extends State<VideoThumbnailDisplay> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: widget.onVideoTapped,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          child: const Icon(
            Icons.play_circle_fill,
            size: 50,
            color: Colors.white,
          ),
        ));
  }
}
