import 'package:flutter/material.dart';

class MediaUploadButton extends StatelessWidget {
  const MediaUploadButton({super.key});

  @override
  Widget build(BuildContext context) {
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
}
