import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wed_pic_frontend/utils/responsiveness.dart';
import 'package:wed_pic_frontend/widgets/media/upload/file_upload_grid_item.dart';

class MediaUploadDialog extends StatefulWidget {
  final List<XFile> selectedMedias;

  const MediaUploadDialog({
    super.key,
    required this.selectedMedias,
  });

  @override
  MediaUploadDialogState createState() => MediaUploadDialogState();
}

class MediaUploadDialogState extends State<MediaUploadDialog> {
  final Map<String, bool> _uploadResults = {};
  final Map<String, GlobalKey<FileUploadGridItemState>> _fileUploadKeys = {};
  bool _uploadStarted = false;

  @override
  void initState() {
    super.initState();
    for (var media in widget.selectedMedias) {
      _fileUploadKeys[media.name] = GlobalKey<FileUploadGridItemState>();
    }
  }

  void _onUploadComplete(String mediaName, bool success) {
    setState(() {
      _uploadResults[mediaName] = success;
    });
    if (_uploadResults.length == widget.selectedMedias.length) {
      final allSuccess = _uploadResults.values.every((element) => element);
      if (allSuccess) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _startUploads() {
    if (_uploadStarted) {
      return;
    }
    _uploadStarted = true;
    for (var media in widget.selectedMedias) {
      final itemKey = _fileUploadKeys[media.name];
      if (itemKey != null) {
        itemKey.currentState?.startUpload();
      }
    }
  }

  void _cancelUploads() {
    for (var itemKey in _fileUploadKeys.values) {
      itemKey.currentState?.cancelUpload();
    }
  }

  @override
  void dispose() {
    _cancelUploads();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Selected Files',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: Responsiveness.getCrossAxisCount(
                MediaQuery.of(context).size.width, 300),
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          children: widget.selectedMedias.map((media) {
            final itemKey = _fileUploadKeys[media.name];
            return FileUploadGridItem(
              key: itemKey,
              media: media,
              onUploadComplete: (success) =>
                  _onUploadComplete(media.name, success),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            _startUploads();
          },
          child: const Text(
            'Send',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
