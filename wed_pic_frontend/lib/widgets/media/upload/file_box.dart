import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/widgets/media/upload/file_upload_grid_item.dart';

class FileBox extends StatelessWidget {
  const FileBox({
    super.key,
    required this.widget,
  });

  final FileUploadGridItem widget;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.image,
          size: 40,
        ),
        const SizedBox(height: 8),
        Text(
          widget.media.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}
