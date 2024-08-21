import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wed_pic_frontend/widgets/dialogs/upload_dialog.dart';
import 'package:wed_pic_frontend/utils/common.dart';

class MediaUploadButton extends StatefulWidget {
  final VoidCallback refreshGallery;
  const MediaUploadButton({super.key, required this.refreshGallery});

  @override
  State<MediaUploadButton> createState() => _MediaUploadButtonState();
}

class _MediaUploadButtonState extends State<MediaUploadButton> {
  Future<void> pickFiles() async {
    List<XFile>? selectedMedias = await Common.pickFiles();
    if (selectedMedias.isNotEmpty) {
      _showMediaPreview(selectedMedias);
    }
  }

  void _showMediaPreview(List<XFile> selectedMedias) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return MediaUploadDialog(selectedMedias: selectedMedias);
      },
    );

    if (!mounted) return;

    late String message;
    if (result != null && result) {
      widget.refreshGallery();
      message = 'Media uploaded successfully';
    } else {
      message = 'Upload cancelled or failed for some media';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'media_upload_button',
      onPressed: pickFiles,
      // backgroundColor: Colors.blueAccent,
      child: const Icon(
        Icons.add,
        color: Colors.white,
      ),
    );
  }
}
