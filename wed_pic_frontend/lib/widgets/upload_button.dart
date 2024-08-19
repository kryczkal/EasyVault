import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wed_pic_frontend/widgets/dialogs/upload_dialog.dart';
import 'package:wed_pic_frontend/utils/common.dart';

class MediaUploadButton extends StatefulWidget {
  const MediaUploadButton({super.key});

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

  void _showMediaPreview(List<XFile> selectedMedias) {
    showDialog(
      context: context,
      builder: (context) {
        return MediaUploadDialog(selectedMedias: selectedMedias);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'media_upload_button',
      onPressed: pickFiles,
      backgroundColor: Colors.blueAccent,
      child: const Icon(
        Icons.add,
        color: Colors.white,
      ),
    );
  }
}
